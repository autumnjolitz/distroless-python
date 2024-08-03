#syntax=docker/dockerfile:1
ARG SOURCE_IMAGE=autumnjolitz/distroless-python:3.12-alpine3.20
FROM $SOURCE_IMAGE-buildroot AS buildroot

ADD requirements.txt .

RUN python -m pip install \
        --no-cache \
        --prefix "$BUILD_ROOT/usr/local" \
        -r requirements.txt

ARG SOURCE_IMAGE=autumnjolitz/distroless-python:3.12-alpine3.20
FROM $SOURCE_IMAGE

EXPOSE 8080

COPY --from=buildroot \
    /$BUILD_ROOT/usr/local/lib/python$PYTHON_VERSION/site-packages \
    /usr/local/lib/python$PYTHON_VERSION/site-packages
COPY --from=buildroot \
    /$BUILD_ROOT/usr/local/bin/flask \
    /usr/local/bin/flask

WORKDIR /app
ADD hello.py .
ENV FLASK_RUN_PORT=8080

ENTRYPOINT ["flask"]
CMD ["--app", "hello", "run", "--host=0.0.0.0"]
