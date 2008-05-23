#!/bin/sh

NAME="arename"

if [ ! -e "${NAME}.in" ] ; then
    exit 0
fi

if [ "${NAME}.in" -nt "${NAME}.1" ] || [ ! -e "${NAME}.1" ] ; then
    printf 'POD2MAN  %s > %s\n'  "${NAME}.in" "${NAME}.1"
    pod2man  --name="${NAME}" ./"${NAME}.in" > "${NAME}.1"    2>/dev/null \
        || exit 1
fi

if [ ${NAME}.in -nt ${NAME}.html ] || [ ! -e "${NAME}.html" ]; then
    printf 'POD2HTML %s > %s\n'  "${NAME}.in" "${NAME}.html"
    pod2html                  ./"${NAME}.in" > "${NAME}.html" 2>/dev/null \
        || exit 1
    rm -f *.tmp
fi

exit 0
