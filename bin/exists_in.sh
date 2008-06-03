#!/bin/sh

IN="${1}.in"
ARENAME_BUILD_VERBOSE="${ARENAME_BUILD_VERBOSE:-0}"

if [ "${ARENAME_BUILD_VERBOSE}" -gt 0 ] ; then
    printf 'Checking for '\''%s'\''...\n' "${IN}"
fi

[ -e "${IN}" ] && exit 0

printf ''\''%s'\'' not found using '\''%s'\''.\n' "${IN}" "${1}"
exit 1
