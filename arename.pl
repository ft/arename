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

=item B<-H>

Do not make use of hooks of any sort (neither global nor local ones).

=item B<-q>

Make the output way more quiet, when processing files.

This option conflicts with the verbose option.

=item B<-Q>

Be even more quiet (this option will surpress, if a file is skipped.
except for files, that are skipped because they would overwrite something).

This option implies '-q'.

=item B<-s>

Read filenames from stdin after processing files given on the commandline.

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

=head2 Configuration files

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

=head3 File format

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

=head2 Hook definition files

=over 4

=item B<~/.arename.hooks>

Defines global hooks, that are in effect in every directory if the I<usehooks>
option is set to B<true>.

=item B<./.arename.hooks.local>

This allows you to define special hooks, that will only be applied for processes
that run in the directory the local file is found (and if the I<uselocalhooks>
option is set to B<true>).

For details about hooks in arename.pl, see L<HOOKS|arename> below.

=back

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

=item B<hookerrfatal>

If this is set to false, arename.pl will continue execution even if
reading, parsing or compiling a hooks file failed. (default value:
I<false>)

=item B<prefix>

Defines a prefix for destination files. This setting can still be
overwritten by the B<-p> command line option. (default value: I<.>)

=item B<quiet>

Switches on quietness by default. (default value: I<off>)

=item B<quiet_skip>

Be quiet about skips by default. This implicitly sets 'quiet'.
(default value: I<off>)

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

=item B<usehooks>

If set to true use hooks defined in B<~/.arename.hooks>.
(default value: I<true>)

=item B<uselocalhooks>

If set to true use hooks defined in B<./.arename.hooks.local>.
(default value: I<false>)

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
in L<SETTINGS|arename>).

=item B<tracktitle>

Well...

=item B<year>

Year (id3v1), TYER (id3v2) or DATE tag (.ogg/.flac).

=back

=head1 HOOKS

Before we start, a word of warning: Hooks can solve a lot of problems.
That amount of flexibility comes with its price. All data passed to
hook functions are B<references> to the B<actual data> in the script.
If you write hooks carelessly, arename.pl will get back at you!
HOOKS ARE A BIG HAMMER, THAT CAN CRUSH PROBLEMS AS WELL AS LIMBS!

I<You have been warned!>

=head2 Discussion

The reason for implementing hooks was to have a simple way of post
processing tags, filenames etc. without having to invent own magic in
the configuration files, when Perl has regular expression on steriods
anyway. Hooks can do more then pure pre and post processing, because
they are called in numerous places and give broad access to the script's
data structures. Still, post processing is probably the most useful
feature they implement.

Hooks are just Perl subroutines, which are defined in one of two files
(see L<FILES|arename>). They are run at certain events during the
execution of arename.pl. The contents of the argument list for each hook
depends on what hook is called (see the list of hook events below).

The global hooks file is read before the local one, which means, that
this local file may overwrite and extend the definitions from the global
file, as much as Perl permits. This also means, that hooks from the
local file are run I<after> the ones from the global file (unless you
are using your own method of registering hooks; but if you do so, you
know what you are doing anyway).

Subroutines must be registered to arename.pl, to be known as hooks.
Once registered, a subroutine can be removed from the known hooks,
if requested (see 'Utility subroutines' below).

The keys in various data hashes passed to the hooks can be one of
the following: I<album>, I<artist>, I<compilation>, I<genre>,
I<tracknumber>, I<tracktitle>, I<year>.

=head2 Utility subroutines

There are two subroutines, that are used to tell arename.pl about
subroutines, you defined that shall become hooks.

=over 4

=item B<register_hook>(I<event>, I<coderef>)

Registers a I<code reference> (read: your subroutine) for the given
I<event>. Example: register_hook('startup', \&custom_banner);

=item B<remove_hook>(I<event>, I<coderef>)

Removes B<all> entries of the I<code reference> for the given
I<event>. Example: remove_hook('startup', \&custom_banner);

If the coderef was added more than once, all entries are removed.

=back

=head2 List of hook events

=head3 Hooks in the main loop

These hooks are called at the highest level of the script.

=over 4

=item B<next_file_early>

Called at the start of the main loop I<before> any file checks are done.

I<Arguments>: B<0:> file name

=item B<next_file_late>

Called in the main loop I<after> the file checks are done.

