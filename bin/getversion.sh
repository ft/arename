#!/bin/sh

# Get version information from git tree.
# If called in a non-git tree (read: from an unpacked tarball), the
# contents of VERSION is used.
#
#   usage:
#       getversion.sh <keyword> [sha]
#           keywords:
#               release
#                   describe the version of the latest release.
#                   Marked by tags of this form: vX.Y[.Z]
#               prerelease
#                   describe the version of the latest prerelease.
#                   Marked by tags of this form: vX.Y[.Z]-rc[C]
#               snapshot
#                   describe the version of the current HEAD commit.
#               build
#                   describe the version of the currently checked out
#                   commit; used as the version in the cmc binary.
#
#           If the second parameter to the script is the string 'sha',
#           getversion.sh will display the sha1 checksum of the commit
#           in question rather than a human readable name.

POSIX_SHELL=${POSIX_SHELL:-"/bin/sh"}

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 ; then
    if [ -e ./VERSION ] ; then
        cat ./VERSION
        exit 0
    else
        printf 'VERSION is missing. Broken tarball?\n'
        exit 1
    fi
fi

if [ -z "$1" ] ; then
    printf 'usage: getversion.sh <keyword> [sha].\n'
    exit 1
fi

rm -f ./VERSION
keyword="$1"
shamod="$2"

set_r_sym () {
    r_sym="$(git tag | grep -- '^v' | grep -v -- '-' | tail -n 1)"
}

set_p_sym () {
    p_sym="$(git tag | grep -- '^v' | tail -n 1)"
    case "${p_sym}" in
        *-rc*) ;;
        *) p_sym='' ;;
    esac
}

shaprint () {
    [ -z "$1" ] && return 1
    git rev-list --abbrev=12 --abbrev-commit --max-count=1 "$1"
}

xprint () {
    if [ "${shamod}" = "sha" ] ; then
        shaprint "$1"
    else
        printf '%s\n' "${1#v}"
    fi
}

fully_beautified_version () {
    if [ -z "$1" ] ; then
        version=$(git describe --abbrev=0  2>/dev/null)
        fullver=$(git describe --abbrev=12 2>/dev/null)
    else
        version=$(git describe "$1" --abbrev=0  2>/dev/null)
        fullver=$(git describe "$1" --abbrev=12 2>/dev/null)
    fi
    suffix=
    dirty=
    [ "$version" != "$fullver" ] && version="${fullver}"
    git update-index -q --refresh
    [ -z "$(git diff-index --name-only HEAD --)" ] || dirty="-dirty"
    [ -z "${version}" ] && version="0.0.unversioned" && suffix='-g'$(shaprint HEAD)
    version=${version#v}
    printf '%s%s%s\n' "$version" "$suffix" "$dirty"
}

case "${keyword}" in
release)
    set_r_sym
    [ -n "${r_sym}" ] && xprint "${r_sym}"
    ;;

prerelease)
    set_r_sym
    set_p_sym

    case "$p_sym" in
    "$r_sym"-*)
        exit 0
        ;;
    *)
        [ -n "${p_sym}" ] && xprint "${p_sym}"
        ;;
    esac
    ;;

snapshot)
    if [ "${shamod}" = "sha" ] ; then
        xprint HEAD
        exit 0
    fi
    set_r_sym
    s_sha="$(shaprint HEAD)"
    r_sha="$(shaprint "${r_sym}")"
    [ "${s_sha}" = "${r_sha}" ] && exit 0

    set_p_sym
    p_sha="$(shaprint "${p_sym}")"
    [ "${s_sha}" = "${p_sha}" ] && exit 0

    fully_beautified_version "${s_sha}"
    ;;

build)
    fully_beautified_version
    ;;
*)
    printf 'Unknown version keyword: '\''%s'\'', ABORT.\n' "${keyword}"
    exit 1
    ;;
esac

exit 0
