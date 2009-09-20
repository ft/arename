#!/bin/sh

# Automatically create a tarballs.
#
# This can also create a tarball for the *latest* release and prerelease
# tag, if available.
#
# usage:
#   dist.sh [-n|-p] [version-identifier]
#
#       -n      create a new release; take the version-identifier argument
#               as the name for the new release's tag.
#       -r      when called without version-identifier argument, create
#               a tarball for the latest release.
#       -p      when called without version-identifier argument, create
#               a tarball for the latest prerelease.
#       -s      when called without version-identifier argument, create
#               a tarball for the current git HEAD.
#
# examples:
#   Create a new tag and tarball for release 0.4:
#       % dist.sh -n v0.4
#   Create a tarball of the latest release tag in history:
#       % dist.sh
#   Create a tarball of the latest prerelease tag in history:
#       % dist.sh -p
#   TODO: This is currently missing:
#   Create a tarball of the existing v0.3 release:
#       % dist.sh v0.3

POSIX_SHELL=${POSIX_SHELL:-"/bin/sh"}

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 ; then
  printf '%s: This is *not* a git repository. Not creating tarballs.\n' "$0"
  exit 0
fi

prerelease=0
newrelease=0
release=0
snapshot=0

while [ -n "$1" ] ; do
    case "$1" in
    -n)
        newrelease=1
        shift
        ;;
    -r)
        release=1
        shift
        ;;
    -p)
        prerelease=1
        shift
        ;;
    -s)
        snapshot=1
        shift
        ;;
    -*)
        printf 'Unknown option %s.\n' "$1"
        ;;
    --)
        shift
        break
        ;;
    *)
        break
        ;;
    esac
done

if [ -z "$1" ] ; then
    if [ "${release}" -gt 0 ] ; then
        rel_version="$(${POSIX_SHELL} ./bin/getversion.sh release)"
    fi
    if [ "${prerelease}" -gt 0 ] ; then
        pre_version="$(${POSIX_SHELL} ./bin/getversion.sh prerelease)"
    fi
    if [ "${snapshot}" -gt 0 ] ; then
        snap_version="$(${POSIX_SHELL} ./bin/getversion.sh snapshot)"
        case "${snap_version}" in
        *-dirty)
            printf 'Building tarballs of -dirty versions does not work! Abort.\n'
            exit 1
            ;;
        esac
    fi
    newrelease=0
else
    version="$1"
fi

if [ "${newrelease}" -gt 0 ] ; then
    if [ -n "${release}" ] || [ -n "${prerelease}" ] || [ -n "${snapshot}" ]; then
        printf 'Sorry, no other options allowed beside -n. Abort.\n'
        exit 1
    fi
    [ -z "${version}" ] && exit 0

    printf 'New release requested. Tagging current master head as '\''%s'\'.'\n' "${version}"
    case "${version}" in
        v*.*) ;;
        *) printf ' -!- New version tag looks suspiciously wrong; Are you sure?\n' ;;
    esac
    printf ' Proceed? (yes/no) '
    read answer
    if [ "${answer}" != 'yes' ] ; then
        printf 'Did not get a '\''yes'\'', aborting.\n'
        exit 1
    fi
    git tag -s -m "Release ${version}" "${version}"
fi

if [ "${release}" -gt 0 ] && [ -n "${rel_version}" ] ; then
    git checkout "v${rel_version}"
    ${POSIX_SHELL} ./bin/createpack.sh "${rel_version}" gz
fi
if [ "${prerelease}" -gt 0 ] && [ -n "${pre_version}" ] ; then
    git checkout "v${pre_version}"
    ${POSIX_SHELL} ./bin/createpack.sh "${pre_version}" gz
fi
if [ "${snapshot}" -gt 0 ] && [ -n "${snap_version}" ] ; then
    ${POSIX_SHELL} ./bin/createpack.sh "${snap_version}" gz
fi
if [ "${newrelease}" -gt 0 ] && [ -n "${version}" ] && [ "${version}" != 'v' ]; then
    ${POSIX_SHELL} ./bin/createpack.sh "${version}" gz
fi

exit 0
