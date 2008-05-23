#!/usr/bin/perl

# TODO:
#   + refactor the code
#   + make it more testable

package ARename;
use warnings;
use strict;

# modules {{{

# These are commonly installed along with Perl:
use Readonly;
use Getopt::Std;
use File::Basename;
use File::Copy;
use Cwd;
use Cwd 'abs_path';

# These are external modules. On debian systems, do:
#   % aptitude install libogg-vorbis-header-perl \
#                      libmp3-tag-perl           \
#                      libaudio-flac-header-perl
#
# If you don't know how to get them for your OS, get them
# from CPAN: <http://cpan.org>.
use MP3::Tag;
use Ogg::Vorbis::Header;
use Audio::FLAC::Header;

#}}}
# variables {{{
my (
    %conf, %defaults, %hooks, %methods, %parsers, %profiles, %opts, %sectconf, %sets,
    $__arename_file, $postproc, $sect,
    @cmdline_profiles, @localizables, @settables, @supported_tags
);
my ( $NAME, $VERSION ) = ( 'unset', 'unset' );

# a helper for the testsuite
sub data_reset { #{{{
    undef %conf;
    undef %defaults;
    undef %hooks;
    undef %methods;
    undef %parsers;
    undef %profiles;
    undef %opts;
    undef %sectconf;
    undef %sets;
    undef @cmdline_profiles;
    undef @localizables;
    undef @settables;
    undef @supported_tags;
}
#}}}

set_opt('shutup', 0);

# settings that may occur in [sections]
@localizables = (
    "force",
    "prefix",
    "sepreplace",
    "tnpad",
    "comp_template",
    "template"
);

@supported_tags = (
    'album',        'artist',
    'compilation',
    'genre',
    'tracknumber',  'tracktitle',
    'year'
);

@settables = (
    'canonicalize', 'checkprofilerc', 'comp_template',
    'debug',
    'hookerrfatal',
    'prefix',
    'quiet', 'quiet_skip',
    'sepreplace',
    'template', 'tnpad',
    'usehooks', 'uselocalhooks', 'uselocalrc', 'useprofiles',
    'verbose', 'warningsautodryrun'
);

$postproc = \&arename;
#}}}

# high level code {{{

sub apply_methods { #{{{
    my ($exit) = @_;

    my $file = get_file();

    foreach my $method (sort keys %methods) {
        if ($file =~ m/$method/i) {
            run_hook('pre_method', \$method);
            $methods{$method}->($file);
            run_hook('post_method', \$method);
            if ($exit) {
                exit 0;
            } else {
                return 1;
            }
        }
    }
    return 0;
}
#}}}
sub __arename_file_eq { #{{{
    my ($newname, $oldname) = @_;

    if (file_eq($newname, $oldname)) {
        if (get_opt("quiet")) {
            if (!get_opt("quiet_skip")) {
                print "Skipping: '$oldname'\n";
            }
        } else {
            oprint("'$oldname'\n      would stay the way it is, skipping.\n");
        }
        return 1;
    }

    return 0;
}
#}}}
sub arename { #{{{
    my ($datref, $ext) = @_;
    my ($t, $newname);

    my $file = get_file();

    run_hook('pre_apply_defaults', $datref, \$ext);

    apply_defaults($datref);
    arename_verbosity($datref);

    run_hook('pre_template', $datref, \$ext);

    $t = choose_template($datref);
    $newname = expand_template($t, $datref);
    return if not defined $newname;
    $newname = get_opt("prefix") . '/' . $newname . '.' . $ext;

    run_hook('post_template', $datref, \$ext, \$newname);

    return if (__arename_file_eq($newname, $file));

    if (-e $newname && !get_opt("force")) {
        oprint("'$newname' exists." . (get_opt("quiet") ? " " : "\n      ")
            . "use '-f' to force overwriting.\n");
        return;
    }

    ensure_dir(dirname($newname));

    run_hook('post_ensure_dir', $datref, \$ext, \$newname);

    if (get_opt("quiet")) {
        print "'$newname'\n" if (!get_opt('shutup'));
    } else {
        oprint("mv '$file' \\\n         '$newname'\n");
    }

    if (!get_opt("dryrun")) {
        xrename($file, $newname);
    }

    run_hook('post_rename', $datref, \$ext, \$newname);
}
#}}}

sub apply_defaults { #{{{
    my ($datref) = @_;
    my ($value);

    foreach my $key (get_default_keys()) {
        if (!defined $datref->{$key}) {
            run_hook('apply_defaults', $datref, \$key);

            $value = get_defaults($key);
            oprint_verbose("Setting ($key) to \"$value\".\n");
            $datref->{$key} = $value;
        }
    }
}
#}}}
sub tag_supported { #{{{
    my ($tag) = @_;

    foreach my $sub (@supported_tags) {
        if ($tag eq $sub) {
            return 1;
        }
    }

    return 0;
}
#}}}

sub arename_verbosity { #{{{
    my ($datref) = @_;

    return if (!get_opt('verbose'));

    oprint("Artist     : " . getdat($datref, "artist")      . "\n");
    oprint("Compilation: " . getdat($datref, "compilation") . "\n");
    oprint("Album      : " . getdat($datref, "album")       . "\n");
    oprint("Tracktitle : " . getdat($datref, "tracktitle")  . "\n");
    oprint("Tracknumber: " . getdat($datref, "tracknumber") . "\n");
    oprint("Genre      : " . getdat($datref, "genre")       . "\n");
    oprint("Year       : " . getdat($datref, "year")        . "\n");
}
#}}}
sub getdat { #{{{
    my ($datref, $tag) = @_;

    return defined $datref->{$tag} ? "\"" . $datref->{$tag} . "\"" : "(undefined)";
}
#}}}

