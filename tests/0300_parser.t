#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

use ARename;
ARename::set_opt('shutup', 1);

# feed some valid lines into the parser() {{{

is( ARename::parse("testrc", 1, 0, "canonicalize", "true"           ), 0, 'parser must return 0 (canonicalize)');
is( ARename::parse("testrc", 1, 0, "hookerrfatal", "true"           ), 0, 'parser must        0 (hookerrfatal)');
is( ARename::parse("testrc", 1, 0, "prefix",       "/mnt/extern/tmp"), 0, 'parser must        0 (prefix)');
is( ARename::parse("testrc", 1, 0, "set",
                "albumless_template = misc/&artist - &tracktitle"   ), 0, 'parser must        0 (set albumless_template)');
is( ARename::parse("testrc", 1, 0, "tnpad",        "3"              ), 0, 'parser must        0 (tnpad)');
is( ARename::parse("testrc", 1, 0, "[/tmp/foo/]",  ""               ), 0, 'parser must        0 (section: [/tmp/foo/])');
is( ARename::parse("testrc", 1, 0, "profile",      "baz /foo/bar"   ), 0, 'parser must return 1 (warning triggered)' );
is( ARename::parse("testrc", 1, 0, "profile",      "b.z /foo/bar"   ), 1, 'parser must return 1 (warning triggered)' );
is( ARename::parse("testrc", 1, 0, "foo",  ""                       ), 2, 'parser must return 2 (unknown systax)' );

#}}}
# and test some of the read settings for correctness {{{

is( ARename::get_opt("canonicalize"), "1", 'canonicalize set to 1' );
is( ARename::get_opt("hookerrfatal"), "1", 'hookerrfatal set to 1' );
is( ARename::get_opt("prefix"), "/mnt/extern/tmp", 'prefix: /mnt/extern/tmp' );
is( ARename::user_get("albumless_template"), "misc/&artist - &tracktitle", 'albumless_template (user_set): misc/&artist - &tracktitle' );

#}}}
