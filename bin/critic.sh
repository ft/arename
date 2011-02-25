#!/bin/sh

crit=${CRITIC:-"$(which perlcritic)"}

if [ ! -x "${crit}" ] ; then
    printf ' !!! perlcritic not found - not checking.\n'
    printf ' !!! use: make test critic=/path/to/perlcritic\n\n'
    exit 0
fi

printf 'Checking source code using Perl::Critic...\n\n'

retval=0
for file in "$@" ; do
    printf 'PERLCRITIC %s\n' "${file}"
    "${crit}" --verbose "[%P]\n%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n" \
            --profile perlcriticrc "${file}" || retval=$(( $retval + 1 ))
done

if [ "${retval}" -gt 0 ] ; then
    printf '\nGot warnings.\n\n'
    exit 1
fi

printf '\nNo warnings - good.\n\n'
exit 0
