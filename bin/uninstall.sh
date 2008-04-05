#!/bin/sh

if [ -z "$2" ] || [ -n "$3" ]; then
    printf 'usage: uninstall.sh <d|f> <target>\n'
    exit 1
fi

WIDTH=6

wprint () {
    # args: 1->type, 2->target
    printf 'Removing %'"${WIDTH}"'s: %s\n' "$1" "$2"
}

die () {
    # args: 1->type, 2->target
    printf 'Error uninstalling '\''%s'\''.\n' "$2"
    printf '  Possible reasons:\n'
    printf '    + Need to become root?\n'
    printf '    + %s %s was never installed?\n' "$1" "$2"
    printf '        - wrong $prefix or $libpath?\n'
    printf '        - '\''make install'\'' never ran properly?\n'
    exit 1
}

rmfile () {
    # args: 1->filename
    wprint 'file' "$1"

    if ! rm "$1" ; then
        die 'file' "$1"
    fi
}

rmsubdir () {
    # args: 1->dirname
    wprint 'subdir' "$1"

    if ! rm -R "$1" ; then
        die 'subdir' "$1"
    fi
}

case "$1" in
d)
    rmsubdir "$2"
    ;;
f)
    rmfile "$2"
    ;;
*)
    printf 'Unknown mode: '\''%s'\'', ABORT.\n' "$1"
    exit 1
    ;;
esac
exit 0
