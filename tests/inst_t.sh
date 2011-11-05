#!/bin/sh
# Testing the installation process.

fail () {
    printf 'This may *not* happen!\n'
    printf '\n  -- Installation tests: failed.\n\n'
}

cleanup () {
    if [ -d "$1" ] ; then
        printf 'Removing %s...\n' "$1"
        rm -Rf "$1"
    fi
}

fail_install () {
    printf 'make install prefix="%s" libdir="%s" failed.\n' "${PREFIX}" "${LIBDIR}"
    fail
}

fail_uninstall () {
    printf 'make uninstall prefix="%s" libdir="%s" failed.\n' "${PREFIX}" "${LIBDIR}"
    fail
}

file_ok () {
    printf '  + %s ... ok.\n' "$1"
}

file_fail () {
    printf '  + %s ... failed.\n' "$1"
    fail
    cleanup "${ROOT}"
    exit 1
}

file_exists_and_exec () {
    local d="$1" local f="$2"

    if [ -e "$d/$f" ] ; then
        if [ ! -x "$d/$f" ] ; then
            printf '  + %s ... not executable.\n' "$d/$f"
            file_fail "$d/$f"
        fi
        file_ok "$d/$f"
    else
        file_fail "$d/$f"
    fi
}

file_exists () {
    local d="$1" local f="$2"

    if [ -e "$d/$f" ] ; then
        file_ok "$d/$f"
    else
        file_fail "$d/$f"
    fi
}

file_notexists () {
    local d="$1" local f="$2"

    if [ ! -e "$d/$f" ] ; then
        file_ok "$d/$f"
    else
        file_fail "$d/$f"
    fi
}

checkinstall () {
    local p="$1" ; local l="$2" ; local file

    local subd='bin'
    printf 'Checking %s/ installation...\n' "${subd}"
    for file in arename ataglist ; do
        file_exists_and_exec "$p/${subd}" "${file}"
    done

    local subd="$l"
    printf 'Checking %s/ installation...\n' "${subd}"
    for file in ARename.pm ; do
        file_exists "$p/${subd}" "${file}"
    done

    local subd='share/doc/arename'
    printf 'Checking %s/ installation...\n' "${subd}"
    for file in CHANGES  LICENCE  README  arename.html \
                examples/_arename ; do
        file_exists "$p/${subd}" "${file}"
    done
}

checkuninstall () {
    local p="$1" ; local l="$2" ; local file

    local subd='bin'
    printf 'Checking %s/ uninstallation...\n' "${subd}"
    for file in arename ataglist ; do
        file_notexists "$p/${subd}" "${file}"
    done

    local subd="$l"
    printf 'Checking %s/ uninstallation...\n' "${subd}"
    for file in ARename.pm ; do
        file_notexists "$p/${subd}" "${file}"
    done

    local subd='share/doc/arename'
    printf 'Checking %s/ uninstallation...\n' "${subd}"
    if [ ! -d "$p/${subd}" ] ; then
        printf '  + %s ... ok.\n' "$p/${subd}"
    else
        printf '  + %s ... failed.\n' "$p/${subd}"
        fail
        cleanup "${ROOT}"
        exit 1
    fi
}

ROOT="$(pwd)/tests/data/install"

######################################################################
######################################################################

PREFIX="${ROOT}/local"
LIBDIR="lib/site_perl"
make genperlscripts
make install install-doc prefix="${PREFIX}" # libpath="${LIBDIR}"

if [ "${?}" -ne 0 ] ; then
    fail_install "${PREFIX}" "${LIBDIR}"
    cleanup "${ROOT}"
    exit 1
fi

checkinstall "${PREFIX}" "${LIBDIR}"

make uninstall uninstall-doc prefix="${PREFIX}" # libpath="${LIBDIR}"

if [ "${?}" -ne 0 ] ; then
    fail_uninstall "${PREFIX}" "${LIBDIR}"
    cleanup "${ROOT}"
    exit 1
fi

checkuninstall "${PREFIX}" "${LIBDIR}"

printf 'First run worked out right.'
cleanup "${ROOT}"

######################################################################
######################################################################

PREFIX="${ROOT}/home with spaces"
LIBDIR="lib/perl/perl x.y.z"
make genperlscripts
make install install-doc prefix="${PREFIX}" libpath="${LIBDIR}"

if [ "${?}" -ne 0 ] ; then
    fail_install "${PREFIX}" "${LIBDIR}"
    cleanup "${ROOT}"
    exit 1
fi

checkinstall "${PREFIX}" "${LIBDIR}"

make uninstall uninstall-doc prefix="${PREFIX}" libpath="${LIBDIR}"

if [ "${?}" -ne 0 ] ; then
    fail_uninstall "${PREFIX}" "${LIBDIR}"
    cleanup "${ROOT}"
    exit 1
fi

checkuninstall "${PREFIX}" "${LIBDIR}"

printf 'Second run worked out right.\n'
cleanup "${ROOT}"

printf '\n  -- Installation tests: ok.\n\n'

######################################################################
######################################################################
