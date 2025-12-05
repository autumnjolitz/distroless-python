#!/usr/bin/env sh

if [ "x$CACHE_ROOT" = 'x' ] || [ "x$BUILD_ROOT" = 'x' ]; then
    >&2 echo "CACHE_ROOT (${CACHE_ROOT:-not-set}) and/or BUILD_ROOT (${BUILD_ROOT:-not-set}) is not set!"
    exit 1
fi

DEBUG="${CHROOT_PIP_DEBUG:-0}"

set -e
set -o pipefail

if [ "$1" = '-O' ] || [ "$1" = '--optimize' ]; then
    PIP_OPTIMIZE='1'
    shift
fi

export PIP_OPTIMIZE="${PIP_OPTIMIZE:-0}"

setup () {
    return 0
}

fini () {
    local rc=$?
    local extra=-q
    if [ "$DEBUG" = 1 ]; then
        extra=
    fi
    set -x

    if [ $PIP_OPTIMIZE = '1' ]; then
        python -m pip freeze >"$AFTER_PACKAGES"
        new_packages="$(diff -Naur "$BEFORE_PACKAGES" "$AFTER_PACKAGES" | grep -vE '^\+\+' | grep -E '^\+' | cut -f2 -d+ | cut -f1 -d= | xargs)"
        if [ "x$new_packages" != 'x' ]; then
            if [ "$DEBUG" = '1' ]; then
                >&2 echo "Optimizing packages (${new_packages})..."
            fi
            for package in $new_packages
            do
                package_location=$(python -m pip show -f "$package" | grep -E '^Location' | cut -f2 -d: | xargs)
                for dir in $(python -m pip show -f "$package" | awk 'f;/Files:/{f=1}' | cut -f1 -d/ | sort | uniq | xargs)
                do
                    eval python -m compileall \
                        $extra \
                        -b "$package_location/$dir"
                done
            done
        else
            if [ "$DEBUG" = '1' ]; then
                >&2 echo 'No new packages installed or changed to optimize with.'
            fi
        fi
        rm -f "$BEFORE_PACKAGES" "$AFTER_PACKAGES"
    fi
    export ALLOW_SITE_PACKAGES=1
    find $BUILD_ROOT/usr/local/lib/python$PYTHON_VERSION/site-packages \
        -type f -name '*.py' -exec sh -c "remove-py-if-pyc-exists $extra {}" \; ;
    return 0
}

trap fini EXIT
setup
export PYTHONPATH="${BUILD_ROOT}/usr/local/lib/python${PYTHON_VERSION}/site-packages"
export PIP_PREFIX="${BUILD_ROOT}/usr/local"
if [ $PIP_OPTIMIZE = '1' ]; then
    BEFORE_PACKAGES=$(mktemp)
    AFTER_PACKAGES=$(mktemp)
    python -m pip freeze >"$BEFORE_PACKAGES"
fi
python -m pip $@
