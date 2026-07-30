#!/usr/bin/env sh

set -eu
set -o pipefail

: CACHE_ROOT="${CACHE_ROOT:?CACHE_ROOT is not set!}" \
  BUILD_ROOT="${BUILD_ROOT:?BUILD_ROOT is not set!}"

DEBUG="${CHROOT_APK_DEBUG:-0}"


setup () {
    local extra=
    if [ "$DEBUG" = '1' ]; then
        extra='-v'
        >&2 echo "Grafting $CACHE_ROOT into $BUILD_ROOT..."
    fi
    rm -f "$BUILD_ROOT"/bin/busybox
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
    mkdir -p $BUILD_ROOT/var/cache/apk
    tar \
        -C "$BUILD_ROOT" \
        -cpf - \
            etc/apk \
            bin/ln \
            bin/busybox \
            var/cache/apk \
            usr/share/apk \
            lib/apk \
    | eval tar -C "$CACHE_ROOT" -xpf $extra -

    $_chroot /bin/ln -sf /usr/bin/dash /bin/sh.bak
    rm -rf \
        "$BUILD_ROOT"/bin/ln \
        "$BUILD_ROOT"/bin/busybox \
        "$BUILD_ROOT"/etc/apk \
        "$BUILD_ROOT"/var/cache/apk \
        "$BUILD_ROOT"/usr/share/apk
    >"$BUILD_ROOT"/bin/busybox cat <<'EOF'
#!/usr/bin/env dash
case "${1:-}" in
    sh)
    shift
    exec /usr/bin/env dash $@
    ;;
    *)
    exec /usr/bin/env $@
    ;;
esac
EOF
    chmod +x "$BUILD_ROOT"/bin/busybox

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
