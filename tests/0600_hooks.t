#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

BEGIN { use_ok('ARename') };

# test the infrastructure {{{

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

#}}}
# test the sample hooks file arename.hooks {{{

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

ARename::set_file($file);
ARename::set_opt('shutup', 1);
ARename::set_opt('quiet',  1);
ARename::set_opt('hookerrfatal',  0);

is( ARename::__read_hook_file('./arename.hooks'), 1, "reading the sample hooks file shouldn't fail");

lives_ok {
    ARename::print_banner0(
        'startup', \$ARename::NAME, \$ARename::VERSION, \%ARename::conf,
        \%ARename::methods, \@ARename::supported_tags, \@main::ARGV
    )
} "print_banner0()";

lives_ok {
    ARename::print_banner1(
        'startup', \$ARename::NAME, \$ARename::VERSION, \%ARename::conf,
        \%ARename::methods, \@ARename::supported_tags, \@main::ARGV
    )
} "print_banner1()";

lives_ok {
    ARename::replace_spaces_by_underscore(
        'post_expand_template', \$template, \%data
    )
} "replace_spaces_by_underscore()";

lives_ok {
    ARename::remove_empty_subdirs(
        'file_done'
    )
} "remove_empty_subdirs()";

lives_ok {
    ARename::fix_template_albumless(
        'pre_expand_template', \$template, \%data
    )
} "fix_template_albumless()";

# }}}
