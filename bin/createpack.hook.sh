#!/bin/sh
# Script called by createpack.sh to include additional files in tarballs.
POSIX_SHELL=${POSIX_SHELL:-"/bin/sh"}

export LC_ALL=C
umask 022

MAKE="${MAKE:-make}"

mkdir -p "${COMMON}"

printf 'Generating VERSION...\n'
printf '%s\n' "${version#v}" > "${COMMON}"/VERSION

printf 'Generating Perl scripts...\n'
${MAKE} genperlscripts
printf 'Generating manuals...\n'
${MAKE} doc
printf 'Including prebuild Perl scripts...\n'
cp ARename.pm ataglist arename "${COMMON}"
printf 'Including prebuild manuals...\n'
cp *.1 *.html "${COMMON}"

printf 'Tweaking permissions for additional files...\n'
find "${COMMON}" -type f -exec chmod 0664 '{}' ';'

tar rf "${TARNAME}" "${COMMON}"
rm -r "${COMMON}"
