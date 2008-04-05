#!/bin/sh

if [ -z "$2" ] ; then
    printf 'usage: gentarball.sh <tag> <versionstring>\n'
    printf '  where tag *must* exist and versionstring can be whatever you want.\n'
    exit 1
fi

tag=$1 ; shift
ver=$1 ; shift

EXCLUDE='.gitignore TODO updatewebsite.sh website.mdwn.in'

if git branch | grep '^.*createtargz$' >/dev/null 2>&1 ; then
    git branch -D createtargz
fi

printf '\n  ----- Creating tarball for %s (%s) -----\n\n' "$tag" "$ver"

make distclean
if ! git checkout -b createtargz "${tag}" ; then
    printf 'git checkout -n createtargz "%s" failed. Check manually!\n' "${tag}"
    exit 1
fi

for file in ${EXCLUDE} ; do
    rm -f "${file}"
    printf 'deleting %s\n' "${file}"
done

make doc

git add .
git commit -a -m 'createtargz'

git-archive --format=tar --prefix="arename-${ver}/" "createtargz" | gzip -c -  > "./arename-${ver}.tar.gz"

git checkout master
git branch -D createtargz
