#!/bin/sh

if [ ! -e "arename.in" ] ; then
    # probably a tarball...
    exit 0
fi

if [ "arename" -nt "arename.in" ] && [ "arename" -nt "ARename.pm" ] ; then
    printf 'genperlscript.sh: arename newer than the input files, doing nothing...\n'
    exit 0
fi

printf 'Generating arename... '
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

sed -e 's/@@arenameversioninfo@@/'"${version}"'/' < "arename.in" > "arename"
chmod +x "arename"
printf 'done.\n'
