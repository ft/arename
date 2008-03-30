#!/usr/bin/perl

use strict;
# use warnings; # enable when writing!
                # disable else, because we redefine xrename() and
                # ensure_dir(); we know that, so don't warn us.

use Test::More tests => 6;
use Test::Exception;

BEGIN { use_ok('ARename') };

# test if the template is correctly choosen {{{

ARename::set_default_options();

my $ct = "compilation template";
my $nt = "normal template";
my ($curtemp, $dr);

sub export_dr {
    my ($datref, $ext) = @_;

    $dr = $datref
}

ARename::set_postproc(\&export_dr);

sub is_comp {
    if ($curtemp eq $ct) { return 1; }
    return 0;
}

sub is_norm {
    if ($curtemp eq $nt) { return 1; }
    return 0;
}

ARename::set_opt("comp_template", "compilation template");
ARename::set_opt("template", "normal template");

ARename::set_file('./tests/data/Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.ogg');
ARename::process_ogg();
$curtemp = ARename::choose_template($dr);
is( is_comp(), 0, "Didn't choose the compilation template for Bazooka George...");
is( is_norm(), 1, "Chose the normal template for Bazooka George...");

ARename::set_file('./tests/data/Tequilla - Compilation from Hell - 12. Ghost Busters.ogg');
ARename::process_ogg();
$curtemp = ARename::choose_template($dr);
is( is_norm(), 0, "Didn't choose the normal template for Tequilla...");
is( is_comp(), 1, "Chose the compilation template for Tequilla...");

#}}}

# do a real renaming run {{{

ARename::set_default_options();
ARename::set_postproc(\&ARename::arename);

my ($newname);

{
    package ARename;

    # change some functions from ARename.pm, in order to just do checks,
    # not actually change names or create directories.
    sub ensure_dir { };

    sub xrename {
        $main::newname = $_[1];
    }
}

sub equal {
    my ($expected, $generated) = @_;

    if ($expected eq $generated) { return 1; }

    print "       ($generated)\nis not ($expected), as expected!\n";
    return 0;
}

ARename::set_opt('template', "(&year) - &artist - &album - &tracknumber. &tracktitle");
ARename::set_opt('prefix', './blah');
ARename::set_opt('shutup', 1);
ARename::set_opt('quiet',  1);

ARename::set_file('./tests/data/Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.ogg');
ARename::process_ogg();

is( equal($main::newname, "./blah/(2006) - Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.ogg"),
    1, "See if the correct filename would be generated");

#}}}
