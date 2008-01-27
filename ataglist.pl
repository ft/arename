#!/usr/bin/perl
### ataglist.pl takes only one argument, a filename. *.ogg, *.mp3
### or *.flac. It outputs a number of lines, that can be easily used
### to create a hash of tag->tag_value pairs in zsh. This program's
### main use is to help implement a functionality in atag, that makes
### it possible to export tag values into zsh shell variables.
### Useful for scripting.
### Calling this program by hand is probably not that useful...

use warnings;
use strict;
use ARename;

my ( $NAME, $VERSION ) = ( 'ataglist.pl', 'v0.2' );

sub list {
    my ($file, $datref, $ext) = @_;

    foreach my $tag (sort keys %$datref) {
        if (defined $datref->{$tag} && $datref->{$tag} ne '') {
            print "$tag\n" . $datref->{$tag} . "\n";
        }
    }
}

if ($#ARGV < 0) {
    warn "$NAME $VERSION\n";
    die  "  usage: $NAME FILE\n";
}

my $file = $ARGV[0];

if (! -r $file) {
    die "Can't read \"$file\": $!\n";
}

ARename::set_nameversion($NAME, $VERSION);
ARename::set_postproc(\&main::list);
ARename::set_default_methods();
ARename::apply_methods($file, 1);

die "No method for handling \"$file\".\n";