sub process_file { #{{{
    my ($file) = @_;

    set_file($file);

    run_hook('next_file_early');

    if (!get_opt("quiet")) {
        print "Processing: $file\n";
    }
    if (-l $file) {
        owarn("Refusing to handle symbolic links ($file).\n");
        return;
    }
    if (! -r $file) {
        owarn("Can't read \"$file\": $!\n");
        return;
    }

    if (get_opt('canonicalize')) {
        my $f = abs_path($file);
        run_hook('canonicalize', \$f);
        set_file($f);
    }

    run_hook('next_file_late');

    if (!apply_methods(0)) {
        run_hook('filetype_unknown');
        process_warn();
    } else {
        run_hook('file_done');
    }
}
#}}}

sub get_profile_list { #{{{
    my @list = ();
    my $wd = getcwd();
    my %seen = ();

    # make sure $wd ends in *one* slash
    $wd =~ s/\/+$//;
    $wd .= '/';

    foreach my $profile (sort keys %profiles) {
        odebug("get_profile_list(): Checking \"$profile\" patterns...\n");

        foreach my $pat (@{ $profiles{$profile} }) {
            odebug("get_profile_list(): ($wd) =~ ($pat)...\n");

            if ($wd =~ m/^$pat/) {
                odebug("get_profile_list(): MATCHED.\n");
                push @list, $profile;
                last;
            }

        }
    }

    @list = sort grep { ! $seen{ $_ }++ } (@list, @cmdline_profiles);
    odebug("get_profile_list(): (" . join(',', @list) . ")\n");
    return @list;
}
#}}}

sub set_default_options { #{{{
    set_opt("canonicalize",         0);
    set_opt("checkprofilerc",       1);
    set_opt("debug",                0);
    set_opt("dryrun",               0);
    set_opt("force",                0);
    set_opt("hookerrfatal",         1);
    set_opt("oprefix",              '  -!- ');
    set_opt("prefix" ,              '.');
    set_opt("quiet",                0);
    set_opt("quiet_skip",           0);
    set_opt("readstdin",            0);
    set_opt("sepreplace",           '_');
    set_opt("tnpad",                2);
    set_opt("usehooks",             1);
    set_opt("uselocalhooks",        0);
    set_opt("uselocalrc",           0);
    set_opt("useprofiles",          1);
    set_opt("verbose",              0);
    set_opt("warningsautodryrun",   1);
    set_opt("comp_template",        "va/&album/&tracknumber - &artist - &tracktitle");
    set_opt("template",             "&artist[1]/&artist/&album/&tracknumber - &tracktitle");
}
#}}}
sub set_default_methods { #{{{

    %methods = (
        '\.flac$' => \&ARename::process_flac,
        '\.mp3$'  => \&ARename::process_mp3,
        '\.ogg$'  => \&ARename::process_ogg
    );
}
#}}}
sub set_nameversion { #{{{
    my ($n, $v) = @_;

    $NAME    = $n;
    $VERSION = $v;
}
#}}}
sub set_postproc { #{{{
    $postproc = $_[0];
}
#}}}

sub usage { #{{{
    print " Usage:\n  $NAME [OPTION(s)] FILE(s)...\n\n";
    print "    -D                Enable debugging output.\n";
    print "    -d                Go into dryrun mode.\n";
    print "    -f                Overwrite files if needed.\n";
    print "    -H                Disable *all* hooks.\n";
    print "    -h                Display this help text.\n";
    print "    -L                List current configuration.\n";
    print "    -l                Read local rc, if it exists.\n";
    print "    -N                Deactivate all profiles.\n";
    print "    -Q                Don't display skips in quiet mode.\n";
    print "    -q                Enable quiet output.\n";
    print "    -s                Read file names from stdin.\n";
    print "    -V                Display version infomation.\n";
    print "    -v                Enable verbose output.\n";
    print "    -c <file>         Read file instead of ~/.arenamerc.\n";
    print "    -C <file>         Read file after ~/.arenamerc.\n";
    print "    -P <prof(s),...>  Comma seperated list of profiles to activate forcibly.\n";
    print "    -p <prefix>       Define a prefix for destination files.\n";
    print "    -T <template>     Define a compilation template.\n";
    print "    -t <template>     Define a generic template.\n";
    print "\n";
}
#}}}

#}}}
# template handling {{{

sub choose_template { #{{{
    my ($datref) = @_;

    if (defined $datref->{compilation}
        && $datref->{compilation} ne $datref->{artist}) {

        return get_opt("comp_template");
    } else {
        return get_opt("template");
    }
}
#}}}
sub __template_create_token { #{{{
    my ($datref, $tag, $len) = @_;
    my ($token, $val, $pad);

    if ($len > 0) {
        $token = substr($datref->{$tag}, 0, $len);
    } else {
        if ($tag eq 'tracknumber') {

            if ($datref->{$tag} =~ m/^([^\/]*)\/.*$/) {
                $val = $1;
            } else {
                $val = $datref->{$tag};
            }

            $pad = get_opt('tnpad');
            $token = sprintf "%0" . ($pad ne "0" ? "$pad" : "" ) . "d", $val;
        } else {
            $token = $datref->{$tag};
        }
    }

    return $token;
}
#}}}
sub __template_token_sepreplace { #{{{
    my ($tokref) = @_;
    my ($sr);

    if ($$tokref =~ m!/!) {
        $sr = get_opt("sepreplace");
        oprint_verbose("Found directory seperator in token.\n");
        oprint_verbose("Replacing with \"$sr\".\n");
        $$tokref =~ s!/!$sr!g;
    }
}
#}}}
sub expand_template { #{{{
    my ($template, $datref) = @_;

    run_hook('pre_expand_template', \$template, $datref);

    foreach my $tag (@supported_tags) {
        my ($len, $token);

        while ($template =~ m/&$tag(\[(\d+)\]|)/) {
            $len = 0;
            if (defined $2) { $len = $2; }

            if (!defined $datref->{$tag} || $datref->{$tag} eq '') {
                owarn("$tag not defined, but required by template. Giving up.\n");
                return undef;
            }

            run_hook('expand_template_next_tag', \$template, \$tag, \$len, $datref);

            $token = __template_create_token($datref, $tag, $len);
            __template_token_sepreplace(\$token);

            run_hook('expand_template_postprocess_tag', \$template, \$token, \$tag, \$len, $datref);

            $template =~ s/&$tag(\[(\d+)\]|)/$token/;
        }
    }

    run_hook('post_expand_template', \$template, $datref);

    return $template;
}
#}}}

