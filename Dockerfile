FROM golang:1.12.5-alpine3.9 as builder

ARG GOOS=linux
ARG GOARCH=amd64
ARG CGO_ENABLED=0
ARG GO111MODULE=on
ARG VERSION

ENV VERSION=${VERSION}

WORKDIR /go/src/app

COPY . /go/src/app

RUN apk add --no-cache --update \
      ca-certificates \
      git && \
    go build -v -ldflags "-X main.version=$VERSION" -a -tags netgo -o release/linux/amd64/drone-ansible

# Pull base image
FROM python:3.7.3-alpine3.9
LABEL maintainer="Ymage"

COPY --from=builder /go/src/app/release/linux/amd64/drone-ansible /bin/

RUN ln -s /lib /lib64 && \
    apk add --upgrade --no-cache \
      ca-certificates \
      curl \
      git \
      openssh-client \
      libressl \
      rsync \
      zip && \
    apk add --upgrade --no-cache --virtual build-dependencies \
      build-base \
      libffi-dev \
      libressl-dev \
      python3-dev

# Ansible installation
COPY requirements.txt /opt/
RUN python3 -m pip install --no-cache-dir --upgrade --requirement /opt/requirements.txt && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/* && \
    mkdir -p ~/.ssh && \
    echo $'Host *\nStrictHostKeyChecking no' > ~/.ssh/config && \
    chmod 400 ~/.ssh/config

ENV PYTHONPATH=/usr/local/lib/python3.7/site-packages:$PYTHONPATH

ENTRYPOINT ["/bin/drone-ansible"]
