#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;

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
# ...new ones, that are actually information about the data stream.
is( ARename::tag_supported("bitrate"),      1, "bitrate     tag supported" );
is( ARename::tag_supported("channels"),     1, "channels    tag supported" );
is( ARename::tag_supported("length_ms"),    1, "length_ms   tag supported" );
is( ARename::tag_supported("samplerate"),   1, "samplerate  tag supported" );

# File type specific tags which we're supporting now.
# `tag_supported()' returns 2 for these.
is( ARename::tag_supported("flac_wordsize"), 2,
    "flac_wordsize tag supported" );
is( ARename::tag_supported("mp3_id3_version"), 2,
    "mp3_id3_version tag supported" );
