#!/usr/bin/perl

use strict;
use warnings;

use ARename;

my (%compare_data, $rc, $verbose, $test_num, $files_n, $types_n);
my (%bazooka, %foo, %myhands, %tequilla, %waylon, %files);
my (@types);

$verbose = 0;
ARename::set_opt('shutup', 1);
ARename::set_opt('quiet',  1);

# data hashes
# BEGIN is needed to be able to calculate the number of tests in here.
BEGIN {

    @types = qw( flac mp3 ogg );
    %files = (
        "./tests/data/Bazooka George and the Shirt - Bodyfluids - 02. Crap me!" => \%bazooka,
        "./tests/data/Foo Bar - Deaftracks - 01. Foo" => \%foo,
        "./tests/data/My Hands - Bakerstreet - 19. Running all over You" => \%myhands,
        "./tests/data/Tequilla - Compilation from Hell - 12. Ghost Busters" => \%tequilla,
        "./tests/data/Waylon and his Banjo - Red - 01. ...neck love" => \%waylon,
    );

    $files_n = scalar keys %files;
    $types_n = $#types + 1;
    $test_num = $types_n * $files_n;
}

%bazooka = (
    artist      => "Bazooka George and the Shirt",
    album       => "Bodyfluids",
    tracknumber => "02",
    tracktitle  => "Crap me!",
    year        => "2006",
);

%foo = (
    artist      => "Foo Bar",
    album       => "Deaftracks",
    tracknumber => "01",
    tracktitle  => "FOO",
    year        => "1980",
);

%myhands = (
    artist      => "My Hands",
    album       => "Bakerstreet",
    tracknumber => "19",
    tracktitle  => "Running all over You",
    year        => "1982",
);

%tequilla = (
    artist      => "Tequilla",
    album       => "Compilation from Hell",
    compilation => "Various Artists",
    tracknumber => "12",
    tracktitle  => "Ghost Busters",
    year        => "2008",
);

%waylon = (
    artist      => "Waylon and his Banjo",
    album       => "Red",
    tracknumber => "01",
    tracktitle  => "...neck love",
    year        => "1952",
);

sub reset_data {
    undef %compare_data;
}

sub rc {
    return $rc;
}

# custom $postproc subroutine
sub compare {
    my ($datref, $ext) = @_;

    $rc = 0;
    foreach my $key (sort keys %compare_data) {
        if ($verbose > 0) {
            print "DEBUG($key): ($datref->{$key}) ?= ($compare_data{$key})\n";
        }
        if ($datref->{$key} ne $compare_data{$key}) {
            reset_data();
            return;
        }
    }

    reset_data();
    $rc = 1;
}

use Test::More tests => $test_num;
use Test::Exception;

ARename::set_postproc(\&compare);

foreach my $type (@types) {
    foreach my $file (sort keys %files) {
        reset_data();
        %compare_data = %{ $files{$file} };
        ARename::set_file("$file.$type");
        ARename::process_file();
        my $f = $file;
        $f =~ s/^.\/tests\/data\///;
        my $substring = substr $f, 0, 23;
        is( rc(), 1, "process_file($substring..., $type");
    }
}
