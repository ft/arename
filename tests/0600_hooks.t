#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

use ARename;

my $foo = 0;

sub whatisfoo { return $foo; }

sub foobar0 { $foo = 1000; }
sub foobar1 { $foo -= 340; }
sub foobar2 { $foo +=   6; }

ARename::register_hook('file_done', \&foobar0);
ARename::register_hook('file_done', \&foobar1);
ARename::register_hook('file_done', \&foobar2);
ARename::run_hook('file_done');

is(whatisfoo(), 666, "registering and running hooks should really REALLY work...");

ARename::data_reset();
# fake data
my $file = './tests/data/Foo Bar - Deaftracks - 01. Foo.ogg';
my $ext = '.ogg';
my $template = '&artist - &album - &tracktitle';
my %data = (
    artist      => "Foo Bar",
    album       => "Deaftracks",
    tracknumber => "01",
    tracktitle  => "FOO",
    year        => "1980",
);
