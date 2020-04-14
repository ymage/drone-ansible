FROM golang:1.14.2-alpine3.11 as gobuilder

ARG GOOS=linux
ARG GOARCH=amd64
ARG CGO_ENABLED=0
ARG VERSION

WORKDIR /go/src/app

COPY . /go/src/app

RUN apk add --no-cache --update \
      ca-certificates \
      git && \
    go build -v -ldflags "-X main.version=$VERSION" -a -tags netgo -o release/linux/amd64/drone-ansible && \
    chmod 0755 release/linux/amd64/drone-ansible

# Pull base image
FROM alpine:3.11.5 as base
FROM base as pybuilder

COPY requirements.txt /

RUN ln -s /lib /lib64 && \
    apk add --upgrade --no-cache \
      ca-certificates \
      curl && \
    apk add --upgrade --no-cache --virtual build-dependencies \
      build-base \
      libffi-dev \
      libressl-dev \
      python3-dev && \
    python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
    mkdir -p /python_dependencies && \
    python3 -m pip wheel --wheel-dir=/python_dependencies --no-cache-dir --requirement /requirements.txt

FROM base
LABEL maintainer="Ymage"
COPY --from=gobuilder /go/src/app/release/linux/amd64/drone-ansible /bin/
COPY --from=pybuilder /python_dependencies /python_dependencies
COPY --from=pybuilder /requirements.txt /requirements.txt

RUN apk add --upgrade --no-cache \
      ca-certificates \
      curl \
      git \
      openssh-client \
      libressl \
      python3 \
      rsync \
      zip && \
    python3 -m pip install --no-cache-dir --no-index --find-links=/python_dependencies --requirement /requirements.txt && \
    rm -fR /python_dependencies /requirements.txt && \
    mkdir -p ~/.ssh && \
    echo $'Host *\nStrictHostKeyChecking no' > ~/.ssh/config && \
    chmod 400 ~/.ssh/config

ENV PYTHONPATH=/usr/local/lib/python3.8/site-packages:$PYTHONPATH

ENTRYPOINT ["/bin/drone-ansible"]
