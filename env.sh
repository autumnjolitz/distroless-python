set -eu
set -o pipefail
shopt -s nullglob


jq="$(command -v jq)"

digest_of() {
    local repo="${1:-}"
    local log="${2:-}"
    if [ "x$jq" = 'x' ]; then
        >&2 echo 'jq not installed!'
        return 101
    fi
    if [ "x$repo" = 'x' ]; then
        >&2 echo 'no repo provided!'
        return 1
    fi
    local PIPE=$(mktemp -u)
    mkfifo "$PIPE"
    exec 3<> "$PIPE"
    rm $PIPE
    if [ "x$log" = 'x' ]; then
        log="$(mktemp digest_of.log.XXXX)"
        trap "rm -f $log;exec 3>&-" RETURN
    else
        trap "exec 3>&-" RETURN
    fi
    if ! 2>>"$log" docker inspect "$repo" | >&3 2>>"$log" $jq -r '.[].RepoDigests[]'; then
        >&2 echo 'Unable to inspect '"$repo"'!'
        >&2 cat "$log"
        return 16
    fi

    local digest
    read digest <&3
    if [ "x$digest" = 'x' ]; then
        >&2 echo 'digest empty?!'
        return 88
    fi
    echo "$digest" | cut -d '@' -f2-
}

trim_slash() {
    local s
    for s in "${@:-}"
    do
        sed -E 's://*:/:g; s:(^/)?/*$:\1:' <<< "${s}"
    done;
}

ALPINE_VERSION="${1:-}"
PYTHON_VERSION="${2:-}"
ORG="${3:-}"

if [ "x${ALPINE_VERSION}" = 'x' ]; then
    >&2 echo 'missing ALPINE_VERSION'
    exit 1
fi

if [ "x${PYTHON_VERSION}" = 'x' ]; then
    >&2 echo 'missing PYTHON_VERSION'
    exit 1
fi

REPOSITORY="${4:-}"

if ! case $REPOSITORY in */) false ;; *) true ;; esac; then
    # trim off the trailing slash
    REPOSITORY="$(trim_slash "$REPOSITORY")"
fi

if ! case $REPOSITORY in docker.io*) false ;; *) true ;; esac; then
    # ARJ: The default context _is_ docker.io
    REPOSITORY=''
fi

IMAGE_TAG="distroless-python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}"
if [ "x$ORG" != 'x' ]; then
    IMAGE_TAG="${ORG}/${IMAGE_TAG}"
fi

if [ "x$REPOSITORY" != 'x' ]; then
    IMAGE_TAG="${REPOSITORY}/${IMAGE_TAG}"
fi

SOURCE_IMAGE="docker.io/python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}"



>&2 echo "ALPINE_VERSION=${ALPINE_VERSION}"
>&2 echo "PYTHON_VERSION=${PYTHON_VERSION}"
>&2 echo "SOURCE_IMAGE=${SOURCE_IMAGE}"
>&2 echo "IMAGE_TAG=${IMAGE_TAG}"
>&2 echo "REPOSITORY=${REPOSITORY}"

export ALPINE_VERSION
export PYTHON_VERSION
export SOURCE_IMAGE
export IMAGE_TAG
export REPOSITORY
