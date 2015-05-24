#!/bin/sh

NAME="$1"

if [ ! -e "${NAME}" ] ; then
    exit 0
fi

if [ "${NAME}" -nt "${NAME}.1" ] || [ ! -e "${NAME}.1" ] ; then
    printf 'POD2MAN  %s > %s\n'  "${NAME}"   "${NAME}.1"
    pod2man  --name="${NAME}"  ./"${NAME}" > "${NAME}.1" \
        || exit 1
fi

if [ ${NAME} -nt ${NAME}.html ] || [ ! -e "${NAME}.html" ]; then
    printf 'POD2HTML %s > %s\n'  "${NAME}"   "${NAME}.html"
    pod2html                   ./"${NAME}" > "${NAME}.html" \
        || exit 1
    rm -f *.tmp
fi

exit 0
