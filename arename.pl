#!/usr/bin/perl
use warnings;
use strict;
use ARename;

# documentation {{{
=pod

=head1 NAME

arename.pl - automatically rename audio files by tagging information

=head1 SYNOPSIS

arename.pl [OPTION(s)] FILE(s)...

=head1 OPTIONS AND ARGUMENTS

=over 8

=item B<-d>

Go into dryrun mode.

=item B<-f>

Overwrite files if needed.

=item B<-h>

Display a short help text.

=item B<-q>

Make the output way more quiet, when processing files.

This option conflicts with the verbose option.

=item B<-Q>

Be even more quiet (this option will surpress, if a file is skipped.
except for files, that are skipped because they would overwrite something).

This option does not work, if 'quiet' isn't set.

=item B<-V>

Display version infomation.

=item B<-v>

Enable verbose output.

=item B<-p> E<lt>prefixE<gt>

Define a prefix for destination files.

=item B<-T> E<lt>templateE<gt>

Define a compilation template.

=item B<-t> E<lt>templateE<gt>

Define a generic template.

=item I<FILE(s)...>

Input files, that are subject for renaming.

=back

=head1 DESCRIPTION

B<arename.pl> is a tool that is able to rename audio files by looking at
a file's tagging information, from which it will assemble a consistent
destination file name. The format of that filename is configurable for the
user by the use of template strings.

B<arename.pl> currently supports three widely used audio formats, namely
MPEG Layer3, ogg vorbis and flac. The format, that B<arename.pl> will
assume for each input file is determined by the file's filename-extension
(I<.mp3> vs. I<.ogg> vs. I<.flac>). The extension check is case-insensitive.

By default, B<arename.pl> will refuse to overwrite destination files,
if the file in question already exists. You can force overwriting by
supplying the B<-f> option.

=head1 FILES

B<arename.pl> uses up to two configuration files. As for most programs,
the script will try to read a configuration file, that is located in the
user's I<home directory>. In addition to that, it will try to load I<local>
configuration files, if it finds appropriately named files in the
I<current directory>.

=over 8

=item B<~/.arenamerc>

per-user global configuration file.

=item B<./.arename.local>

per-directory local configuration file.

=back

=head2 File format