#}}}
# file system related code {{{

sub ensure_dir { #{{{
    # think: mkdir -p /foo/bar/baz
    my ($wantdir) = @_;
    my (@parts, $sofar);

    if (-d $wantdir) {
        return;
    }

    if ($wantdir =~ '^/') {
        $sofar = '/';
    } else {
        $sofar = '';
    }

    @parts = split(/\//, $wantdir);
    foreach my $part (@parts) {
        if ($part eq '') {
            next;
        }
        $sofar = (
                  $sofar eq ''
                    ? $part
                    : (
                        $sofar eq '/'
                          ? '/' . $part
                          : $sofar . "/" . $part
                      )
                 );

        if (!-d $sofar) {
            if ((get_opt("dryrun") || get_opt("verbose")) && !get_opt("quiet")) {
                oprint("mkdir \"$sofar\"\n");
            }
            if (!get_opt("dryrun")) {
                mkdir($sofar) or die "Could not mkdir($sofar).\n" .
                                     "Reason: $!\n";
            }
        }
    }
}
#}}}
sub file_eq { #{{{
    my ($f0, $f1) = @_;
    my (@stat0, @stat1);

    if (!-e $f0 || !-e $f1) {
        # one of the two doesn't even exist, can't be the same then.
        return 0;
    }

    @stat0 = stat $f0 or die "Could not stat($f0): $!\n";
    @stat1 = stat $f1 or die "Could not stat($f1): $!\n";

    if ($stat0[0] == $stat1[0] && $stat0[1] == $stat1[1]) {
        # device and inode are the same. same file.
        return 1;
    }

    return 0;
}
#}}}
sub xrename { #{{{
    # a rename() replacement, that implements renames across
    # filesystems via File::copy() + unlink().
    # This assumes, that source and destination directory are
    # there, because it stat()s them, to check if it can use
    # rename().
    my ($src, $dest) = @_;
    my (@stat0, @stat1, $d0, $d1, $cause);

    $d0 = dirname($src);
    $d1 = dirname($dest);
    @stat0 = stat $d0 or die "Could not stat($d0): $!\n";
    @stat1 = stat $d1 or die "Could not stat($d1): $!\n";

    if ($stat0[0] == $stat1[0]) {
        $cause = 'rename';
        rename $src, $dest or goto err;
    } else {
        $cause = 'copy';
        copy($src, $dest) or goto err;
        $cause = 'unlink';
        unlink $src or goto dir;
    }

    return 0;

err:
    die "Could not rename($src, $dest);\n" .
        "Reason: $cause(): $!\n";
}
#}}}

#}}}
# output subroutines {{{

sub odebug { #{{{
    my ($string) = @_;

    # we cannot use the normal API here, because we're using odebug()
    # in the API's subroutines. That would recurse endlessly.
    return if (!$conf{'debug'} || $conf{'shutup'});
    print "DEBUG: $string";
}
#}}}
sub oprint { #{{{
    my ($string) = @_;

    return if (get_opt('shutup'));
    print get_opt("oprefix") . $string;
}
#}}}
sub oprint_verbose { #{{{
    my ($string) = @_;

    return if (!get_opt('verbose'));
    oprint($string);
}
#}}}
sub owarn { #{{{
    my ($string) = @_;

    return if (get_opt('shutup'));
    warn get_opt("oprefix") . $string;
}
#}}}
sub owarn_verbose { #{{{
    my ($string) = @_;

    return if (!get_opt('verbose'));
    owarn($string);
}
#}}}

#}}}
# config file processing {{{

Readonly::Scalar my $FIND_RC => 0;              # find .arenamerc
Readonly::Scalar my $FIND_HOOKS => 1;           # find .arename.hooks
Readonly::Scalar my $FIND_PROFRC => 2;          # find .arename.profilename
Readonly::Scalar my $FIND_PROFHOOKS => 3;       # find .arename.profilename.hooks
Readonly::Scalar my $FIND_NONAME => q{};        # file name to find not further specified

sub __home_find_file { #{{{
    my ($home, $name, $dotname) = @_;
    my ($etcdir, $dotdir, $fn);

    $etcdir = "$home/etc/arename";
    $dotdir = "$home/.arename";

    # if ~/etc/arename/ exists, we read *everything* from there.
    # if not, but ~/.arename/, we read everything from there.
    # if both are not there, we're looking for stuff like ~/.arenamerc.
    if (-d $etcdir) {
        odebug("__home_find_file() using \"$etcdir\"\n");
        $fn = "$etcdir/$name";

        if (-e $fn) {
            return $fn;
        }
    } elsif (-d $dotdir) {
        odebug("__home_find_file() using \"$dotdir\"\n");
        $fn = "$dotdir/$name";

        if (-e $fn) {
            return $fn;
        }
    } else {
        odebug("__home_find_file() using \"$home\"\n");
        $fn = "$home/$dotname";

        if (-e $fn) {
            return $fn;
        }
    }

    return '';
}
#}}}
sub home_find_file { #{{{
    my ($code, $spec) = @_;
    my ($name, $home);

    $home = $ENV{'HOME'};
    $home =~ s/\/+$//;

    if ($code == $FIND_RC) {
        $name = __home_find_file($home, 'rc', '.arenamerc');
    } elsif ($code == $FIND_HOOKS) {
        $name = __home_find_file($home, 'hooks', '.arename.hooks');
    } elsif ($code == $FIND_PROFRC) {
        $name = __home_find_file(
            $home,
            sprintf('profile.%s', $spec),
            sprintf('.arename.%s', $spec)
        );
    } elsif ($code == $FIND_PROFHOOKS) {
        $name = __home_find_file(
            $home,
            sprintf('profile.%s.hooks', $spec),
            sprintf('.arename.%s.hooks', $spec)
        );
    } else {
        die "home_find_file(): unknown code ($code). Please report!\n";
    }

    odebug("home_find_file($code, \"$spec\") returning ($name)\n");
    return $name;
}
#}}}

sub __is_comment_or_blank { #{{{
    my ($string) = @_;

    if ($string =~ m/^\s*#/ || $string =~ m/^\s*$/) {
        return 1;
    }

    return 0;
}
#}}}
sub __remove_leading_backslash { #{{{
    my ($strref) = @_;

    if (defined $$strref) {
        $$strref =~ s/^\\//;
    }
}
#}}}
sub __remove_leading_whitespace { #{{{
    my ($strref) = @_;

    $$strref =~ s/^\s*//;
}
#}}}
sub __rcload_stats { #{{{
    my ($desc, $count, $warnings) = @_;

    oprint("Read $desc.\n");
    oprint("$count valid items.\n");
    if ($warnings > 0) {
        oprint("$warnings warnings.\n");
        if (get_opt('warningsautodryrun') && !get_opt('dryrun')) {
            owarn("Encountered warnings; enabling 'dryrun'.\n");
            owarn("  (See 'warningsautodryrun' option.)\n");
            set_opt('dryrun', 1);
        }
    }
}
#}}}
sub __rcload { #{{{
    my ($file, $desc) = @_;
    my ($fh, $retval);
    my ($count, $warnings, $lnum) = (0, 0, 0);

    if (!open($fh, "<$file")) {
        warn "Failed to read $desc ($file).\n";
        owarn("Reason: $!\n");
        return 1;
    }

    print "Reading \"$file\"...\n" if (!get_opt('shutup'));

    while (my $line = <$fh>) {
        chomp($line);
        $lnum++;

        if (__is_comment_or_blank($line)) {
            next;
        }

        __remove_leading_whitespace(\$line);

        my ($key,$val) = split(/\s+/, $line, 2);

        __remove_leading_backslash(\$val);

        $retval = parse($file, $lnum, $count, $key, $val);
        if ($retval < 0) {
            owarn("$file,$lnum: invalid line '$line'.\n");
            return -1;
        } elsif ($retval > 1) {
            owarn("unknown-line:$file,$lnum: $line\n");
            $warnings++;
        } elsif ($retval > 0) {
            owarn("warning:$file,$lnum: $line\n");
            $warnings++;
        } else {
            $count++;
        }
    }
    close $fh;

    sect_reset();
    __rcload_stats($desc, $count, $warnings);

    return 0;
}
#}}}
sub rcload { #{{{
    my ($rc, $desc) = @_;
    my ($retval);

    $retval = __rcload($rc, $desc);

    if ($retval < 0) {
        die "Error(s) in \"$rc\". Aborting.\n";
    } elsif ($retval > 0) {
        owarn("Error opening configuration file.\n");
    }

}
#}}}
sub read_rcs { #{{{
    my ($rc);

    if (cmdopts('c')) {
        $rc = cmdoptstr('c');
    } else {
        $rc = home_find_file($FIND_RC, $FIND_NONAME);
    }

    if ($rc eq '') {
        owarn("main configuration file not found. Using defaults.\n");
    } else {
        rcload($rc, "main configuration");
    }

    if (cmdopts('C')) {
        $rc = cmdoptstr('C');
        rcload($rc, "additional configuration");
    }

    if (get_opt('useprofiles')) {
        foreach my $profile (get_profile_list()) {
            $rc = home_find_file($FIND_PROFRC, $profile);
            if ($rc ne '') {
                rcload($rc, "configuration for profile \"$profile\"");
            } else {
                owarn("Profile \"$profile\" active, but no configuration found.\n");
            }
        }
    }

    if (get_opt('uselocalrc') && -r "./.arename.local") {
        $rc = "./.arename.local";
        rcload($rc, "local configuration");
    }
}
#}}}

%parsers = (
#{{{
    '^\s*\[.*\]\s*$'        => \&parse_new_section,
    '^canonicalize$'        => \&parse_bool,
    '^checkprofilerc$'      => \&parse_bool,
    '^comp_template$'       => \&parse_string,
    '^default_.*$'          => \&parse_defaultvalues,
    '^debug$'               => \&parse_bool,
    '^hookerrfatal$'        => \&parse_bool,
    '^prefix$'              => \&parse_string,
    '^profile$'             => \&parse_profile,
    '^quiet$'               => \&parse_bool,
    '^quiet_skip$'          => \&parse_bool,
    '^sepreplace$'          => \&parse_string,
    '^set$'                 => \&parse_set,
    '^template$'            => \&parse_string,
    '^tnpad$'               => \&parse_integer,
    '^usehooks$'            => \&parse_bool,
    '^uselocalhooks$'       => \&parse_bool,
    '^uselocalrc$'          => \&parse_bool,
    '^useprofiles$'         => \&parse_bool,
    '^verbose$'             => \&parse_bool,
    '^warningsautodryrun$'  => \&parse_bool
);
#}}}

sub parse { #{{{
    my ($file, $lnum, $count, $key, $val) = @_;

    foreach my $pattern (sort keys %parsers) {
        if ($key =~ m/$pattern/) {

            return $parsers{$pattern}->(
                        $file, $lnum, $count,
                        $key, (defined $val ? $val : "")
                   );
        }
    }

    # return 2, to tell __rcload() that we had no parser, which matched
    # this line, unknown lines should be warnings, not fatal error.
    return 2;
}
#}}}

# parser sub functions
#   return values:
#       all okay: =0
#       warning : >0
#       fatal   : <0
sub parse_bool { #{{{
    my ($file, $lnum, $count, $key, $val) = @_;

    if (!defined $val || $val eq ''
       || $val =~ m/^true$/i || $val eq '1') {

        $val = 1;
    } elsif ($val =~ m/^false$/i || $val eq '0') {
        $val = 0;
    } else {
        owarn("$file,$lnum: unknown boolean value for '$key': '$val'\n");
        return -1
    }

    oprint_verbose("boolean option \"$key\" = '" . ($val ? 'true' : 'false' ) . "'\n");

    set_opt($key, $val);

    return 0;
}
#}}}
sub parse_defaultvalues { #{{{
    my ($file, $lnum, $count, $key, $val) = @_;

    $key =~ s/^default_//;

    if (!tag_supported($key)) {
        owarn("$file,$lnum: Default for unsupported tag found: '$key'\n");
        return -1;
    }

    oprint_verbose("default for \"$key\" = '$val'\n");

    set_defaults($key, $val);

    return 0;
}
#}}}
sub parse_integer { #{{{
    my ($file, $lnum, $count, $key, $val) = @_;

    if ($val ne '' && $val !~ m/^\d+$/) {
        owarn("$file,$lnum: Broken integer value for '$key': '$val'\n");
        return -1;
    }

    $val = 0 if ($val eq '');

    oprint_verbose("integer option \"$key\" = $val\n");

    set_opt($key, $val);

    return 0;
}
#}}}
sub parse_profile { #{{{
    my ($file, $lnum, $count, $key, $val) = @_;
    my ($name, $pat, $home);

    ($name, $pat) = $val =~ m/([^\s]+)\s+(.*)/;
    if (!defined $name || !defined $pat || $name eq '' || $pat eq '') {
        owarn("Could not parse profile value \"$val\"\n");
        return 1;
    }

    if ($name =~ m/[^a-zA-Z0-9_-]/) {
        owarn("Disallowed charaters in profile name ($name)!");
        return 1;
    }

    if (get_opt('checkprofilerc') && home_find_file($FIND_PROFRC, $name) eq '') {
        owarn("Could not find config file for profile \"$name\".\n");
        return 1;
    }

    $home = $ENV{'HOME'};
    $home =~ s/\/+$//;
    $home .= '/';

    $pat =~ s/^\\//;        # throw away a leading backslash
    $pat =~ s/^~\//$home/;  # ~/ -> $HOME

    oprint_verbose("Adding pattern \"$pat\" to profile \"$name\".\n");
    push @{ $profiles{$name} }, $pat;

    return 0;
}
#}}}
sub parse_string { #{{{
    my ($file, $lnum, $count, $key, $val) = @_;

    oprint_verbose("string option \"$key\" = '$val'\n");

    set_opt($key, $val);

    return 0;
}
#}}}
sub parse_new_section { #{{{
    my ($file, $lnum, $count, $key, $val) = @_;

    my ($s) = $key =~ m/^\s*\[(.*)\]\s*$/;

    if (!defined $s) {
        owarn("Broken section start: ($key)\n");
        return -1;
    }

    $s =~ s/^~\//$ENV{HOME}\//;
    sect_set($s);

    oprint_verbose("Switching section: \"$s\"\n");

    return 0;
}
#}}}
sub parse_set { #{{{
    my ($file, $lnum, $count, $key, $val) = @_;

    my ($name, $value) = $val =~ m/\s*(\w+)\s*=\s*\\?(.*)/;
    if (!defined $name || !defined $value) {
        owarn("Broken user setting: ($val)\n");
        return 1;
    }

    oprint_verbose("user setting \"$name\" = '$value'\n");

    user_set($name, $value);

    return 0;
}
#}}}

#}}}
# processing audio files {{{

sub handle_vorbistag { #{{{
    my ($datref, $tag, $value) = @_;
    my ($realtag);

    run_hook('pre_handle_vorbistag', \$tag, \$value, $datref);

    if (!(
            $tag =~ m/^ALBUM$/i         ||
            $tag =~ m/^ARTIST$/i        ||
            $tag =~ m/^TITLE$/i         ||
            $tag =~ m/^TRACKNUMBER$/i   ||
            $tag =~ m/^DATE$/i          ||
            $tag =~ m/^GENRE$/i         ||
            $tag =~ m/^ALBUMARTIST$/i
        )) { return; }

    if ($tag =~ m/^ALBUM$/i) {
        $realtag = 'album';
    } elsif ($tag =~ m/^ARTIST$/i) {
        $realtag = 'artist';
    } elsif ($tag =~ m/^TITLE$/i) {
        $realtag = 'tracktitle';
    } elsif ($tag =~ m/^TRACKNUMBER$/i) {
        $realtag = 'tracknumber';
    } elsif ($tag =~ m/^DATE$/i) {
        $realtag = 'year';
    } elsif ($tag =~ m/^GENRE$/i) {
        $realtag = 'genre';
    } elsif ($tag =~ m/^ALBUMARTIST$/i) {
        $realtag = 'compilation';
    } else {
        die "This should not happen. Report this BUG. ($tag, $value)";
    }

    if (!defined $datref->{$realtag}) {
        $datref->{$realtag} = $value;
    }

    run_hook('post_handle_vorbistag', \$tag, \$value, \$realtag, $datref);
}
#}}}
sub process_flac { #{{{
    my ($flac, %data, $tags);

    my $file = get_file();

    run_hook('pre_process_flac');

    $flac = Audio::FLAC::Header->new($file);

    if (!defined $flac) {
        oprint("Failed to open \"$file\".\n");
        oprint("Reason: $!\n");
        return;
    }

    $tags = $flac->tags();

    foreach my $tag (keys %$tags) {
        handle_vorbistag(\%data, $tag, $tags->{$tag});
    }

    $postproc->(\%data, 'flac');

    run_hook('post_process_flac');
}
#}}}
sub process_mp3 { #{{{
    my ($mp3, %data, $info);

    my $file = get_file();

    run_hook('pre_process_mp3');

    $mp3 = MP3::Tag->new($file);

    if (!defined $mp3) {
        oprint("Failed to open \"$file\".\n");
        oprint("Reason: $!\n");
        return;
    }

    $mp3->get_tags;

    if (!exists $mp3->{ID3v1} && !exists $mp3->{ID3v2}) {
        oprint("No tag found. Ignoring.\n");
        $mp3->close();
        return;
    }

    run_hook('pre_handle_mp3tag', $mp3, \%data);
    if (exists $mp3->{ID3v2}) {
        ($data{artist},      $info) = $mp3->{ID3v2}->get_frame("TPE1");
        ($data{compilation}, $info) = $mp3->{ID3v2}->get_frame("TPE2");
        ($data{album},       $info) = $mp3->{ID3v2}->get_frame("TALB");
        ($data{tracktitle},  $info) = $mp3->{ID3v2}->get_frame("TIT2");
        ($data{tracknumber}, $info) = $mp3->{ID3v2}->get_frame("TRCK");
        ($data{genre},       $info) = $mp3->{ID3v2}->get_frame("TCON");
        ($data{year},        $info) = $mp3->{ID3v2}->get_frame("TYER");
    } elsif (exists $mp3->{ID3v1}) {
        if ($NAME eq 'arename') {
            oprint("Only found ID3v1 tag.\n");
        }
        $data{artist}      = $mp3->{ID3v1}->artist;
        $data{album}       = $mp3->{ID3v1}->album;
        $data{tracktitle}  = $mp3->{ID3v1}->title;
        $data{tracknumber} = $mp3->{ID3v1}->track;
        $data{genre}       = $mp3->{ID3v1}->genre;
        $data{year}        = $mp3->{ID3v1}->year;
    }
    run_hook('post_handle_mp3tag', $mp3, \%data);

    $mp3->close();

    $postproc->(\%data, 'mp3');

    run_hook('post_process_mp3');
}
#}}}
sub process_ogg { #{{{
    my ($ogg, %data, @tags);

    my $file = get_file();

    run_hook('pre_process_ogg');

    $ogg = Ogg::Vorbis::Header->load($file);

    if (!defined $ogg) {
        oprint("Failed to open \"$file\".\n");
        oprint("Reason: $!\n");
        return;
    }

    @tags = $ogg->comment_tags;

    foreach my $tag (@tags) {
        handle_vorbistag(\%data, $tag, join(' ', $ogg->comment($tag)));
    }

    $postproc->(\%data, 'ogg');

    run_hook('post_process_ogg');
}
#}}}
sub process_warn { #{{{
    my $file = get_file();

    owarn("No method for handling \"$file\".\n");
}
#}}}

#}}}
# handling commandline options {{{

sub checkstropts { #{{{
    my (@o) = @_;

    foreach my $opt (@o) {
        if (exists $opts{$opt} && !defined $opts{$opt}) {
            owarn(" -$opt *requires* a string argument!\n");
        }
    }
}
#}}}
sub cmdopts { #{{{
    foreach my $opt (@_) {
        return 0 if (!defined $opts{$opt});
    }

    odebug("@_ options given!\n");
    return 1;
}
#}}}
sub cmdopts_or { #{{{
    foreach my $opt (@_) {
        return 1 if (defined $opts{$opt});
    }

    return 0;
}
#}}}
sub cmdoptstr { #{{{
    my ($opt) = @_;

    return $opts{$opt};
}
#}}}

sub read_cmdline_options { #{{{
    my ($tmp);

    if ($#main::ARGV == -1) {
        $opts{h} = 1;
    } else {
        if (!getopts('DdfhHLlNQqsVvc:C:P:p:T:t:', \%opts)) {
            checkstropts('c', 'C', 't', 'T', 'P', 'p');
            die "    Try $NAME -h\n";
        }
    }

    # turn on debugging early
    __set_opt("debug", 1) if (cmdopts('D'));

    set_opt('shutup', 1) if (cmdopts('L'));

    if (cmdopts('h')) {
        usage();
        exit 0;
    }

    if (cmdopts_or('q', 'Q') && cmdopts('v')) {
        die "Verbose *and* quiet? Please decide!\n";
    }

    if (cmdopts('V')) {
        print " $NAME $VERSION\n";
        exit 0;
    }

    $tmp = cmdoptstr('P');
    if (defined $tmp && $tmp ne '') {
        @cmdline_profiles = split(/,/, $tmp);
    }
    __set_opt("useprofiles", 0) if (cmdopts('N'));
    __set_opt("readstdin", 1) if (cmdopts('s'));
    __set_opt("uselocalrc", 1) if (cmdopts('l'));
    __set_opt("verbose", 1) if (cmdopts('v'));
    __set_opt("quiet", 1) if (cmdopts_or('q', 'Q'));
    __set_opt("quiet_skip", 1) if (cmdopts('Q'));
    __set_opt("force", 1) if (cmdopts('f'));
    __set_opt("dryrun", 1) if (cmdopts('d'));
    __set_opt("template", cmdoptstr('t')) if (cmdopts('t'));
    __set_opt("comp_template", cmdoptstr('T')) if (cmdopts('T'));
    __set_opt("prefix", cmdoptstr('p')) if (cmdopts('p'));
    disable_hooks() if (cmdopts('H'));

    if ($#main::ARGV < 0 && !cmdopts('L') && !get_opt('readstdin')) {
        die "No input files given; try " . basename($main::0) . " -h.\n";
    }
}
#}}}

#}}}
# accessing the currently processed audio file's name {{{

sub get_file { #{{{
    return $__arename_file;
}
#}}}
sub set_file { #{{{
    $__arename_file = $_[0];
}
#}}}

#}}}
# section handling code {{{

sub is_locopt { #{{{
    my ($opt) = @_;

    foreach my $lo (@localizables) {
        if ($lo eq $opt) {
            return 1;
        }
    }

    return 0;
}
#}}}
sub section_matches { #{{{
    my ($filename) = @_;

    if (!defined $filename) {
        return undef;
    }

    # The block in the sort call makes sure we always get the longest
    # section names first; that way /foo/bar/ supersedes /foo/.
    foreach my $section (sort { length $b <=> length $a } keys %sectconf) {
        my $substring = substr($filename, 0, length $section);
        odebug("<$section> ($filename) eq [generated from $filename] ($substring)\n");

        if ($substring eq $section) {
            odebug("$section MATCHED! returning it.\n");
            return $section;
        }
    }

    return undef;
}
#}}}
sub sect_get { #{{{
    return $sect;
}
#}}}
sub sect_set { #{{{
    $sect = $_[0];
}
#}}}
sub sect_reset { #{{{
    $sect = undef;
}
#}}}

#}}}
# {get,set}_opt() API {{{

sub get_opt { #{{{
    my ($opt) = @_;
    my ($section) = (undef);

    odebug("GET OPTION ($opt)\n");
    if (is_locopt($opt)) {
        $section = section_matches(get_file());
    }

    if (defined $section && $sectconf{$section}{$opt}) {
        odebug("returning $conf{$opt} (section: $section)\n");
        return $sectconf{$section}{$opt};
    } else {
        if (defined $conf{$opt}) {
            odebug("returning $conf{$opt}\n");
        }
        return $conf{$opt};
    }
}
#}}}
sub set_opt { #{{{
    my ($opt, $val) = @_;

    my %opttab = (
        force         => "f",
        quiet         => "q",
        quiet_skip    => "Q",
        usehooks      => "H",
        uselocalhooks => "H",
        verbose       => "v"
    );

    if (
        ($opt eq 'verbose' && $val == 1 && get_opt('quiet')) ||
        ($opt eq 'quiet' && $val == 1 && get_opt('verbose'))
       ) {

        return if ($opt eq 'quiet' && cmdopts('v'));
        return if ($opt eq 'verbose' && (cmdopts('q') || cmdopts('Q')));

        die "verbose and quiet set at the same time. Check your config.\n";
    }

    if (!defined $opttab{$opt} || !cmdopts($opttab{$opt})) {
        __set_opt($opt, $val);

        if ($opt eq 'quiet_skip' && $val == 1 && !get_opt('quiet')) {
            __set_opt('quiet', 1);
        }
    } else {
        odebug("(-$opttab{$opt}) given on the cmdline, not touching $opt (will not set to $val).\n");
    }
}
#}}}
sub __set_opt { #{{{
    my ($opt, $val) = @_;

    my $s = sect_get();

    if (defined $s && !is_locopt($opt)) {
        owarn("\"$opt\" is *not* a localizable setting (will not set to $val).\n");
        return;
    }

    if (!defined $s) {
        odebug("set_opt() ($opt) = ($val)\n");
        $conf{$opt} = $val;
    } else {
        odebug("set_opt() ($opt) = ($val) [$s]\n");
        $sectconf{$s}{$opt} = $val;
    }
}
#}}}

#}}}
# default_* code {{{

sub get_defaults { #{{{
    my ($key) = @_;

    return $defaults{$key};
}
#}}}
sub get_default_keys { #{{{

    return sort keys %defaults;
}
#}}}
sub set_defaults { #{{{
    my ($key, $val) = @_;

    $defaults{$key} = $val;
}
#}}}

#}}}
# user-defined-variable API {{{

sub user_get { #{{{
    my ($opt) = @_;

    return $sets{$opt}
}
#}}}
sub user_set { #{{{
    my ($opt, $val) = @_;

    $sets{$opt} = $val;
}
#}}}

#}}}
# hooks code {{{

sub disable_hooks { #{{{
    __set_opt("usehooks", 0);
    __set_opt("uselocalhooks", 0);
}
#}}}
sub __read_hook_file { #{{{
    my ($file) = @_;
    my ($rc);

    if ($file eq '') {
        return 1;
    }

    if (! -e $file) {
        owarn_verbose("Hook file not found ($file).\n");
        return 1;
    }

    $rc = do $file;

    if (!defined $rc && $@) {
        owarn("Could not parse hooks file ($file):\n   - $@\n");
        if (get_opt("hookerrfatal")) {
            exit 1;
        } else {
            return 0;
        }
    } elsif (!defined $rc) {
        owarn("Could not read hooks file ($file):\n   - $!\n");
        if (get_opt("hookerrfatal")) {
            exit 1;
        } else {
            return 0;
        }
    } elsif ($rc != 1) {
        owarn("Reading hooks file \"$file\" did not return 1.\n");
        owarn("  While this is not a fatal problem, it is good practice, to let\n");
        owarn("  perl script files return 1. Just put a '1;' into the last line\n");
        owarn("  of this file to get rid of this warning. Subroutines like\n");
        owarn("  register_hook() and remove_hook() return 1 by default, so sticking\n");
        owarn("  them into the last line of the file will do the trick, too.\n");
    }

    oprint("Hook file read ($file).\n");
    return 1;
}
#}}}
sub read_hook_files { #{{{
    if (get_opt("usehooks")) {
        __read_hook_file( home_find_file($FIND_HOOKS, $FIND_NONAME) );
    }

    if (get_opt('useprofiles')) {
        foreach my $profile (get_profile_list()) {
            __read_hook_file( home_find_file($FIND_PROFHOOKS, $profile) );
        }
    }

    if (get_opt("uselocalhooks")) {
        __read_hook_file("./.arename.hooks.local");
    }
}
#}}}
sub register_hook { #{{{
    my ($namespace, $funref) = @_;

    if (!defined &{ $funref }) {
        owarn("Trying to register undefined subroutine in namespace: $namespace; Ignoring.\n");
        return 1;
    }
    push @{ $hooks{$namespace} }, $funref;

    return 1;
}
#}}}
sub remove_hook { #{{{
    my ($namespace, $funref) = @_;

    for my $i (0 .. scalar @{ $hooks{$namespace} } - 1) {
        if ($funref == $hooks{$namespace}[$i]) {
            # found; remove and rerun ourself to be sure
            # the coderef is not registered more than once
            # in this namespace.
            splice @{ $hooks{$namespace} }, $i, 1;
            remove_hook($namespace, $funref);
            return 1;
        }
    }
    return 1;
}
#}}}
sub run_hook { #{{{
    my ($namespace) = ($_[0]);
    shift;

    if (!defined $hooks{$namespace} || scalar @{ $hooks{$namespace} } == 0) {
        return 0;
    }

    foreach my $funref (@{ $hooks{$namespace} }) {
        $funref->($namespace, @_);
    }

    return 1
}
#}}}
sub startup_hook { #{{{
    run_hook(
        'startup',
        \$NAME, \$VERSION,
        \%conf, \%methods,
        \@supported_tags, \@main::ARGV
    );
}
#}}}

#}}}
# configuration dumping code {{{

sub dump_string { #{{{
    my ($s) = @_;

    if ($s =~ m/^\s/) {
        return "\\$s";
    } else {
        return "$s";
    }
}
#}}}
sub dump_config { #{{{
    # XXX: Oh baby, this one needs some serious lovin...
    #      It works as I want it to, but it's ugly as fuck.
    my ($val);

    foreach my $setting (sort @settables) {
        if ($setting =~ m/^(comp_|)template$/) {
            next;
        }

        $val = dump_string($conf{$setting});

        if ($val ne '') {
            printf "%-18s   %s\n", "$setting", "$val";
        } else {
            print "$setting\n";
        }
    }

    print "\n";
    foreach my $setting ('comp_template', 'template') {
        $val = dump_string($conf{$setting});

        if ($val ne '') {
            printf "%-13s   %s\n", "$setting", "$val";
        } else {
            print "$setting\n";
        }
    }

    foreach my $default (sort keys %defaults) {
        print "default_$default " . dump_string($defaults{$default}) . "\n";
    }

    if (%sets) {
        print "\n# user defined settings (see manual for details)\n\n";
    }
    foreach my $key (sort keys %sets) {
        print "set $key = " . dump_string($sets{$key}) . "\n";
    }

    if (%profiles) {
        print "\n# profile definitions (commented out on purpose)\n\n";
    }
    foreach my $key (sort keys %profiles) {
        foreach my $pat (@{ $profiles{$key} }) {
            print "#profile $key $pat\n";
        }
    }

    if (%sectconf) {
        print "\n# section definition(s)\n";

        foreach my $sect (sort keys %sectconf) {
            print "\n[$sect]\n";

            foreach my $setting (sort keys %{ $sectconf{$sect} }) {
                if ($setting =~ m/^(comp_|)template$/) {
                    next;
                }

                $val = dump_string($sectconf{$sect}{$setting});

                if ($val ne '') {
                    printf "%-18s   %s\n", "$setting", "$val";
                } else {
                    print "$setting\n";
                }
            }
            if (defined $sectconf{$sect}{'template'}
                || defined $sectconf{$sect}{'comp_template'}) {

                print "\n";
                foreach my $setting ('comp_template', 'template') {
                    if (!defined$sectconf{$sect}{$setting}) {
                        next;
                    }

                    $val = dump_string($sectconf{$sect}{$setting});

                    if ($val ne '') {
                        printf "%-13s   %s\n", "$setting", "$val";
                    } else {
                        print "$setting\n";
                    }
                }
            }
        }
    }

    exit 0;
}
#}}}

#}}}

1;
