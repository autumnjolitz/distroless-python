#!/usr/bin/env sh

if [ "x$CACHE_ROOT" = 'x' ] || [ "x$BUILD_ROOT" = 'x' ]; then
    >&2 echo "CACHE_ROOT (${CACHE_ROOT:-not-set}) and/or BUILD_ROOT (${BUILD_ROOT:-not-set}) is not set!"
    exit 1
fi

DEBUG="${CHROOT_PIP_DEBUG:-0}"

if [ "x${SOURCE_DATE_EPOCH:-}" = x ]; then
    SOURCE_DATE_EPOCH=0
elif [ "x${SOURCE_DATE_EPOCH:-}" = x- ]; then
    # ARJ: if the SOURCE_DATE_EPOCH is '-' then it
    # will have the effect of clearing the default SOURCE_DATE_EPOCH
    SOURCE_DATE_EPOCH=
fi

set -e
set -o pipefail

if [ "x${1:-}" = 'x-O' ] || [ "x${1:-}" = 'x--optimize' ]; then
    PIP_OPTIMIZE='1'
    shift
fi

export PIP_OPTIMIZE="${PIP_OPTIMIZE:-0}"

setup () {
    return 0
}

fini () {
    local rv=
    local rc=$?
    local extra=-q
    local new_packages=
    if [ "x${DEBUG:-}" = x1 ]; then
        extra=
    fi

    if [ x${PIP_OPTIMIZE:-} = 'x1' ]; then
        python -m pip freeze >"$AFTER_PACKAGES"
        rv=0
        new_packages="$(diff -Naur "$BEFORE_PACKAGES" "$AFTER_PACKAGES" | grep -vE '^\+\+' | grep -E '^\+' | cut -f2 -d+ | cut -f1 -d= | xargs)" || rv=$?
        if [ "x$new_packages" != 'x' ]; then
            if [ "x${DEBUG:-}" = 'x1' ]; then
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
            if [ "x${DEBUG:-}" = 'x1' ]; then
                >&2 echo 'No new packages installed or changed to optimize with.'
            fi
        fi
        rm -f "$BEFORE_PACKAGES" "$AFTER_PACKAGES"
    fi
    export ALLOW_SITE_PACKAGES=1
    find $BUILD_ROOT/usr/local/lib/python$PYTHON_VERSION/site-packages \
        -type f -name '*.py' -exec sh -c "remove-py-if-pyc-exists $extra {}" \; ;
    return $rc
}

trap fini EXIT
setup
export PYTHONPATH="${BUILD_ROOT}/usr/local/lib/python${PYTHON_VERSION}/site-packages"
export PIP_PREFIX="${BUILD_ROOT}/usr/local"

case "$1" in
    optimize)
    PIP_OPTIMIZE='1'
    ;;
esac

if [ x$PIP_OPTIMIZE = 'x1' ]; then
    BEFORE_PACKAGES=$(mktemp)
    AFTER_PACKAGES=$(mktemp)
    python -m pip freeze >"$BEFORE_PACKAGES"
fi

case "$@" in
    *'--force-reinstall'*|optimize*)
    maybe_packages=
    index='-1'
    for package_name in $@
    do
        if [ x"$package_name" != x ] && ! case "$package_name" in '-'*) true ;; *) false ;; esac ; then
            index="$(expr $index \+ 1)" || index='0'
            if case "$package_name" in *'=='*) true ;; *) false ;; esac ; then
                package_name="$(echo "${package_name}" | cut -d'=' -f1 | xargs)"
            fi
            if [ $index -ne 0 ]; then
                maybe_packages="${maybe_packages} ${package_name}"
            fi
        fi
    done
    if [ x$maybe_packages != x ]; then
        for package_name in $maybe_packages
        do
            # if the package is already installed, flag it
            # as if it wasn't installed so we can optimize it
            if [ x$package_name != x ] && pip show "${package_name}" >/dev/null ; then
                sed -i'' '/^'"${package_name}"'==/d' $BEFORE_PACKAGES
            fi
        done
    fi
    ;;
esac

if [ x"${1:-}" = xoptimize ]; then
    shift
    if [ x"$@" = x ]; then
        >&2 echo 'optimize [PACKAGE] [PACKAGE2] ... [PACKAGEN]
pass in package names to run optimize on
'
        exit 1
    fi
    exit
fi

python -m pip $@
