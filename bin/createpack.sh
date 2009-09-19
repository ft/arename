#!/bin/sh
#
# This is a helper script, that can create tarballs from git repositories.
# It creates tarballs of the current git HEAD.
# It can also create different types of tarballs, namely uncompressed,
# gzip and bzip2 tarballs.
# usage:
#   createpack.sh version-string compression-method

POSIX_SHELL=${POSIX_SHELL:-"/bin/sh"}

export LC_ALL=C

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 ; then
  printf '%s: This is *not* a git repository. Not creating tarballs.\n' "$0"
  exit 0
fi

version="$1"
atype="$2"

if [ -z "${version}" ] || [ -z "${atype}" ] ; then
    printf 'usage: %s version-string compression-method\n' "$0"
    exit 1
fi

package="$( pwd )"
package="${package##*/}"
package="${package%.git}"

COMMON="${package}-${version}"
COMMON="$( echo ${COMMON} | sed 's,-v,-,' )"
TARNAME="${COMMON}.tar"
PREFIX="${COMMON}/"
export package version COMMON TARNAME PREFIX

git archive --format=tar --prefix="${PREFIX}" HEAD > "${TARNAME}"
if [ -e ./bin/createpack.hook.sh ] ; then
    # Adding files, that are needed in tarballs.
    ${POSIX_SHELL} ./bin/createpack.hook.sh
fi

case "${atype}" in
    bz2)
        printf '  - creating bzip2 tarball: %s\n' "${TARNAME}.bz2"
        bzip2 -f -9 "${TARNAME}"
        ;;
    gz)
        printf '  - creating gzip tarball: %s\n' "${TARNAME}.gz"
        gzip -f -9 "${TARNAME}"
        ;;
    tar)
        printf '  - creating uncompressed tarball: %s\n' "${TARNAME}"
        ;;
    *)
        printf 'unknown value in \$atype. This should not happen.\n'
        ;;
esac
