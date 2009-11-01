#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;

BEGIN { use_ok('Readonly')            };
BEGIN { use_ok('Carp')                };
BEGIN { use_ok('English')             };
BEGIN { use_ok('Getopt::Std')         };
BEGIN { use_ok('File::Basename')      };
BEGIN { use_ok('File::Copy')          };
BEGIN { use_ok('Cwd')                 };

BEGIN { use_ok('Audio::Scan')         };

BEGIN { use_ok('ARename')             };

is( defined &Audio::Scan::is_supported, !0, "Audio::Scan has is_supported()" );
is( defined &Audio::Scan::extensions_for, !0, "Audio::Scan has extensions_for()" );
is( defined &Audio::Scan::type_for, !0, "Audio::Scan has type_for()" );
is( defined &Audio::Scan::get_types, !0, "Audio::Scan has get_types()" );
is( Audio::Scan->is_supported("foo.mp3"), 1, "Audio::Scan->is_supported() works" );
