#!/bin/sh

if [ ! -e "arename.in" ] ; then
    # probably a tarball...
    exit 0
fi

if [ "arename.pl" -nt "arename.in" ] ; then
    printf 'genperlscript.sh: arename.pl newer than the input file, do nothing...\n'
    exit 0
fi

pre="$(./getversion.sh prerelease)"
if [ -n "${pre}" ] ; then
    snap="$(./getversion.sh snapshot)"
    [ -z "${snap}" ] && version="${pre}"
fi

if [ -z "${version}" ] ; then
    rel="$(./getversion.sh release)"
    snap="$(./getversion.sh snapshot)"
    if [ -n "${snap}" ] ; then
        version="${rel}+git-${snap}"
    else
        version="${rel}"
    fi
fi

sed -e 's/@@arenameversioninfo@@/'"${version}"'/' < "arename.in" > "arename.pl"
chmod +x "arename.pl"
