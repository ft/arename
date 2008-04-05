#!/bin/sh

# chdir to thy data pool
mkdir -p tests/data || exit 1
cd tests/data

# create
[ ! -e input.wav ] && arecord -d3 -fcd input.wav || true

lame -m s -b 192 --noreplaygain input.wav "Foo Bar - Deaftracks - 01. Foo.mp3"
oggenc input.wav -b 256 -o "Foo Bar - Deaftracks - 01. Foo.ogg"
flac -f input.wav -o "Foo Bar - Deaftracks - 01. Foo.flac"

# multiply
for i in ogg flac mp3 ; do
    for j in "Tequilla - Compilation from Hell - 12. Ghost Busters"    \
            "Bazooka George and the Shirt - Bodyfluids - 02. Crap me!" \
            "My Hands - Bakerstreet - 19. Running all over You"        \
            "Waylon and his Banjo - Red - 01. ...neck love" ; do
        cp "Foo Bar - Deaftracks - 01. Foo"."$i" "$j.$i"
    done
done

# tag them accordingly
metaflac \
    "--no-utf8-convert" \
    "--set-tag=TRACKNUMBER=02" "--set-tag=TITLE=Crap me!" \
    "--set-tag=ARTIST=Bazooka George and the Shirt" \
    "--set-tag=ALBUM=Bodyfluids" "--set-tag=DATE=2006" \
        "Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.flac"

id3v2 \
    -2 "-t" "Crap me!" "-T" "02" "-a" "Bazooka George and the Shirt" \
    "-A" "Bodyfluids" "-y" "2006" \
        "Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.mp3"

vorbiscomment \
    "-w" "-t" "TRACKNUMBER=02" "-t" "TITLE=Crap me!" "-t" \
    "ARTIST=Bazooka George and the Shirt" "-t" "ALBUM=Bodyfluids" \
    "-t" "DATE=2006" \
        "Bazooka George and the Shirt - Bodyfluids - 02. Crap me!.ogg"

metaflac \
    "--no-utf8-convert" "--set-tag=TRACKNUMBER=01" "--set-tag=TITLE=FOO" \
    "--set-tag=ARTIST=Foo Bar" "--set-tag=ALBUM=Deaftracks" "--set-tag=DATE=1980" \
        "Foo Bar - Deaftracks - 01. Foo.flac"

id3v2 \
    -2 "-t" "FOO" "-T" "01" "-a" "Foo Bar" "-A" "Deaftracks" "-y" "1980" \
        "Foo Bar - Deaftracks - 01. Foo.mp3"

vorbiscomment \
    "-w" "-t" "TRACKNUMBER=01" "-t" "TITLE=FOO" "-t" "ARTIST=Foo Bar" \
    "-t" "ALBUM=Deaftracks" "-t" "DATE=1980" \
        "Foo Bar - Deaftracks - 01. Foo.ogg"

metaflac \
    "--no-utf8-convert" \
    "--set-tag=TRACKNUMBER=19" \
    "--set-tag=TITLE=Running all over You" "--set-tag=ARTIST=My Hands" \
    "--set-tag=ALBUM=Bakerstreet" "--set-tag=DATE=1982" \
        "My Hands - Bakerstreet - 19. Running all over You.flac"

id3v2 \
    -2 "-t" "Running all over You" "-T" "19" "-a" "My Hands" \
    "-A" "Bakerstreet" "-y" "1982" \
        "My Hands - Bakerstreet - 19. Running all over You.mp3"

vorbiscomment \
    "-w" "-t" "ARTIST=My Hands" "-t" "TRACKNUMBER=19" "-t" "TITLE=Running all over You" \
    "-t" "ALBUM=Bakerstreet" "-t" "DATE=1982" \
        "My Hands - Bakerstreet - 19. Running all over You.ogg"

metaflac \
    "--no-utf8-convert" \
    "--set-tag=ALBUMARTIST=Various Artists" "--set-tag=TRACKNUMBER=12" \
    "--set-tag=TITLE=Ghost Busters" "--set-tag=ARTIST=Tequilla" \
    "--set-tag=ALBUM=Compilation from Hell" "--set-tag=DATE=2008" \
        "Tequilla - Compilation from Hell - 12. Ghost Busters.flac"

id3v2 \
    -2 "--TPE2" "Various Artists" "-t" "Ghost Busters" "-T" "12" \
    "-a" "Tequilla" "-A" "Compilation from Hell" "-y" "2008" \
        "Tequilla - Compilation from Hell - 12. Ghost Busters.mp3"

vorbiscomment \
    "-w" "-t" "TRACKNUMBER=12" "-t" "TITLE=Ghost Busters" "-t" "ARTIST=Tequilla" \
    "-t" "ALBUMARTIST=Various Artists" "-t" "ALBUM=Compilation from Hell" "-t" "DATE=2008" \
        "Tequilla - Compilation from Hell - 12. Ghost Busters.ogg"

metaflac \
    "--no-utf8-convert" \
    "--set-tag=TRACKNUMBER=01" "--set-tag=TITLE=...neck love" \
    "--set-tag=ARTIST=Waylon and his Banjo" "--set-tag=ALBUM=Red" "--set-tag=DATE=1952" \
        "Waylon and his Banjo - Red - 01. ...neck love.flac"

id3v2 \
    -2 "-t" "...neck love" "-T" "01" "-a" "Waylon and his Banjo" "-A" "Red" "-y" "1952" \
        "Waylon and his Banjo - Red - 01. ...neck love.mp3"

vorbiscomment \
    "-w" "-t" "TRACKNUMBER=01" "-t" "TITLE=...neck love" "-t" "ARTIST=Waylon and his Banjo" \
    "-t" "ALBUM=Red" "-t" "DATE=1952" \
        "Waylon and his Banjo - Red - 01. ...neck love.ogg"
