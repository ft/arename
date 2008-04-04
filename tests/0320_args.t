#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

use ARename;

# Test if -v and -q are given. {{{
# read_cmdline_options() should fail in that case.

@main::ARGV=( '-v', '-q' );
dies_ok { ARename::read_cmdline_options() } "faking -v *and* -q, which should fail";

#}}}
# Test if -v and -Q are given. {{{
# read_cmdline_options() should fail in that case.

ARename::data_reset();
@main::ARGV=( '-v', '-Q' );
dies_ok { ARename::read_cmdline_options() } "faking -v *and* -Q, which should fail";

#}}}
# Give an allowed combination of options but do not include a file {{{
# name; ARename::read_cmdline_options() must fail again.

ARename::data_reset();
@main::ARGV=( '-Q', '-d', '-l' );
dies_ok { ARename::read_cmdline_options() } "allowed combination: (-Q -d -l), but no file! - dies";

#}}}
# Use an allowed option combination and give a file name, too. {{{
# read_cmdline_options() must succeed in this case.
# Also check if the call sets the appropriate settings.

ARename::data_reset();
@main::ARGV=( '-Q', '-l', 'foo.ogg' );
lives_ok { ARename::read_cmdline_options() } "allowed combination: (-Q -l)";
is( ARename::get_opt('quiet_skip'), 1, "-Q should set quiet_skip");
is( ARename::get_opt('quiet'),      1, "-Q should also force quiet to be set");

#}}}
# Use -s alone, without giving addtional file names. Since -s is for {{{
# reading file names from stdin, read_cmdline_options() must succeed.
# Also check if the call sets the appropriate settings.

ARename::data_reset();
@main::ARGV=( '-s' );
lives_ok { ARename::read_cmdline_options() } "allowed combination: (-s) even without given file";
is( ARename::get_opt('readstdin'), 1, "-s should set readstdin");

#}}}
