#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use Test::Exception;

BEGIN { use_ok('ARename') };

my (%compare_data, $rc, $verbose);
my (%bazooka, %foo, %myhands, %tequilla, %waylon);

$verbose = 0;
ARename::set_opt('shutup', 1);
ARename::set_opt('quiet',  1);

# data hashes {{{

%bazooka = (
    #{{{
    artist      => "Bazooka George and the Shirt",
    album       => "Bodyfluids",
    tracknumber => "02",
    tracktitle  => "Crap me!",
    year        => "2006",
    #}}}
);

%foo = (
    #{{{
    artist      => "Foo Bar",
    album       => "Deaftracks",
    tracknumber => "01",
    tracktitle  => "FOO",
    year        => "1980",
    #}}}
);

%myhands = (
    #{{{
    artist      => "My Hands",
    album       => "Bakerstreet",
    tracknumber => "19",
    tracktitle  => "Running all over You",
    year        => "1982",
    #}}}
);

%tequilla = (
    #{{{
    artist      => "Tequilla",
    album       => "Compilation from Hell",
    compilation => "Various Artists",
    tracknumber => "12",
    tracktitle  => "Ghost Busters",
    year        => "2008",
    #}}}
);

%waylon = (
    #{{{
    artist      => "Waylon and his Banjo",
    album       => "Red",
    tracknumber => "01",
    tracktitle  => "...neck love",
    year        => "1952",
    #}}}
);

#}}}
# custom $postproc subroutine {{{

sub reset_data { undef %compare_data; }
sub rc { return $rc; }

sub compare {
    my ($datref, $ext) = @_;

    $rc = 0;
    foreach my $key (sort keys %compare_data) {
        if ($verbose > 0) {
            print "DEBUG: ($datref->{$key}) ?= ($compare_data{$key})\n";
        }
        if ($datref->{$key} ne $compare_data{$key}) {
            reset_data();
            return;
        }
    }

    reset_data();
    $rc = 1;
}

ARename::set_postproc(\&compare);

#}}}
# direct ogg tests {{{

ARename::set_file('./tests/data/Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.ogg');
%compare_data = %bazooka;

ARename::process_ogg();
is( rc(), 1, "process_ogg(Bazooka George...");

######################################################################

ARename::set_file('./tests/data/Foo Bar - Deaftracks - 01. Foo.ogg');
%compare_data = %foo;

ARename::process_ogg();
is( rc(), 1, "process_ogg(Foo Bar - Deaftracks...");

######################################################################

ARename::set_file('./tests/data/My Hands - Bakerstreet - 19. Running all over You.ogg');
%compare_data = %myhands;

ARename::process_ogg();
is( rc(), 1, "process_ogg(My Hands - Bakerstreet -...");

######################################################################

ARename::set_file('./tests/data/Tequilla - Compilation from Hell - 12. Ghost Busters.ogg');
%compare_data = %tequilla;

ARename::process_ogg();
is( rc(), 1, "process_ogg(Tequilla - Compilation...");

######################################################################

ARename::set_file('./tests/data/Waylon and his Banjo - Red - 01. ...neck love.ogg');
%compare_data = %waylon;

ARename::process_ogg();
is( rc(), 1, "process_ogg(Waylon and his Banjo - Red -...");

#}}}
# direct flac tests {{{

ARename::set_file('./tests/data/Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.flac');
%compare_data = %bazooka;

ARename::process_flac();
is( rc(), 1, "process_flac(Bazooka George...");

######################################################################

ARename::set_file('./tests/data/Foo Bar - Deaftracks - 01. Foo.flac');
%compare_data = %foo;

ARename::process_flac();
is( rc(), 1, "process_flac(Foo Bar - Deaftracks...");

######################################################################

ARename::set_file('./tests/data/My Hands - Bakerstreet - 19. Running all over You.flac');
%compare_data = %myhands;

ARename::process_flac();
is( rc(), 1, "process_flac(My Hands - Bakerstreet -...");

######################################################################

ARename::set_file('./tests/data/Tequilla - Compilation from Hell - 12. Ghost Busters.flac');
%compare_data = %tequilla;

ARename::process_flac();
is( rc(), 1, "process_flac(Tequilla - Compilation...");

######################################################################

ARename::set_file('./tests/data/Waylon and his Banjo - Red - 01. ...neck love.flac');
%compare_data = %waylon;

ARename::process_flac();
is( rc(), 1, "process_flac(Waylon and his Banjo - Red -...");

#}}}
# direct mp3 tests {{{

ARename::set_file('./tests/data/Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.mp3');
%compare_data = %bazooka;

ARename::process_mp3();
is( rc(), 1, "process_mp3(Bazooka George...");

######################################################################

ARename::set_file('./tests/data/Foo Bar - Deaftracks - 01. Foo.mp3');
%compare_data = %foo;

ARename::process_mp3();
is( rc(), 1, "process_mp3(Foo Bar - Deaftracks...");

######################################################################

ARename::set_file('./tests/data/My Hands - Bakerstreet - 19. Running all over You.mp3');
%compare_data = %myhands;

ARename::process_mp3();
is( rc(), 1, "process_mp3(My Hands - Bakerstreet -...");

######################################################################

ARename::set_file('./tests/data/Tequilla - Compilation from Hell - 12. Ghost Busters.mp3');
%compare_data = %tequilla;

ARename::process_mp3();
is( rc(), 1, "process_mp3(Tequilla - Compilation...");

######################################################################

ARename::set_file('./tests/data/Waylon and his Banjo - Red - 01. ...neck love.mp3');
%compare_data = %waylon;

ARename::process_mp3();
is( rc(), 1, "process_mp3(Waylon and his Banjo - Red -...");

#}}}
# automatic processing tests {{{

%compare_data = %bazooka;
ARename::process_file('./tests/data/Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.ogg');
is( rc(), 1, "process_file(Bazooka George...                    [.ogg]");

######################################################################

%compare_data = %foo;
ARename::process_file('./tests/data/Foo Bar - Deaftracks - 01. Foo.flac');
is( rc(), 1, "process_file(Foo Bar - Deaftracks...             [.flac]");

######################################################################

%compare_data = %myhands;
ARename::process_file('./tests/data/My Hands - Bakerstreet - 19. Running all over You.mp3');
is( rc(), 1, "process_file(My Hands - Bakerstreet -...          [.mp3]");

######################################################################

%compare_data = %tequilla;
ARename::process_file('./tests/data/Tequilla - Compilation from Hell - 12. Ghost Busters.flac');
is( rc(), 1, "process_file(Tequilla - Compilation...           [.flac]");

######################################################################

%compare_data = %waylon;
ARename::process_file('./tests/data/Waylon and his Banjo - Red - 01. ...neck love.ogg');
is( rc(), 1, "process_file(Waylon and his Banjo - Red -...      [.ogg]");

#}}}
