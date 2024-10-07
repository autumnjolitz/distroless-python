#!/usr/bin/env sh

if [ -f "${1}c" ]; then
    if ! case "$1" in *site-packages/pip/__pip-*) false ;; *) true ;; esac ; then
        echo 'Skipping optimization of '"$1"
        exit 0
    fi
    echo 'Removing '"${1}"
    rm -f "${1}"
fi