#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN { use_ok('ARename') };

# checking file_eq(), which returns 1 for same files {{{
# and 0 for files, that are not the same file.

is( ARename::file_eq("./tests/0100_files.t", "./tests/0100_files.t"),  1, "file_eq() returning 1 for the same file" );
is( ARename::file_eq("./tests/0100_files.t", "./tests/0500_data.t"),   0, "file_eq() returning 0 for different files" );

#}}}
# checking ensure_dir() {{{
# ...and clean up what we created.

sub testdir {
    my ($dir) = @_;

    if (-d $dir) {
        return 1;
    }

    return 0;
}

sub xrmdir {
    my ($dir) = @_;

    rmdir($dir) or die "Couldn't remove $dir: $!\n";
}

lives_ok { ARename::ensure_dir('./tests/data/foo/bar/baz') } "creating a directory should really succeed";
is( testdir('./tests/data/foo')        , 1, "foo         is there");
is( testdir('./tests/data/foo/bar')    , 1, "foo/bar     is there");
is( testdir('./tests/data/foo/bar/baz'), 1, "foo/bar/baz is there");

xrmdir('./tests/data/foo/bar/baz');
xrmdir('./tests/data/foo/bar');
xrmdir('./tests/data/foo');

#}}}
