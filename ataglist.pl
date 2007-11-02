#!/usr/bin/perl
### ataglist.pl is a small program, heavily based on arename.pl.
### It takes only one argument, a filename. *.ogg, *.mp3 or *.flac.
### It outputs a number of lines, that can be easily used to create
### a hash of tag->tag_value pairs in zsh. This program's main use is
### to help implement a functionality in atag, that makes it possible
### to export tag values into zsh shell variables. Useful for scripting.
### Calling this program by hand is probably not that useful...
use warnings;
use strict;

use Getopt::Std;
use File::Basename;
use File::Copy;
use MP3::Tag;
use Ogg::Vorbis::Header;
use Audio::FLAC::Header;

my ( %conf, %defaults, %methods, %opts );
my ( $NAME, $VERSION ) = ( 'ataglist.pl', 'v0.1' );

sub list {
    my ($datref) = @_;

    foreach my $tag (sort keys %$datref) {
        if (defined $datref->{$tag} && $datref->{$tag} ne '') {
            print "$tag\n" . $datref->{$tag} . "\n";
        }
    }
}

sub process_flac { #{{{
    my ($file) = @_;
    my ($flac, %data, $tags);

    $flac = Audio::FLAC::Header->new($file);

    if (!defined $flac) {
        print "Failed to open \"$file\".\nReason: $!\n";
        return;
    }

    $tags = $flac->tags();

    foreach my $tag (keys %$tags) {
        my ($realtag, $value);
        if (!(
                $tag =~ m/^ALBUM$/i         ||
                $tag =~ m/^ARTIST$/i        ||
                $tag =~ m/^TITLE$/i         ||
                $tag =~ m/^TRACKNUMBER$/i   ||
                $tag =~ m/^DATE$/i          ||
                $tag =~ m/^GENRE$/i         ||
                $tag =~ m/^ALBUMARTIST$/i
            )) { next; }

        $value = $tags->{$tag};
        if ($tag =~ m/^ALBUM$/i) {
            $realtag = 'album';
        } elsif ($tag =~ m/^ARTIST$/i) {
            $realtag = 'artist';
        } elsif ($tag =~ m/^TITLE$/i) {
            $realtag = 'tracktitle';
        } elsif ($tag =~ m/^TRACKNUMBER$/i) {
            $realtag = 'tracknumber';
        } elsif ($tag =~ m/^DATE$/i) {
            $realtag = 'year';
        } elsif ($tag =~ m/^GENRE$/i) {
            $realtag = 'genre';
        } elsif ($tag =~ m/^ALBUMARTIST$/i) {
            $realtag = 'compilation';
        } else {
            die "This should not happen. Report this BUG. ($tag, $value)";
        }

        if (!defined $data{$realtag}) {
            $data{$realtag} = $value;
        }
    }

    list(\%data);
}
#}}}
sub process_mp3 { #{{{
    my ($file) = @_;
    my ($mp3, %data, $info);

    $mp3 = MP3::Tag->new($file);

    if (!defined $mp3) {
        print "Failed to open \"$file\".\nReason: $!\n";
        return;
    }

    $mp3->get_tags;

    if (!exists $mp3->{ID3v1} && !exists $mp3->{ID3v2}) {
        print $conf{oprefix} . "No tag found. Ignoring.\n";
        $mp3->close();
        return;
    }

    if (exists $mp3->{ID3v2}) {
        ($data{artist},      $info) = $mp3->{ID3v2}->get_frame("TPE1");
        ($data{compilation}, $info) = $mp3->{ID3v2}->get_frame("TPE2");
        ($data{album},       $info) = $mp3->{ID3v2}->get_frame("TALB");
        ($data{tracktitle},  $info) = $mp3->{ID3v2}->get_frame("TIT2");
        ($data{tracknumber}, $info) = $mp3->{ID3v2}->get_frame("TRCK");
        ($data{genre},       $info) = $mp3->{ID3v2}->get_frame("TCON");
        ($data{year},        $info) = $mp3->{ID3v2}->get_frame("TYER");
    } elsif (exists $mp3->{ID3v1}) {
        print $conf{oprefix} . "Only found ID3v1 tag.\n";
        $data{artist}      = $mp3->{ID3v1}->artist;
        $data{album}       = $mp3->{ID3v1}->album;
        $data{tracktitle}  = $mp3->{ID3v1}->title;
        $data{tracknumber} = $mp3->{ID3v1}->track;
        $data{genre}       = $mp3->{ID3v1}->genre;
        $data{year}        = $mp3->{ID3v1}->year;
    }

    $mp3->close();

    list(\%data);
}
#}}}
sub process_ogg { #{{{
    my ($file) = @_;
    my ($ogg, %data, @tags);

    $ogg = Ogg::Vorbis::Header->load($file);

    if (!defined $ogg) {
        print "Failed to open \"$file\".\nReason: $!\n";
        return;
    }

    @tags = $ogg->comment_tags;

    foreach my $tag (@tags) {
        my ($realtag, $value);
        if (!(
                $tag =~ m/^ALBUM$/i         ||
                $tag =~ m/^ARTIST$/i        ||
                $tag =~ m/^TITLE$/i         ||
                $tag =~ m/^TRACKNUMBER$/i   ||
                $tag =~ m/^DATE$/i          ||
                $tag =~ m/^GENRE$/i         ||
                $tag =~ m/^ALBUMARTIST$/i
            )) { next; }

        $value = join(' ', $ogg->comment($tag));
        if ($tag =~ m/^ALBUM$/i) {
            $realtag = 'album';
        } elsif ($tag =~ m/^ARTIST$/i) {
            $realtag = 'artist';
        } elsif ($tag =~ m/^TITLE$/i) {
            $realtag = 'tracktitle';
        } elsif ($tag =~ m/^TRACKNUMBER$/i) {
            $realtag = 'tracknumber';
        } elsif ($tag =~ m/^DATE$/i) {
            $realtag = 'year';
        } elsif ($tag =~ m/^GENRE$/i) {
            $realtag = 'genre';
        } elsif ($tag =~ m/^ALBUMARTIST$/i) {
            $realtag = 'compilation';
        } else {
            die "This should not happen. Report this BUG. ($tag, $value)";
        }

        if (!defined $data{$realtag}) {
            $data{$realtag} = $value;
        }
    }

    list(\%data);
}
#}}}

if ($#ARGV < 0) {
    die "usage: $NAME FILE\n";
}

%methods = (
    '\.flac$' => \&process_flac,
    '\.mp3$'  => \&process_mp3,
    '\.ogg$'  => \&process_ogg
);
my $file = $ARGV[0];

if (! -r $file) {
    die "Can't read \"$file\": $!\n";
}

foreach my $method (sort keys %methods) {
    if ($file =~ m!$method!i) {
        $methods{$method}->($file);
        exit 0;
    }
}

die "No method for handling \"$file\".\n";