I<Arguments>: B<0:> file name

=item B<file_done>

Called in the main loop I<after> the file has been processed.

I<Arguments>: B<0:> file name

=item B<filetype_unknown>

Called in the main loop I<after> the file was tried to be processed but
the file type (the extension, specifically) was unknown.

I<Arguments>: B<0:> file name

=back

=head3 Hooks in the renaming procedure

When all data has been gathered, arename.pl will go on to actually
rename the files to their new destination name (which will be generated
in the process, see L<Hooks when expanding the template> below).

=over 4

=item B<pre_apply_defaults>

This is the first action to be taken in the renaming process. It is
called even before the default values are applied.

I<Arguments>: B<0:> file name, B<1:> data hash, B<2:> file extension

=item B<pre_template>

Called I<before> template expansions have been done.

I<Arguments>: B<0:> file name, B<1:> data hash, B<2:> file extension

=item B<post_template>

Called I<after> the template has been expanded and the new file name
has been completely generated (including the destination directory
prefix).

I<Arguments>: B<0:> file name, B<1:> data hash, B<2:> file extension
B<3:> the generated new filename (including directory prefix and file
extension)

=item B<post_ensure_dir>

The destnation directory for the new file name may contain sub directories,
which currently do not exist. This hook is called I<after> it is ensured,
every directory portion exists.

I<Arguments>: B<0:> file name, B<1:> data hash, B<2:> file extension
B<3:> the generated new filename (including directory prefix and file
extension)

=item B<post_rename>

This is the final hook in the actual renaming process. The file has been
renamed at this point.

I<Arguments>: B<0:> file name, B<1:> data hash, B<2:> file extension
B<3:> the generated new filename (including directory prefix and file
extension)

=back

=head3 Hooks when expanding the template

These hooks are called when the template string is filled with the data
from tags in the audio files. All file type specific actions will have
been taken care of already. That makes these hooks probably most useful
for post processing tags, the template and file names.

=over 4

=item B<pre_expand_template>

Called before any expansions are done.

I<Arguments>: B<0:> the template string, B<1:> the data hash

=item B<expand_template_next_tag>

This hook is triggered when the next identifier in the template string
is processed. At this point it is already verified, that there is an
according tag in the data hash to fill in the identifier's space.

I<Arguments>: B<0:> the template string, B<1:> the tag's name
B<2:> the value of the length modifier in the template (zero, if
unspecified) B<3:> the data hash

=item B<expand_template_postprocess_tag>

This hooks is triggered after all internal processing of the replacement
token is done (directory seperators are replaced; tracknumbers are padded
up).

I<Arguments>: B<0:> the template string, B<1:> the text token, that will
replace the identifier in the template, B<2:> the tag's name B<3:> the
value of the length modifier, B<4:> the data hash

=item B<post_expand_template>

Called after all expansions have been done, right before the the resulting
string is returned.

I<Arguments>: B<0:> the template string, B<1:> the data hash

=back

=head3 Hooks when gathering information

These hooks are triggered while the tag information is extracted from
the audio files arename.pl is processing. Due to the differing nature
of the the involved backends, these are slightly different from file type
to file type.

Specifically, the tag for .ogg and .flac files are read one after another
(the tags in these files are pretty much the same, hence they are processed
exactly the same), whereas tags in .mp3 files are read all at the same
time.

=over 4

=item B<pre_process_flac>

I<.flac only!>

Called I<before> a flac file is processed.

I<Arguments>: B<0:> file name

=item B<post_process_flac>

I<.flac only!>

Called I<after> a flac file is processed.

I<Arguments>: B<0:> file name

=item B<pre_process_ogg>

I<.ogg only!>

Called I<before> an ogg file is processed.

I<Arguments>: B<0:> file name

=item B<post_process_ogg>

I<.ogg only!>

Called I<after> an ogg file is processed.

I<Arguments>: B<0:> file name

=item B<pre_handle_vorbistag>

I<.ogg and .flac only!>

Triggered I<before> any processing of a certain tag. It is not ensured
that the tag is even among the supported tags at this point.

I<Arguments>: B<0:> tag name, B<1:> tag value, B<2:> data hash

=item B<pre_handle_vorbistag>

I<.ogg and .flac only!>

Triggered I<after> a certain tag was processed.