The format of the aforementioned files is pretty simple.
It is parsed line by line. Empty lines, lines only containing whitespace
and lines, whose first non whitespace character is a hash character (I<#>)
are ignored.

Each line consists of one or two parts. If there are two parts,
they are separated by whitespace. The first part of the line will be used
as the identifier of a setting (eg. I<verbose>). The second part (read: the
rest of the line) is used as the value of the setting. (No quoting, or whatsoever
is required.)

If the value part start with a backslash, that backslash is left out of the
value. That makes it possible to define templates with leading whitespace.

If a line consists of only one part, that means the setting is switched on.

=head2 Configuration file example

  # switch on verbosity
  verbose

  # the author is crazy! use a sane template by default. :-)
  template &artist - &album (&year) - &tracknumber. &tracktitle

=head1 SETTINGS

The following settings are supported in all configuration files:

=over 8

=item B<comp_template>

Defines a template to use with files that provide a compilation tag
(for 'various artist' CDs, for example). This setting can still be
overwritten by the B<-T> command line option. (default value:
I<va/&album/&tracknumber - &artist - &tracktitle>)

=item B<default_*>

default_artist, default_album, default_compilation, default_genre, 
default_tracknumber, default_tracktitle, default_year

Defines a default value, for the given tag in files, that lack this
information. (default value: I<undefined>)

=item B<prefix>

Defines a prefix for destination files. This setting can still be
overwritten by the B<-p> command line option. (default value: I<.>)

=item B<quiet>

Switches on quietness by default. (default value: I<off>)

=item B<quiet_skip>

Be quiet about skips by default. (default value: I<off>)

=item B<sepreplace>

Tagging information strings may contain slashes, which is a pretty bad
idea on most filesystems. Therefore, you can define a string, that replaces
slashes with the value of this setting. (default value: I<_>)

=item B<template>

Defines a template to use with files that do not provide a compilation tag
(or where the compilation tag and the artist tag are exactly the same).
This setting can still be overwritten by the B<-T> command line option.
(default value: I<&artist[1]/&artist/&album/&tracknumber - &tracktitle>)

=item B<tnpad>

This defines the width, to which the tracknumber field is padded with zeros
on the left. (default value: I<2>)

=item B<verbose>

Switches on verbosity by default. (default value: I<off>)

=back

=head1 TEMPLATE FORMAT

B<arename.pl>'s templates are quite simple, yet powerful.

At simplest, a template is just a fixed character string. However, that would
not be exactly useful. So, the script is able to expand certain expressions
with information gathered from the file's tagging information.

The expressions can have two slightly different forms:

=over 8

=item B<&>I<identifier>

The simple form.

=item B<&>I<identifier>B<[>I<length>B<]>

The "complex" form. The I<length> argument in square brackets defines the
maximum length, to which the expression should be expanded.

That means, if the Artist of a file reveals to be 'I<Frank Zappa>', then
using 'B<&artist[1]>' will expand to 'I<F>'.

=back

=head2 Available expression identifiers

The data, that is expanded is derived from tagging information in
the audio files. For I<.ogg> and I<.flac> files, the tag checking
B<arename.pl> does is case insensitive and the first matching tag
will be used.

=over 8

=item B<album>

Guess.

=item B<artist>

Guess again.

=item B<compilation>

For I<.ogg> and I<.flac> this is filled with information found in the
'albumartist' tag. For I<.mp3> this is filled with information from the
id3v2 TPE2 frame. If the mp3 file only provides a id3v1 tag, this is not
supported.

=item B<genre>

The genre or content type of the audio file.

=item B<tracknumber>

The number of the position of the track on the disc. Obviously. However, this
can be in the form of '12' or '12/23'. In the second form, only the part left
of the slash is used. The tracknumber is a little special, as you can define
to what width it should be padded with zeros on the left (see I<tnpad> setting
in L<arename(1)/SETTINGS>).

=item B<tracktitle>

Well...

=item B<year>

Year (id3v1), TYER (id3v2) or DATE tag (.ogg/.flac).

=back

=head1 SEE ALSO

L<Ogg::Vorbis::Header(3)>, L<Audio::FLAC::Header(3)> and L<MP3::Tag(3)>.

=head1 AUTHOR

Frank Terbeck E<lt>ft@bewatermyfriend.orgE<gt>,

Please report bugs.

=head1 LICENSE

 Copyright 2007
 Frank Terbeck <ft@bewatermyfriend.org>, All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

   1. Redistributions of source code must retain the above
      copyright notice, this list of conditions and the following
      disclaimer.
   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials
      provided with the distribution.

  THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS OF THE
  PROJECT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
#}}}

my ( $NAME, $VERSION ) = ( 'arename.pl', 'v0.9' );

ARename::set_default_options();
ARename::read_cmdline_options();
ARename::read_rcs();
ARename::set_cmdline_options($#ARGV);
ARename::set_default_methods();

# clear the line prefix, if we're running quietly.
if (ARename::get_opt("quiet")) {
    ARename::set_opt("oprefix", "");
}

if (ARename::get_opt("dryrun")) {
    print "+++ We are on a dry run!\n";
}

if (ARename::get_opt("verbose")) {
    print "+++ Running verbosely.\n";
}

if (ARename::get_opt("dryrun") || ARename::get_opt("verbose")) {
    print "\n";
}

foreach my $file (@ARGV) {
    my $done = 0;
    if (!ARename::get_opt("quiet")) {
        print "Processing: $file\n";
    }
    if (-l $file) {
        warn ARename::get_opt("oprefix") . "Refusing to handle symbolic links ($file).\n";
        next;
    }
    if (! -r $file) {
        warn ARename::get_opt("oprefix") . "Can't read \"$file\": $!\n";
        next;
    }

    if (!ARename::apply_methods($file, 0)) {
        ARename::process_warn($file);
    }
}
