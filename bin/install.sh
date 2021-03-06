#!/bin/sh

MODE="$1"
SRC="$2"
DST="$3"
WIDTH="${4:-0}"

if [ -z "${SRC}" ] || [ -z "${DST}" ] ; then
    printf 'usage: install.sh <x|n> <file> <dest-dir> <srcwidth>\n'
    exit 1
fi

umask 0022

if [ "${WIDTH}" -gt 0 ] ; then
    printf 'Installing %'"${WIDTH}"'s to %s\n' "${SRC}" "${DST}"
else
    printf 'Installing %'"${WIDTH}"'s to %s\n' "${SRC}" "${DST}"
fi

mkdir -p "${DST}"                   || exit 1
chown root:root "${DST}"            || exit 1
cp "${SRC}" "${DST}"                || exit 1
chown root:root "${DST}/${SRC##*/}" || exit 1
case "${MODE}" in
n)
    chmod 0644 "${DST}/${SRC##*/}"  || exit 1
    ;;
x)
    chmod 0755 "${DST}/${SRC##*/}"  || exit 1
    ;;
*)
    printf 'Unknown mode '\''%s'\'', ABORT.\n' "${MODE}"
    exit 1
    ;;
esac
exit 0
