#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use ARename;
ARename::set_default_options();
ARename::set_opt('shutup', 1);
ARename::set_opt('quiet',  1);
ARename::set_file('need-no-file');

my ($expanded, $expected, %waylon);

%waylon = (
    artist      => "Waylon and his Banjo",
    album       => "Red",
    tracknumber => "01",
    tracktitle  => "...neck love",
    year        => "1952",
);

sub equal {
    my ($expected, $generated) = @_;

    if (!defined $generated) {
        print "generated value is not defined (expected \"$expected\"). fail therefore.\n";
        return 0;
    }
    if ($expected eq $generated) { return 1; }

    print "       ($generated)\nis not ($expected), as expected!\n";
    return 0;
}

$expanded = ARename::expand_template('&album', \%waylon);
$expected = "Red";
is( equal($expected, $expanded), 1, "Basic template expansion");

$expanded = ARename::expand_template('&compilation', \%waylon);
$expected = "";
is( !defined $expanded, 1, "Basic template expansion with empty value (expect undefined)");

$expanded = ARename::expand_template('&artist[4]', \%waylon);
$expected = "Wayl";
is( equal($expected, $expanded), 1, "Basic template expansion with specified length");

$expanded = ARename::expand_template('&{album:default}', \%waylon);
$expected = "Red";
is( equal($expected, $expanded), 1, "Complex template expansion &{foo:default} set value");

$expanded = ARename::expand_template('&{compilation:default}', \%waylon);
$expected = "default";
is( equal($expected, $expanded), 1, "Complex template expansion &{foo:default} unset value");

$expanded = ARename::expand_template('&artist &{album?- &album !}- &tracknumber. &tracktitle', \%waylon);
$expected = "Waylon and his Banjo - Red - 01. ...neck love";
is( equal($expected, $expanded), 1, "Complex template expansion &{foo?set!unset} set value");

$expanded = ARename::expand_template('&artist &{compilation?- &compilation !}- &tracknumber. &tracktitle', \%waylon);
$expected = "Waylon and his Banjo - 01. ...neck love";
is( equal($expected, $expanded), 1, "Complex template expansion &{foo?set!unset} unset value");
