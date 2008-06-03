#!/bin/sh

[ ! -e "arename.in" ] && exit 0         # probably a tarball...

pre="$(./bin/getversion.sh prerelease)"
if [ -n "${pre}" ] ; then
    snap="$(./bin/getversion.sh snapshot)"
    [ -z "${snap}" ] && version="${pre}" || version="${pre}+git-${snap}"
fi

if [ -z "${version}" ] ; then
    rel="$(./bin/getversion.sh release)"
    snap="$(./bin/getversion.sh snapshot)"
    if [ -n "${snap}" ] ; then
        version="${rel}+git-${snap}"
    else
        version="${rel}"
    fi
fi

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

    sed -e 's/@@arenameversioninfo@@/'"${version}"'/' < "${scr}.in" > "${scr}"
    chmod +x "${scr}"

    printf 'done.\n'

done

exit 0
