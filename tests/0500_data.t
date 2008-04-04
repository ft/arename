#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

use ARename;

# set_file() may *never* *ever* die {{{

lives_ok { ARename::set_file('foo123.ogg') } 'set_file() must live';
is( ARename::get_file(), "foo123.ogg", "{set,get}_file()");

#}}}
# neither may user_set() {{{

lives_ok { ARename::user_set('my_setting', 'Vaaaaalue!') } 'set_file() must live';
is( ARename::user_get('my_setting'), "Vaaaaalue!", "user_{set,get}()");

#}}}
# checking set_opt() {{{

# setting verbose {{{

lives_ok { ARename::set_opt('verbose', 1) } 'set_file() must live';
is( ARename::get_opt('verbose'), 1, "set/get verbose");

#}}}
# verbose set, do quiet breaks {{{

dies_ok  { ARename::set_opt('quiet', 1) }  "verbose is set, so setting quiet should die";

#}}}
# unsetting verbose {{{

lives_ok { ARename::set_opt('verbose', 0) } 'set_file() must live';
is( ARename::get_opt('verbose'), 0, "unset/get verbose");

#}}}
# setting quiet {{{

lives_ok { ARename::set_opt('quiet', 1) } 'set_file() must live';
is( ARename::get_opt('quiet'), 1, "set/get quiet");

#}}}
# quiet set, so verbose breaks {{{

dies_ok  { ARename::set_opt('verbose', 1) }  "quiet is set, so setting verbose should die";

#}}}
# unsetting quiet {{{

lives_ok { ARename::set_opt('quiet', 0) } 'set_file() must live';
is( ARename::get_opt('quiet'), 0, "unset/get quiet");

#}}}
# setting quiet_skip {{{
# which *must* implcitly set quiet, too

lives_ok { ARename::set_opt('quiet_skip', 1) } 'set_file() must live';
is( ARename::get_opt('quiet_skip'), 1, "set/get quiet_skip");
is( ARename::get_opt('quiet'), 1, "expecting quiet to be set after quiet_skip was set");

#}}}
# quiet set, so verbose breaks {{{

dies_ok  { ARename::set_opt('verbose', 1) }  "quiet_skip is set (implies quiet), so setting verbose should die";

#}}}

#}}}
# sect_set() must succeed {{{

lives_ok { ARename::sect_set('/my/section') } 'set_file() must live';
is( ARename::sect_get(), "/my/section", "sect_{set,get}()");

#}}}
