#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use ARename;

# Test if -v and -q are given. {{{
# read_cmdline_options() should fail in that case.

@main::ARGV=( '--verbose', '--quiet', 'foo.ogg' );
lives_ok { ARename::read_cmdline_options() } "--verbose *and* --quiet";

ARename::data_reset();
@main::ARGV=( '--verbose', '--uber-quiet', 'foo.ogg' );
lives_ok { ARename::read_cmdline_options() } "--verbose *and* --ober-quiet";

# Give an allowed combination of options but do not include a file
# name; ARename::read_cmdline_options() must fail.

ARename::data_reset();
@main::ARGV=( '--uber-quiet', '--dryrun', '--read-local' );
dies_ok {
    ARename::read_cmdline_options();
} "allowed combination: (--uber-quiet --dryrun --read-local), but no file! - dies";

# Use an allowed option combination and give a file name, too.
# read_cmdline_options() must succeed in this case.
# Also check if the call sets the appropriate settings.

ARename::data_reset();
@main::ARGV=( '--uber-quiet', '--read-local', 'foo.ogg' );
lives_ok {
    ARename::read_cmdline_options();
} "allowed combination: (-Q -l)";
lives_ok {
    ARename::read_cmdline_options_late();
} "read_cmdline_options_late() should live, too";

# Use -s alone, without giving addtional file names. Since -s is for
# reading file names from stdin, read_cmdline_options() must succeed.
# Also check if the call sets the appropriate settings.

ARename::data_reset();
@main::ARGV=( '--stdin' );
lives_ok {
    ARename::read_cmdline_options();
} "allowed combination: (--stdin) even without given file";
is( ARename::get_opt('readstdin'), 1, "--stdin should set readstdin");
