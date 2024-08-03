distroless-python images
=================================

.. list-table::
    :stub-columns: 1

    * - Latest Build
      - |github-actions|
    * - Source
      - `<https://github.com/autumnjolitz/distroless-python>`_
    * - Issues
      - `<https://github.com/autumnjolitz/distroless-python/issues>`_
    * - DockerHub
      - `<https://hub.docker.com/r/autumnjolitz/distroless-python>`_

Images
---------

DockerHub:

* |dockerhub_py312alpine320|_
* |dockerhub_py311alpine320|_
* |dockerhub_py310alpine320|_
* |dockerhub_py39alpine320|_
* |dockerhub_py38alpine320|_


Github Container Repository:

* |ghcr_py312alpine320|_
* |ghcr_py311alpine320|_
* |ghcr_py310alpine320|_
* |ghcr_py39alpine320|_
* |ghcr_py38alpine320|_


About
------

A distroless image is one that has the **bare minimum** to run the application.

By definition, a **distroless** image is **secure** as it has less code, less entrypoints.

**distroless-python** builds off of the official `DockerHub python <https://hub.docker.com/_/python>`_ images, which means that as the official images are updated, a refresh is a simple CI/CD run away to get any updates or bugfixes.

.. code:: bash

    $  docker images | grep -E \
    >   '^(REPO|gcr.io/distroless/python3|autumnjolitz/distroless-python|python)' | \
    >   grep -E 'REPO|latest|3.12-alpine3.20' | sort
    REPOSITORY                       TAG                IMAGE ID       CREATED         SIZE
    autumnjolitz/distroless-python   3.12-alpine3.20    4a335b955cb1   54 years ago    27.8MB
    gcr.io/distroless/python3        latest             e83c6b1e2ef3   N/A             52.8MB
    python                           3.12-alpine3.20    2ec26f9329f2   5 days ago      55.3MB

a distroless-python image provides:

* python3
* dash
* ca-certificates (NB: Use ``update-ca-certificates`` to update them)

To save space, the standard library has been byte-compiled and compressed into a zip file which is imported by the interpreter.

ensurepip is replaced with a no-op to allow venv to continue functioning.

Development
-------------

For each image, there is a **-buildroot** companion package. You may ``FROM $SOURCE-buildroot AS builder`` in your own ``Dockerfile``s and add to the new root at ``$BUILD_ROOT``!

The following is an example demonstrating the installation of a PyPI package (httpie) into a minimal image.

Given the following ``Dockerfile``, we will add ``httpie`` to the image and reference just that!

.. code:: dockerfile

    #syntax=docker/dockerfile:1
    FROM autumnjolitz/distroless-python:3.12-alpine3.20-buildroot AS buildroot
    RUN python -m pip install \
            --no-cache \
            --prefix "$BUILD_ROOT/usr/local" \
            httpie

    FROM autumnjolitz/distroless-python:3.12-alpine3.20
    COPY --from=buildroot \
        /$BUILD_ROOT/usr/local/lib/python$PYTHON_VERSION/site-packages \
        /usr/local/lib/python$PYTHON_VERSION/site-packages
    COPY --from=buildroot \
        /$BUILD_ROOT/usr/local/bin/http \
        /usr/local/bin/http

    ENTRYPOINT ["http"]


Build and test the image!

.. code:: bash

    $ docker build -t httpie =f Dockerfile .
    $ docker run --rm -it httpie pie.dev/get
    HTTP/1.1 200 OK
    Access-Control-Allow-Credentials: true
    Access-Control-Allow-Origin: *
    Connection: keep-alive
    Content-Encoding: gzip
    Content-Type: application/json
    Date: Sat, 03 Aug 2024 07:00:04 GMT
    Transfer-Encoding: chunked
    alt-svc: h3=":443"; ma=86400

    {
        "args": {},
        "headers": {
            "Accept": "*/*",
            "Accept-Encoding": "gzip",
            "Connection": "Keep-Alive",
            "Host": "pie.dev",
            "User-Agent": "HTTPie/3.2.3"
        },
        "origin": "[suppressed]",
        "url": "http://pie.dev/get"
    }
    $ docker images test
    REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
    httpie         latest    7c6811df800d   3 minutes ago   43.3MB


Isn't that neat? Tiny images!

Another example may be found at `examples/simple-flask/ <https://github.com/autumnjolitz/distroless-python/blob/main/examples/simple-flask>`_!


.. |dockerhub_py312alpine320| replace:: ``3.12-alpine3.20``
.. _dockerhub_py312alpine320: https://hub.docker.com/r/autumnjolitz/distroless-python/tags?name=3.12-alpine3.20
.. |dockerhub_py311alpine320| replace:: ``3.11-alpine3.20``
.. _dockerhub_py311alpine320: https://hub.docker.com/r/autumnjolitz/distroless-python/tags?name=3.11-alpine3.20
.. |dockerhub_py310alpine320| replace:: ``3.10-alpine3.20``
.. _dockerhub_py310alpine320: https://hub.docker.com/r/autumnjolitz/distroless-python/tags?name=3.10-alpine3.20
.. |dockerhub_py39alpine320| replace:: ``3.9-alpine3.20``
.. _dockerhub_py39alpine320: https://hub.docker.com/r/autumnjolitz/distroless-python/tags?name=3.9-alpine3.20
.. |dockerhub_py38alpine320| replace:: ``3.8-alpine3.20``
.. _dockerhub_py38alpine320: https://hub.docker.com/r/autumnjolitz/distroless-python/tags?name=3.8-alpine3.20
.. |ghcr_py312alpine320| replace:: ``ghcr.io/autumnjolitz/distroless-python:3.12-alpine3.20``
.. _ghcr_py312alpine320: https://github.com/autumnjolitz/distroless-python/pkgs/container/distroless-python/versions?filters%5Bversion_type%5D=tagged
.. |ghcr_py311alpine320| replace:: ``ghcr.io/autumnjolitz/distroless-python:3.11-alpine3.20``
.. _ghcr_py311alpine320: https://github.com/autumnjolitz/distroless-python/pkgs/container/distroless-python/versions?filters%5Bversion_type%5D=tagged
.. |ghcr_py310alpine320| replace:: ``ghcr.io/autumnjolitz/distroless-python:3.10-alpine3.20``
.. _ghcr_py310alpine320: https://github.com/autumnjolitz/distroless-python/pkgs/container/distroless-python/versions?filters%5Bversion_type%5D=tagged
.. |ghcr_py39alpine320| replace:: ``ghcr.io/autumnjolitz/distroless-python:3.9-alpine3.20``
.. _ghcr_py39alpine320: https://github.com/autumnjolitz/distroless-python/pkgs/container/distroless-python/versions?filters%5Bversion_type%5D=tagged
.. |ghcr_py38alpine320| replace:: ``ghcr.io/autumnjolitz/distroless-python:3.8-alpine3.20``
.. _ghcr_py38alpine320: https://github.com/autumnjolitz/distroless-python/pkgs/container/distroless-python/versions?filters%5Bversion_type%5D=tagged


.. |github-actions| image:: https://github.com/autumnjolitz/distroless-python/actions/workflows/main.yml/badge.svg
    :target: https://github.com/autumnjolitz/distroless-python/actions/workflows/main.yml
