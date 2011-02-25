#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use ARename;

ARename::user_set('foo', 'doob');
# not an actual option, but this test doesn't care.
ARename::set_opt('template', 'zork');
ARename::sect_set('/bar/baz/');
ARename::user_set('foo', 'bood');
ARename::set_opt('template', 'clang!');
ARename::sect_reset();

# #1
is( ARename::get_opt('template'), 'zork', "works with no file set yet [normal]" );
# #2
is( ARename::user_get('foo'), 'doob', "works with no file set yet [user]" );

# #3
ARename::set_file('/zack/whee.mp3');
is( ARename::get_opt('template'), 'zork', "works with file set, no matching section [normal]" );
# #4
is( ARename::user_get('foo'), 'doob', "works with file set, no matching section [user]" );

# #5
ARename::set_file('/bar/baz/whee.mp3');
is( ARename::get_opt('template'), 'clang!', "works with file set, matching section [normal]" );
# #6
is( ARename::user_get('foo'), 'bood', "works with file set, matching section [user]" );
