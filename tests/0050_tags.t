#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use ARename;

# just check if all tags mentioned in the docs are recognized
# by ARename.pm
is( ARename::tag_supported("album"),        1, "album       tag supported" );
is( ARename::tag_supported("artist"),       1, "artist      tag supported" );
is( ARename::tag_supported("compilation"),  1, "compilation tag supported" );
is( ARename::tag_supported("genre"),        1, "genre       tag supported" );
is( ARename::tag_supported("tracknumber"),  1, "tracknumber tag supported" );
is( ARename::tag_supported("tracktitle"),   1, "tracktitle  tag supported" );
is( ARename::tag_supported("year"),         1, "year        tag supported" );
