#!/usr/bin/env sh

if [ "x$CACHE_ROOT" = 'x' ] || [ "x$BUILD_ROOT" = 'x' ]; then
    >&2 echo "CACHE_ROOT (${CACHE_ROOT:-not-set}) and/or BUILD_ROOT (${BUILD_ROOT:-not-set}) is not set!"
    exit 1
fi

set -e
set -o pipefail

setup () {
    >&2 echo "Grafting $CACHE_ROOT into $BUILD_ROOT..."
    tar -C "$CACHE_ROOT" -cpf - . | tar -C "$BUILD_ROOT" -xpf -
    return $?
}

fini () {
    >&2 echo "Removing APK data from $BUILD_ROOT, storing in $CACHE_ROOT"
    tar -C "$BUILD_ROOT" -cpf - etc/apk bin/ln bin/busybox var/cache/apk usr/share/apk | tar -C "$CACHE_ROOT" -xpf -
    rm -rf $BUILD_ROOT/bin/ln $BUILD_ROOT/bin/busybox $BUILD_ROOT/etc/apk $BUILD_ROOT/var/cache/apk $BUILD_ROOT/usr/share/apk
    return $?
}

trap fini EXIT
setup
set -x
apk --root "$BUILD_ROOT" $@