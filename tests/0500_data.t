#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

use ARename;

# set_file() may *never* *ever* die

lives_ok { ARename::set_file('foo123.ogg') } 'set_file() must live';
is( ARename::get_file(), "foo123.ogg", "{set,get}_file()");

# neither may user_set()

lives_ok { ARename::user_set('my_setting', 'Vaaaaalue!') } 'set_file() must live';
is( ARename::user_get('my_setting'), "Vaaaaalue!", "user_{set,get}()");

# checking set_opt()

lives_ok { ARename::set_opt('verbosity', 100) } 'set_file() must live';
is( ARename::get_opt('verbosity'), 100, "set/get verbosity");

# sect_set() must succeed

lives_ok { ARename::sect_set('/my/section') } 'set_file() must live';
is( ARename::sect_get(), "/my/section", "sect_{set,get}()");
