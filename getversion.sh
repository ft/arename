#!/bin/sh

if [ -z "$1" ] ; then
    printf 'usage: getversion.sh <keyword> [sha].\n'
    exit 1
fi

keyword="$1"
shamod="$2"

set_r_sym () {
    r_sym="$(git tag | grep -- '^v' | grep -v -- '-' | tail -n 1)"
}

set_p_sym () {
    p_sym="$(git tag | grep -- '^v' | tail -n 1)"
}

shaprint () {
    git-rev-list --abbrev=12 --abbrev-commit --max-count=1 "$1"
}

xprint () {
    if [ "${shamod}" = "sha" ] ; then
        shaprint "$1"
    else
        printf '%s\n' "$1"
    fi
}

case "${keyword}" in
release)
    set_r_sym
    xprint "${r_sym}"
    ;;

prerelease)
    set_r_sym
    set_p_sym

    case "$p_sym" in
    "$r_sym"-*)
        exit 0
        ;;
    *)
        xprint "${p_sym}"
        ;;
    esac
    ;;

snapshot)
    set_r_sym
    s_sha="$(shaprint HEAD)"
    r_sha="$(shaprint "${r_sym}")"
    [ "${s_sha}" = "${r_sha}" ] && exit 0

    set_p_sym
    p_sha="$(shaprint "${p_sym}")"
    [ "${s_sha}" = "${p_sha}" ] && exit 0

    printf '%s\n' "${s_sha}"
    ;;

*)
    printf 'Unknown version keyword: '\''%s'\'', ABORT.\n' "${keyword}"
    exit 1
    ;;
esac

exit 0
