#!/bin/sh

# sanity checks
if [ -z "$2" ] ; then
    printf 'usage: %s <ikiwikidir> <ikisubpagesdir>\n' "$0"
    exit 1
fi

if [ ! -d "$1" ] || [ ! -d "$2" ] ; then
    printf 'Either %s or %s does not exist. Giving up.\n' "$1" "$2"
    printf 'You are probably not Frank.\n'
    exit 1
fi

if [ ! -d .git ] ; then
    printf 'This is not a git repo, giving up.\n'
    exit 1
elif [ ! -e arename.in ] ; then
    printf 'This is not a arename repo, giving up.\n'
    exit 1
fi

#curbranch () {
#    local b=$(git symbolic-ref HEAD)
#    b=${b##refs/heads/}
#    printf '%s' "${b}"
#}
#
#if [ $(curbranch) != 'master' ] ; then
#    printf 'master is currently *not* checked out. Abort.\n'
#    exit 1
#fi
#
#################################################################################
#
#RELEASE="$(./bin/getversion.sh release)"
#PRERELEASE="$(./bin/getversion.sh prerelease)"
#SNAPSHOT="$(./bin/getversion.sh snapshot)"
#
#[ -n "${SNAPSHOT}" ] && SNAPSHOT_ver="snap-$(date +"%Y%m%d")-${SNAPSHOT}"
#
#                          printf '  Latest version: %s\n' "${RELEASE}"
#[ -n "${PRERELEASE}" ] && printf '     pre-release: %s\n' "${PRERELEASE}"
#[ -n "${SNAPSHOT}" ]   && printf 'snapshot version: %s\n' "${SNAPSHOT_ver}"
#
#################################################################################
#
#rm -f "$2"/*.tar.gz
#                          ./bin/gentarball.sh "${RELEASE}"    "${RELEASE}"      && mv ./arename-*.tar.gz "$2/"
#[ -n "${PRERELEASE}" ] && ./bin/gentarball.sh "${PRERELEASE}" "${PRERELEASE}"   && mv ./arename-*.tar.gz "$2/"
#[ -n "${SNAPSHOT}" ]   && ./bin/gentarball.sh "${SNAPSHOT}"   "${SNAPSHOT_ver}" && mv ./arename-*.tar.gz "$2/"
#
#SEDCOMMANDS='s/@@release@@/'"[arename ${RELEASE}](\/comp\/arename\/arename-${RELEASE}.tar.gz)<br \/>"'/;'
#
#if [ -n "${PRERELEASE}" ] ; then
#    SEDCOMMANDS="$SEDCOMMANDS"'s/@@prerelease@@/'"[arename ${PRERELEASE}](\/comp\/arename\/arename-${PRERELEASE}.tar.gz)<br \/>"'/;'
#else
#    SEDCOMMANDS="$SEDCOMMANDS"'/@@prerelease@@/d;'
#fi
#
#if [ -n "${SNAPSHOT}" ] ; then
#    SEDCOMMANDS="$SEDCOMMANDS"'s/@@snapshot@@/'"[arename ${SNAPSHOT_ver}](\/comp\/arename\/arename-${SNAPSHOT_ver}.tar.gz)<br \/>"'/'
#else
#    SEDCOMMANDS="$SEDCOMMANDS"'/@@snapshot@@/d'
#fi
#
SEDCOMMANDS=''
sed -e "$SEDCOMMANDS" < ./website.mdwn.in > "$1/arename.mdwn"

make doc
cp "arename.1" "arename.html" "$2"
