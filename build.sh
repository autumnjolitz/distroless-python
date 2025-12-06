#!/usr/bin/env sh

. env.sh

log="$(mktemp image.log.XXXX)"
trap "rm -f $log" EXIT

if ! >"$log" 2>&1 docker pull "$SOURCE_IMAGE"; then
    >&2 echo 'Unable to find '"$SOURCE_IMAGE"'!'
    >&2 cat "$log"
    exit 4;
fi


BASE_IMAGE_DIGEST=$(digest_of "$SOURCE_IMAGE" "$log")
if [ "x$BASE_IMAGE_DIGEST" = 'x' ]; then
    exit 88
fi

>&2 echo "BASE_IMAGE_DIGEST=${BASE_IMAGE_DIGEST}"

if ! >"$log" 2>&1 docker build \
    --build-arg "ALPINE_VERSION=${ALPINE_VERSION}" \
    --build-arg "BASE_IMAGE_DIGEST=${BASE_IMAGE_DIGEST}" \
    --build-arg "PYTHON_VERSION=${PYTHON_VERSION}" \
    --build-arg "BUILD_ROOT=/d" \
    -f buildroot/Dockerfile.alpine \
    -t "${IMAGE_TAG}-buildroot" \
    . ; then
    >&2 echo 'Unable to build '"${IMAGE_TAG}-buildroot"'!'
    >&2 cat "$log"
    exit 8;
fi
if ! >"$log" 2>&1 docker build \
    --build-arg "ALPINE_VERSION=${ALPINE_VERSION}" \
    --build-arg "BASE_IMAGE_DIGEST=${BASE_IMAGE_DIGEST}" \
    --build-arg "PYTHON_VERSION=${PYTHON_VERSION}" \
    --build-arg "BUILD_ROOT=/d" \
    --build-arg "SOURCE_IMAGE=${IMAGE_TAG}-buildroot" \
    -f buildroot/Dockerfile.alpine \
    -t "${IMAGE_TAG}" \
    . ; then
    >&2 echo 'Unable to build '"$IMAGE_TAG"'!'
    >&2 cat "$log"
    exit 8;
fi

echo "$IMAGE_TAG"
