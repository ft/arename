#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

use ARename;

# feed some parse_defaultvalues() {{{

lives_ok { ARename::parse_defaultvalues("testrc", 1, 0, "default_artist",      "Mastodon" ), } 'default parser must live (artist)';
lives_ok { ARename::parse_defaultvalues("testrc", 2, 1, "default_album",       "Leviathan"), } 'default parser must live (album)';
lives_ok { ARename::parse_defaultvalues("testrc", 3, 2, "default_tracktitle",  "I am Ahab"), } 'default parser must live (tracktitle)';
lives_ok { ARename::parse_defaultvalues("testrc", 4, 3, "default_tracknumber", "02"       ), } 'default parser must live (tracknumber)';
lives_ok { ARename::parse_defaultvalues("testrc", 5, 4, "default_genre",       "Metal"    ), } 'default parser must live (genre)';

#}}}
# read some back {{{
is( ARename::get_defaults("artist"     ), "Mastodon",  "default_artist"      );
is( ARename::get_defaults("album"      ), "Leviathan", "default_album"       );
is( ARename::get_defaults("tracktitle" ), "I am Ahab", "default_tracktitle"  );
is( ARename::get_defaults("tracknumber"), "02",        "default_tracknumber" );
is( ARename::get_defaults("genre"      ), "Metal",     "default_genre"       );

#}}}
