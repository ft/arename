#!/bin/sh

[ ! -e "arename.in" ] && exit 0         # probably a tarball...

PERL=${PERL:-/usr/bin/perl}

version="$(./bin/getversion.sh build)"

for scr in "${@}" ; do

    if [ ! -e "${scr}.in" ] ; then
        printf 'in-file missing! This should not happen! Please report!\n'
        exit 1
    fi

    if [ "${scr}" -nt "${scr}.in" ] && [ "${1}" -nt "${1}.in" ] ; then
        printf 'genperlscript.sh: '\''%s'\'' newer than the input files, doing nothing...\n' "${scr}"
        continue
    fi

    printf 'Generating '\''%s'\''... ' "${scr}"

    sed -e 's/@@arenameversioninfo@@/'"${version}"'/' \
        -e 's:@@perl@@:'"${PERL}"':' < "${scr}.in" > "${scr}"
    chmod +x "${scr}"

    printf 'done.\n'

done

exit 0