I<Arguments>: B<0:> tag name, B<1:> tag value, B<2:> the internal name for
the tag (also used as the key in the data hash), B<3:> data hash

=item B<pre_process_mp3>

I<.mp3 only!>

Called I<before> an mp3 file is processed.

I<Arguments>: B<0:> file name

=item B<post_process_mp3>

I<.mp3 only!>

Called I<after> an mp3 file is processed.

I<Arguments>: B<0:> file name

=item B<pre_handle_mp3tag>

I<.mp3 only!>

Called I<before> data from the mp3 object is copied to the data hash.

I<Arguments>: B<0:> the mp3 object, B<1:> data hash

=item B<post_handle_mp3tag>

I<.mp3 only!>

Called I<after> data from the mp3 object has been copied to the data hash.

I<Arguments>: B<0:> the mp3 object, B<1:> data hash

=back

=head3 Miscellaneous hooks

=over 4

=item B<apply_defaults>

This is triggered before values from the default_* settings are applied
to missing values in the audio file. This hook is I<only> run if the
default value for a tag will be used!

I<Arguments>: B<0:> data hash, B<1:> defaults hash, B<2:> current key

=item B<pre_method>

This hook is called after a method for a file type is choosen but
I<before> the method was executed.

I<Arguments>: B<0:> file name, B<1:> method name

=item B<post_method>

Called after a method for a file type was executed.

I<Arguments>: B<0:> file name, B<1:> method name

=item B<startup>

Called directly after all the module initialisation is done, at the very
start of the script. Configuration files will have been read, as well as
hook files (obviously) and command line options will have been handled at
this point already.

This hook may be useful for postprocessing the configuration as well as
for debugging.

I<Arguments>: B<0:> program name, B<1:> its version, B<2:> configuration
hash, B<3:> hash of extensions, that point the the according method for
the file type B<4:> array of supported tags, B<5:> the program's argument
list

=item B<normal_quit>

Called at the end of the script. This is reached if nothing fatal happened.

I<Arguments>: B<0:> the program's argument list

=back

=head2 Example

This is a very simple example for a hook file, that prints a custom
banner and replaces all whitespace in the expanded template with
underscores:

  sub my_banner { oprint "Hello World.\n"; }
  sub replace_spaces_by_underscore {
      my ($templateref, $datref) = @_;
      $$templateref =~ s/\s+/_/g;
  }
  register_hook('startup', \&my_banner);
  register_hook('post_expand_template',
      \&replace_spaces_by_underscore);

Further examples can be found in the arename.hook file of the
distribution.

=head1 SEE ALSO

L<Ogg::Vorbis::Header>, L<Audio::FLAC::Header> and L<MP3::Tag>.

=head1 AUTHOR

Frank Terbeck E<lt>ft@bewatermyfriend.orgE<gt>,

Please report bugs.

=head1 LICENCE

 Copyright 2007, 2008
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

my ( $NAME, $VERSION ) = ( 'arename.pl', 'v1.1-rc2' );

# Initialisation {{{

ARename::set_nameversion($NAME, $VERSION);
ARename::set_default_options();
ARename::read_cmdline_options();
ARename::read_rcs();
ARename::set_cmdline_options($#ARGV);
ARename::read_hook_files();
ARename::set_default_methods();
ARename::startup_hook();

#}}}
# customisation and cosmetics {{{

# clear the line prefix, if we're running quietly.
sub dvr_newline {
    if (   ARename::get_opt("dryrun")
        || ARename::get_opt("readstdin")
        || ARename::get_opt("verbose")) {
        print "\n";
    }
}

if (ARename::get_opt("quiet")) {
    ARename::set_opt("oprefix", "");
}

dvr_newline();

if (ARename::get_opt("dryrun")) {
    print "+++ We are on a dry run!\n";
}

if (ARename::get_opt("verbose")) {
    print "+++ Running verbosely.\n";
}

if (ARename::get_opt("readstdin")) {
    print "+++ Reading stdin for filenames (after \@ARGV).\n";
}

dvr_newline();

# }}}

foreach my $file (@ARGV) {
    ARename::process_file($file);
}

if (ARename::get_opt("readstdin")) {
    while (<STDIN>) {
        chomp;
        ARename::process_file($_);
    }
}

ARename::run_hook('normal_quit', \@ARGV);
