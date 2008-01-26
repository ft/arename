#!/usr/bin/perl

package ARename;
use warnings;
use strict;

# modules {{{

# These are commonly installed along with Perl:
use Getopt::Std;
use File::Basename;
use File::Copy;

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
my ( %conf, %defaults, %methods, %opts, $postproc );
my ( $NAME, $VERSION ) = ( 'arename.pl', 'v0.8' );

$postproc = \&arename;
#}}}
sub arename { #{{{
    my ($file, $datref, $ext) = @_;
    my ($t, $newname);

    apply_defaults($datref);
    arename_verbosity($datref);

    $t = choose_template($datref);
    $newname = expand_template($t, $datref);
    return if not defined $newname;
    $newname = $conf{prefix} . '/' . $newname . '.' . $ext;

    if (file_eq($newname, $file)) {
        if ($conf{quiet}) {
            if (!$conf{quiet_skip}) {
                print "Skipping: '$file'\n";
            }
        } else {
            oprint("'$file'\n      would stay the way it is, skipping.\n");
        }
        return;
    }

    if (-e $newname && !$conf{force}) {
        oprint("'$newname' exists." . ($conf{quiet} ? " " : "\n      ")
            . "use '-f' to force overwriting.\n");
        return;
    }

    ensure_dir(dirname($newname));

    if ($conf{quiet}) {
        print "'$newname'\n";
    } else {
        oprint("mv '$file' \\\n         '$newname'\n");
    }

    if (!$conf{dryrun}) {
        xrename($file, $newname);
    }
}
#}}}
sub arename_verbosity { #{{{
    my ($datref) = @_;

    if ($conf{verbose}) {
        oprint("Artist     : \"" . getdat($datref, "artist")      . "\"\n");
        oprint("Compilation: \"" . getdat($datref, "compilation") . "\"\n");
        oprint("Album      : \"" . getdat($datref, "album")       . "\"\n");
        oprint("Tracktitle : \"" . getdat($datref, "tracktitle")  . "\"\n");
        oprint("Tracknumber: \"" . getdat($datref, "tracknumber") . "\"\n");
        oprint("Genre      : \"" . getdat($datref, "genre")       . "\"\n");
        oprint("Year       : \"" . getdat($datref, "year")        . "\"\n");
    }
}
#}}}
sub apply_defaults { #{{{
    my ($datref) = @_;

    foreach my $key (keys %defaults) {
        if (!defined $datref->{$key}) {
            if ($conf{verbose}) {
                oprint("Setting ($key) to \"$defaults{$key}\".\n");
            }
            $datref->{$key} = $defaults{$key};
        }
    }
}
#}}}
sub choose_template { #{{{
    my ($datref) = @_;

    if (defined $datref->{compilation}
        && $datref->{compilation} ne $datref->{artist}) {

        return $conf{comp_template};
    } else {
        return $conf{template};
    }
}
#}}}
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
            if (($conf{dryrun} || $conf{verbose}) && !$conf{quiet}) {
                oprint("mkdir \"$sofar\"\n");
            }
            if (!$conf{dryrun}) {
                mkdir($sofar) or die "Could not mkdir($sofar).\n" .
                                     "Reason: $!\n";
            }
        }
    }
}
#}}}
sub expand_template { #{{{
    my ($template, $datref) = @_;
    my @tags = (
        'album',
        'artist',
        'compilation',
        'genre',
        'tracknumber',
        'tracktitle',
        'year'
    );

    foreach my $tag (@tags) {
        my ($len, $token);

        while ($template =~ m/&$tag(\[(\d+)\]|)/) {
            $len = 0;
            if (defined $2) { $len = $2; }

            if (!defined $datref->{$tag} || $datref->{$tag} eq '') {
                owarn("$tag not defined, but required by template. Giving up.\n");
                return undef;
            }

            if ($len > 0) {
                $token = substr($datref->{$tag}, 0, $len);
            } else {
                if ($tag eq 'tracknumber') {
                    my $val;
                    if ($datref->{$tag} =~ m/^([^\/]*)\/.*$/) {
                        $val = $1;
                    } else {
                        $val = $datref->{$tag};
                    }
                    $token = sprintf "%0" . $conf{tnpad} . "d", $val;
                } else {
                    $token = $datref->{$tag};
                }
            }
            if ($token =~ m!/!) {
                if ($conf{verbose}) {
                    oprint("Found directory seperator in token.\n");
                    oprint("Replacing with \"$conf{sepreplace}\".\n");
                }
                $token =~ s!/!$conf{sepreplace}!g;
            }
            $template =~ s/&$tag(\[(\d+)\]|)/$token/;
        }
    }

    return $template;
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
sub getdat { #{{{
    my ($datref, $tag) = @_;

    return defined $datref->{$tag} ? $datref->{$tag} : "-.-";
}
#}}}
sub oprint { #{{{
    my ($string) = @_;

    print $conf{oprefix} . $string;
}
#}}}
sub owarn { #{{{
    my ($string) = @_;

    warn $conf{oprefix} . $string;
}
#}}}
sub rcload { #{{{
    my ($file, $desc) = @_;
    my ($fh, $retval);
    my $count = 0;
    my $lnum  = 0;

    if (!open($fh, "<$file")) {
        warn "Failed to read $desc ($file).\n";
        owarn("Reason: $!\n");
        return 1;
    }

    print "Reading \"$file\"...\n";

    while (my $line = <$fh>) {
        chomp($line);
        $lnum++;

        if ($line =~ m/^\s*#/ || $line =~ m/^\s*$/) {
            next;
        }

        $line =~ s/^\s*//;
        my ($key,$val) = split(/\s+/, $line, 2);
        if (defined $val) {
            $val =~ s/^\\//;
        }

        # TODO: Improve this mess.
        if ($key eq 'template') {
            $conf{template} = $val;
        } elsif ($key eq 'comp_template') {
            $conf{comp_template} = $val;
        } elsif ($key eq 'sepreplace') {
            $conf{sepreplace} = (defined $val ? $val : "");
        } elsif ($key eq 'tnpad') {
            $conf{tnpad} = $val;
        } elsif ($key eq 'verbose') {
            if ($conf{quiet}) {
                die "$file,$lnum: quiet set. verbose not allowed.\n";
            }
            $conf{verbose} = 1;
        } elsif ($key eq 'quiet') {
            if ($conf{verbose}) {
                die "$file,$lnum: verbose set. quiet not allowed.\n";
            }
            $conf{quiet} = 1;
        } elsif ($key eq 'quiet_skip') {
            $conf{quiet_skip} = 1;
        } elsif ($key eq 'prefix') {
            $conf{prefix} = $val;
        } elsif ($key eq 'default_artist') {
            $defaults{artist}      = $val;
        } elsif ($key eq 'default_album') {
            $defaults{album}       = $val;
        } elsif ($key eq 'default_compilation') {
            $defaults{compilation} = $val;
        } elsif ($key eq 'default_genre') {
            $defaults{genre}       = $val;
        } elsif ($key eq 'default_tracknumber') {
            $defaults{tracknumber} = $val;
        } elsif ($key eq 'default_tracktitle') {
            $defaults{tracktitle}  = $val;
        } elsif ($key eq 'default_year') {
            $defaults{year}        = $val;
        } else {
            warn "$file,$lnum: invalid line '$line'.\n";
            return -1;
        }

        $count++;
    }
    close $fh;

    oprint("Read $desc.\n");
    oprint("$count valid items.\n");
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

sub handle_vorbistag { #{{{
    my ($datref, $tag, $value) = @_;
    my ($realtag);

    if (!(
            $tag =~ m/^ALBUM$/i         ||
            $tag =~ m/^ARTIST$/i        ||
            $tag =~ m/^TITLE$/i         ||
            $tag =~ m/^TRACKNUMBER$/i   ||
            $tag =~ m/^DATE$/i          ||
            $tag =~ m/^GENRE$/i         ||
            $tag =~ m/^ALBUMARTIST$/i
        )) { next; }

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
}
#}}}
sub process_flac { #{{{
    my ($file) = @_;
    my ($flac, %data, $tags);

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

    $postproc->($file, \%data, 'flac');
}
#}}}
sub process_mp3 { #{{{
    my ($file) = @_;
    my ($mp3, %data, $info);

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

    if (exists $mp3->{ID3v2}) {
        ($data{artist},      $info) = $mp3->{ID3v2}->get_frame("TPE1");
        ($data{compilation}, $info) = $mp3->{ID3v2}->get_frame("TPE2");
        ($data{album},       $info) = $mp3->{ID3v2}->get_frame("TALB");
        ($data{tracktitle},  $info) = $mp3->{ID3v2}->get_frame("TIT2");
        ($data{tracknumber}, $info) = $mp3->{ID3v2}->get_frame("TRCK");
        ($data{genre},       $info) = $mp3->{ID3v2}->get_frame("TCON");
        ($data{year},        $info) = $mp3->{ID3v2}->get_frame("TYER");
    } elsif (exists $mp3->{ID3v1}) {
        oprint("Only found ID3v1 tag.\n");
        $data{artist}      = $mp3->{ID3v1}->artist;
        $data{album}       = $mp3->{ID3v1}->album;
        $data{tracktitle}  = $mp3->{ID3v1}->title;
        $data{tracknumber} = $mp3->{ID3v1}->track;
        $data{genre}       = $mp3->{ID3v1}->genre;
        $data{year}        = $mp3->{ID3v1}->year;
    }

    $mp3->close();

    $postproc->($file, \%data, 'mp3');
}
#}}}
sub process_ogg { #{{{
    my ($file) = @_;
    my ($ogg, %data, @tags);

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

    $postproc->($file, \%data, 'ogg');
}
#}}}
sub process_warn { #{{{
    my ($file) = @_;

    owarn("No method for handling \"$file\".\n");
}
#}}}

sub apply_methods { #{{{
    my ($file, $exit) = @_;

    foreach my $method (sort keys %methods) {
        if ($file =~ m/$method/i) {
            $methods{$method}->($file);
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
sub read_rcs { #{{{
    my $rc = $ENV{HOME} . "/.arenamerc";
    my $retval = rcload($rc, "arename.pl configuration");

    if ($retval < 0) {
        die "Error(s) in \"$rc\". Aborting.\n";
    } elsif ($retval > 0) {
        warn "Error opening configuration; using defaults.\n";
    }

    if (-r "./.arename.local") {
        $rc = "./.arename.local";
        $retval = rcload($rc, "local configuration");
        if ($retval < 0) {
            die "Error(s) in \"$rc\". Aborting.\n";
        } elsif ($retval > 0) {
            warn "Error opening local configuration.\n";
        }
    }

    print "\n";
}
#}}}
sub read_cmdline_options { #{{{
    if ($#main::ARGV == -1) {
        $opts{h} = 1;
    } else {
        if (!getopts('dfhQqVvp:T:t:', \%opts)) {
            if (exists $opts{t} && !defined $opts{t}) {
                die " -t *requires* a string argument!\n";
            } elsif (exists $opts{T} && !defined $opts{T}) {
                die " -T *requires* a string argument!\n";
            } elsif (exists $opts{p} && !defined $opts{p}) {
                die " -p *requires* a string argument!\n";
            } else {
                die "    Try $NAME -h\n";
            }
        }
    }

    if (defined $opts{h}) {
        usage();
        exit 0;
    }

    if (defined $opts{q} && defined $opts{v}) {
        print "Verbose *and* quiet? Please decide!\n";
        exit 1;
    }

    if (defined $opts{V}) {
        print " $NAME $VERSION\n";
        exit 0;
    }
}
#}}}
sub set_cmdline_options { #{{{
    my ($argc) = @_;

    if ($argc == -1) {
        die "No input files. See: $NAME -h\n";
    }

    if (!$conf{verbose} && defined $opts{v}) {
        $conf{verbose} = $opts{v};
        $conf{quiet} = 0;
    }

    if (defined $opts{q}) {
        $conf{quiet} = $opts{q};
        $conf{verbose} = 0;
    }

    if (defined $opts{Q}) {
        if (!$conf{quiet}) {
            die "quiet_skip (-Q) does not make sense without quiet (-q).\n";
        }
        $conf{quiet_skip} = $opts{Q};
    }

    if (defined $opts{f}) {
        $conf{force} = $opts{f};
    }

    if (defined $opts{p}) {
        $conf{prefix} = $opts{p};
    }

    if (defined $opts{t}) {
        $conf{template} = $opts{t};
    }

    if (defined $opts{T}) {
        $conf{comp_template} = $opts{T};
    }

    if (defined $opts{d}) {
        $conf{dryrun} = $opts{d};
    }

    undef %opts;
}
#}}}
sub set_default_options { #{{{
    $conf{dryrun}        = 0;
    $conf{force}         = 0;
    $conf{oprefix}       = '  -!- ';
    $conf{prefix}        = '.';
    $conf{sepreplace}    = '_';
    $conf{tnpad}         = 2;
    $conf{verbose}       = 0;
    $conf{comp_template} = "va/&album/&tracknumber - &artist - &tracktitle";
    $conf{template}      = "&artist[1]/&artist/&album/&tracknumber - &tracktitle";
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
sub set_postproc { #{{{
    $postproc = $_[0];
}
#}}}
sub usage { #{{{
    print " Usage:\n  $NAME [OPTION(s)] FILE(s)...\n\n";
    print "    -d                Go into dryrun mode.\n";
    print "    -f                Overwrite files if needed.\n";
    print "    -h                Display this help text.\n";
    print "    -Q                Don't display skips in quiet mode.\n";
    print "    -q                Enable quiet output.\n";
    print "    -V                Display version infomation.\n";
    print "    -v                Enable verbose output.\n";
    print "    -p <prefix>       Define a prefix for destination files.\n";
    print "    -T <template>     Define a compilation template.\n";
    print "    -t <template>     Define a generic template.\n";
    print "\n";
}
#}}}

sub get_opt { #{{{
    my ($opt) = @_;

    return $conf{$opt}
}
#}}}
sub set_opt { #{{{
    my ($opt, $val) = @_;

    $conf{$opt} = $val;
}
#}}}

1;
