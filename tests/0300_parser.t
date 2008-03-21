#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Exception;

BEGIN { use_ok('ARename') };

# feed some valid lines into the parser() {{{

lives_ok { ARename::parse("testrc", 1, 0, "canonicalize", "true"           ) } 'parser must live (canonicalize)';
lives_ok { ARename::parse("testrc", 1, 0, "hookerrfatal", "true"           ) } 'parser must live (hookerrfatal)';
lives_ok { ARename::parse("testrc", 1, 0, "prefix",       "/mnt/extern/tmp") } 'parser must live (prefix)';
lives_ok { ARename::parse("testrc", 1, 0, "set",
                         "albumless_template = misc/&artist - &tracktitle" ) } 'parser must live (set albumless_template)';
lives_ok { ARename::parse("testrc", 1, 0, "tnpad",        "3"              ) } 'parser must live (tnpad)';
lives_ok { ARename::parse("testrc", 1, 0, "[/tmp/foo/]",  ""               ) } 'parser must live (section: [/tmp/foo/])';

#}}}
# and test some of the read settings for correctness {{{

is( ARename::parse("testrc", 1, 0, "foo",  ""), 0, 'Unknown syntax must fail' );
is( ARename::get_opt("canonicalize"), "1", 'canonicalize set to 1' );
is( ARename::get_opt("hookerrfatal"), "1", 'hookerrfatal set to 1' );
is( ARename::get_opt("prefix"), "/mnt/extern/tmp", 'prefix: /mnt/extern/tmp' );
is( ARename::user_get("albumless_template"), "misc/&artist - &tracktitle", 'albumless_template (user_set): misc/&artist - &tracktitle' );

#}}}
