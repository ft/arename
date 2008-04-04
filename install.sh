#!/bin/sh

SRC="$1"
DST="$2"
WIDTH="${3:-0}"

if [ -z "${SRC}" ] || [ -z "${DST}" ] ; then
    printf 'usage: install.sh <file> <dest-dir> <srcwidth>\n'
    exit 1
fi

umask 0022

if [ "${WIDTH}" -gt 0 ] ; then
    printf 'Installing %'"${WIDTH}"'s to %s\n' "${SRC}" "${DST}"
else
    printf 'Installing %'"${WIDTH}"'s to %s\n' "${SRC}" "${DST}"
fi

mkdir -p "${DST}"
chown root:root "${DST}"
cp "${SRC}" "${DST}"
chown root:root "${DST}/${SRC##*/}"
chmod 0644 "${DST}/${SRC##*/}"
