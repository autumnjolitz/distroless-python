#!/usr/bin/env sh

ALLOW_SITE_PACKAGES=${ALLOW_SITE_PACKAGES:-0}
quiet=0
if [ $1 = '-q' ]; then
    quiet=1
    shift
fi

if [ -f "${1}c" ]; then
    if [ "x$ALLOW_SITE_PACKAGES" = 'x0' ] && ! case "$1" in *site-packages/*) false ;; *) true ;; esac ; then
        if [ $quiet -eq 0 ]; then
            >&2 echo 'Skipping optimization of '"$1"
        fi
        exit 0
    fi
    if [ $quiet -eq 0 ]; then
        >&2 echo 'Removing '"${1}"
    fi
    rm -f "${1}"
fi