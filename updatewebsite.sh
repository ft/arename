#!/bin/sh

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
elif [ ! -e arename.pl ] ; then
    printf 'This is not a arename.pl repo, giving up.\n'
    exit 1
fi

EXCLUDE='.gitignore TODO updatewebsite.sh website.mdwn.in'

LATEST="$(git tag | grep -v -- '-' | tail -n 1)"
PREREL="$(git tag | tail -n 1)"
SNSHOT="$(git-rev-list --abbrev=12 --abbrev-commit --max-count=1 HEAD)"

LATSHA=$(git-rev-list --abbrev=12 --abbrev-commit --max-count=1 $LATEST)
PRESHA=$(git-rev-list --abbrev=12 --abbrev-commit --max-count=1 $PREREL)

    [ "$LATSHA" = "$PRESHA" ] && PREREL=''

if [ -n "$PREREL" ] ; then

    [ "$PRESHA" = "$SNSHOT" ] && SNSHOT=''

else

    [ "$LATSHA" = "$SNSHOT" ] && SNSHOT=''

fi

case "$PREREL" in
    "$LATEST"-*) PREREL='' ;;
esac

[ -n "$SNSHOT" ] && SNSVER="snap-$(date +"%Y%m%d")-$SNSHOT"

                    printf '  Latest version: %s\n' "$LATEST"
[ -n "$PREREL" ] && printf '     pre-release: %s\n' "$PREREL"
[ -n "$SNSHOT" ] && printf 'snapshot version: %s\n' "$SNSVER"

################################################################################

createtargz() {
    tag=$1 ; shift
    ver=$1 ; shift

    if git branch | grep '^.*createtargz$' >/dev/null 2>&1 ; then
        git branch -D createtargz
    fi

    printf 'Creating tarball for %s (%s).\n' "$tag" "$ver"
    git checkout -b createtargz "$tag"
    for file in $EXCLUDE ; do
        rm -f "${file}" ; echo "deleting $file"
    done
    make doc
    git add .
    git commit -a -m 'createtargz'
    git-archive --format=tar --prefix="arename-${ver}/" "createtargz" | gzip -c -  > "../arename-${ver}.tar.gz"
    git checkout master
    git branch -D createtargz
}

################################################################################

                    createtargz "$LATEST" "$LATEST"
[ -n "$PREREL" ] && createtargz "$PREREL" "$PREREL"
[ -n "$SNSHOT" ] && createtargz "$SNSHOT" "$SNSVER"

SEDCOMMANDS='s/@@release@@/'"[arename $LATEST](\/comp\/arename\/arename-$LATEST.tar.gz)<br \/>"'/;'

if [ -n "$PREREL" ] ; then
    SEDCOMMANDS="$SEDCOMMANDS"'s/@@prerelease@@/'"[arename $PREREL](\/comp\/arename\/arename-$PREREL.tar.gz)<br \/>"'/;'
else
    SEDCOMMANDS="$SEDCOMMANDS"'/@@prerelease@@/d;'
fi

if [ -n "$SNSHOT" ] ; then
    SEDCOMMANDS="$SEDCOMMANDS"'s/@@snapshot@@/'"[arename $SNSVER](\/comp\/arename\/arename-$SNSVER.tar.gz)<br \/>"'/'
else
    SEDCOMMANDS="$SEDCOMMANDS"'/@@snapshot@@/d'
fi

sed -e "$SEDCOMMANDS" < ./website.mdwn.in > "$1/arename.mdwn"

rm -f "$2"/*.tar.gz
mv ../arename-*.tar.gz "$2/"
make doc
cp "arename.1" "arename.html" "$2"
