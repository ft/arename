#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More tests => 24;
use Test::Exception;

use ARename;
ARename::set_default_options();
ARename::set_opt('verbosity', -1);
ARename::set_opt('template_aliases', 0);
ARename::set_file('need-no-file');

my ($expanded, $expected, %waylon, %woot, %sob);

%waylon = (
    artist      => "Waylon and his Banjo",
    album       => "Red",
    tracknumber => "01",
    tracktitle  => "...neck love",
    year        => "1952",
);

%woot = (
    artist      => "Woot",
    album       => "Gain or drain",
    tracknumber => "7",
    tracktitle  => "Wag a leg",
    year        => "1992",
);

# check for infinite-loops
%sob = (
    album => "&album",
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

$expanded = ARename::expand_template('No tag at all', \%waylon);
$expected = "No tag at all";
is( equal($expected, $expanded), 1, "Basic template expansion without tags even");

$expanded = ARename::expand_template('Multibyte strings, (here: UTF8): öäü', \%waylon);
$expected = "Multibyte strings, (here: UTF8): öäü";
is( equal($expected, $expanded), 1, "Multibyte strings are correctly assembled again");

$expanded = ARename::expand_template('&album', \%waylon);
$expected = "Red";
is( equal($expected, $expanded), 1, "Basic template expansion");

$expanded = ARename::expand_template('&album', \%sob);
$expected = "&album";
is( equal($expected, $expanded), 1, "Do not produce infinite loops, if album tag is '&album'");

$expanded = ARename::expand_template('\&album', \%waylon);
$expected = "&album";
is( equal($expected, $expanded), 1, "Quoting the & with a \\");

$expanded = ARename::expand_template('&compilation', \%waylon);
$expected = "";
is( !defined $expanded, 1, "Basic template expansion with empty value (expect undefined)");

$expanded = ARename::expand_template('&artist[4]', \%waylon);
$expected = "Wayl";
is( equal($expected, $expanded), 1, "Basic template expansion with specified length");

$expanded = ARename::expand_template('&artist[12]', \%waylon);
$expected = "Waylon and h";
is( equal($expected, $expanded), 1, "Basic template expansion with specified length > 9");

$expanded = ARename::expand_template('&artist[6] - &album - &tracknumber. &tracktitle (&year)', \%waylon);
$expected = "Waylon - Red - 01. ...neck love (1952)";
is( equal($expected, $expanded), 1, "Complete test for simple tags template");

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

$expanded = ARename::expand_template('&artist &{album?- &{compilation?&compilation!&album} !}- &tracknumber. &tracktitle', \%waylon);
$expected = "Waylon and his Banjo - Red - 01. ...neck love";
is( equal($expected, $expanded), 1, "Complex template expansion &{foo?set!unset} - nested 0");

$expanded = ARename::expand_template('&artist &{compilation?- &compilation !&{album?- &album !}}- &tracknumber. &tracktitle', \%waylon);
$expected = "Waylon and his Banjo - Red - 01. ...neck love";
is( equal($expected, $expanded), 1, "Complex template expansion &{foo?set!unset} - nested 1");

$expanded = ARename::expand_template('&artist &{compilation?- &compilation !&{album2?- &album2 !}}- &tracknumber. &tracktitle', \%waylon);
$expected = "Waylon and his Banjo - 01. ...neck love";
is( equal($expected, $expanded), 1, "Complex template expansion &{foo?set!unset} - nested 2");

$expanded = ARename::expand_template('FOO - &{blah:&{album?&artist - &{tracktitle?&tracktitle[7]!NONE}!ZACK} &{bang:BOOM}} - BAR', \%waylon);
$expected = "FOO - Waylon and his Banjo - ...neck BOOM - BAR";
is( equal($expected, $expanded), 1, "Multiple nesting levels with complex tag expansions");

$expanded = ARename::expand_template('&{bar:\&{album?&album!album}', \%waylon);
$expected = "&{album?Red!album";
is( equal($expected, $expanded), 1, "Quoting characters in extended tag expansions");

$expanded = ARename::expand_template('&tracknumber', \%woot);
$expected = "07";
is( equal($expected, $expanded), 1, "Default track-no padding 7->07");

$expanded = ARename::expand_template('\b', \%woot);
$expected = "b";
is( equal($expected, $expanded), 1, "Escaped non-metacharacter should work and NOT hang");

$expanded = ARename::expand_template('somewhere i\n \betw\e\en!', \%woot);
$expected = "somewhere in between!";
is( equal($expected, $expanded), 1, "Escaped non-metacharacter should work");

# With `template_aliases' off "&al" should return 0.
$expanded = ARename::template_deep_inspect('&al');
$expected = 0;
is( equal($expected, $expanded), 1, "Warn of aliases with template_aliases off");

ARename::set_opt('template_aliases', 1);
# With `template_aliases' on however, "&al" should return 1.
$expanded = ARename::template_deep_inspect('&al');
$expected = 1;
is( equal($expected, $expanded), 1, "No alias warning with template_aliases on");

# "&{artist &album" caused infinite loop.
is(ARename::expand_template("&{artist&foo}", \%woot),
   undef,
   "Unclosed template expansion with trailing expansion");
