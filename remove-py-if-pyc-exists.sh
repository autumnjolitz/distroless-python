#!/usr/bin/env sh

ALLOW_SITE_PACKAGES=${ALLOW_SITE_PACKAGES:-0}

if [ -f "${1}c" ]; then
    if [ "x$ALLOW_SITE_PACKAGES" = 'x0' ] && ! case "$1" in *site-packages/*) false ;; *) true ;; esac ; then
        echo 'Skipping optimization of '"$1"
        exit 0
    fi
    echo 'Removing '"${1}"
    rm -f "${1}"
fi