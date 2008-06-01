#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

BEGIN { use_ok('Readonly')            };
BEGIN { use_ok('Carp')                };
BEGIN { use_ok('English')             };
BEGIN { use_ok('Getopt::Std')         };
BEGIN { use_ok('File::Basename')      };
BEGIN { use_ok('File::Copy')          };
BEGIN { use_ok('Cwd')                 };

BEGIN { use_ok('MP3::Tag')            };
BEGIN { use_ok('Ogg::Vorbis::Header') };
BEGIN { use_ok('Audio::FLAC::Header') };

BEGIN { use_ok('ARename')             };
