#!/usr/bin/env sh

if [ "x$CACHE_ROOT" = 'x' ] || [ "x$BUILD_ROOT" = 'x' ]; then
    >&2 echo "CACHE_ROOT (${CACHE_ROOT:-not-set}) and/or BUILD_ROOT (${BUILD_ROOT:-not-set}) is not set!"
    exit 1
fi

DEBUG="${CHROOT_APK_DEBUG:-0}"

set -e
set -o pipefail

setup () {
    local extra=''
    if [ "$DEBUG" = '1' ]; then
        extra='-v'
        >&2 echo "Grafting $CACHE_ROOT into $BUILD_ROOT..."
    fi
    tar -C "$CACHE_ROOT" -cpf - . | eval tar -C "$BUILD_ROOT" -xpf $extra -
    return $?
}

fini () {
    local rc=$?
    local extra=''
    if [ "$DEBUG" = '1' ]; then
        >&2 echo "Removing APK data from $BUILD_ROOT, storing in $CACHE_ROOT"
        extra='-v'
    fi
    local T="$(mktemp -d)"
    if [ -f $BUILD_ROOT/lib/apk/db/scripts.tar.gz ]; then
        tar -C "$T" -xzpf $BUILD_ROOT/lib/apk/db/scripts.tar.gz
        rm -f $BUILD_ROOT/lib/apk/db/scripts.tar.gz
        sed -i'' 's|^#!busybox sh|#!/usr/bin/dash|g' $(find "$T" -type f -print)
        sed -i'' 's|^#!/bin/sh|#!/usr/bin/dash|g' $(find "$T" -type f -print)
        sed -i'' 's|^#!/bin/busybox sh|#!/usr/bin/dash|g' $(find "$T" -type f -print)
        cat $(find "$T" -type f -print)
        tar -C "$T" -cpvzf $BUILD_ROOT/lib/apk/db/scripts.tar.gz  .
        rm -rf "$T"
    fi

    mkdir -p $BUILD_ROOT/var/cache/apk
    tar -C "$BUILD_ROOT" -cpf - etc/apk bin/ln bin/busybox var/cache/apk usr/share/apk | eval tar -C "$CACHE_ROOT" -xpf $extra -
    $_chroot /bin/ln -sf /usr/bin/dash /bin/sh.bak
    rm -rf $BUILD_ROOT/bin/ln $BUILD_ROOT/bin/busybox $BUILD_ROOT/etc/apk $BUILD_ROOT/var/cache/apk $BUILD_ROOT/usr/share/apk
    if $_chroot /usr/bin/dash -c '[ ! -x /bin/sh ]'; then
        >&2 echo '/bin/sh in chroot failed the vibe check, replacing with a symlink to /usr/bin/dash!'
        mv $BUILD_ROOT/bin/sh.bak $BUILD_ROOT/bin/sh
    else
        if [ "$DEBUG" = '1' ]; then
            >&2 echo '/bin/sh passed the vibe check'
        fi
        rm $BUILD_ROOT/bin/sh.bak
    fi
    exit $rc
}

trap fini EXIT
setup
apk --root "$BUILD_ROOT" $@
