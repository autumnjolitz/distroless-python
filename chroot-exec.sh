#!/usr/bin/env sh

if [ "x$CACHE_ROOT" = 'x' ] || [ "x$BUILD_ROOT" = 'x' ]; then
    >&2 echo "CACHE_ROOT (${CACHE_ROOT:-not-set}) and/or BUILD_ROOT (${BUILD_ROOT:-not-set}) is not set!"
    exit 1
fi

DEBUG="${CHROOT_EXEC_DEBUG:-0}"

set -e
set -o pipefail

setup () {
    local extra=
    if [ "$DEBUG" = '1' ]; then
        >&2 echo "Grafting $CACHE_ROOT into $BUILD_ROOT..."
        extra='-v'
    fi
    tar -C "$CACHE_ROOT" -cpf - . | eval tar -C "$BUILD_ROOT" $extra -xpf -
    return $?
}

fini () {
    local rc=$?
    local extra=
    if [ "$DEBUG" = '1' ]; then
        >&2 echo "Removing APK data from $BUILD_ROOT, storing in $CACHE_ROOT"
        extra=-v
    fi
    mkdir -p $BUILD_ROOT/var/cache/apk
    tar -C "$BUILD_ROOT" -cpf - etc/apk bin/ln bin/busybox var/cache/apk usr/share/apk | eval tar -C "$CACHE_ROOT" $extra -xpf -
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

while [ "x$1" = x/usr/bin/env -o "x$1" = xenv ]; do
    shift
done

if [ "x$@" = x -o x"$@" = 'x-h' -o x"$@" = 'x--help' -o x"$@" = 'x-?' ]; then
    >&2 echo 'chroot-exec [NAME=VALUE]... [COMMAND [ARG]...]

let NAME=VALUE denote environment variables

All file accesses in this command are relative to the '"$BUILD_ROOT"'
'
    exit 1
fi

setup

chroot $BUILD_ROOT /usr/bin/env $@
