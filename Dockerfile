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

FROM alpine:3.11.6 as base
FROM base as pybuilder

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    VIRTUAL_ENV=/opt/venv \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN ln -s /lib /lib64 && \
    apk add --upgrade --no-cache \
      ca-certificates \
      curl && \
    apk add --upgrade --no-cache --virtual build-dependencies \
      build-base \
      libffi-dev \
      libressl-dev \
      python3-dev

RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY requirements.txt /
RUN python3 -m pip install --no-cache-dir --upgrade --requirement /requirements.txt

FROM base
LABEL maintainer="Ymage (fork maintainer)"
LABEL maintainer="Drone.IO Community <drone-dev@googlegroups.com>" \
      org.label-schema.name="Drone Ansible" \
      org.label-schema.vendor="Drone.IO Community" \
      org.label-schema.schema-version="1.0"

COPY --from=gobuilder /go/src/app/release/linux/amd64/drone-ansible /bin/
COPY --from=pybuilder /opt/venv /opt/venv

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONPATH=/opt/venv/lib/python3.8/site-packages:$PYTHONPATH \
    ANSIBLE_STRATEGY_PLUGINS=/opt/venv/lib/python3.8/site-packages/ansible_mitogen/plugins/strategy \
    ANSIBLE_STRATEGY=mitogen_linear \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

RUN apk add --upgrade --no-cache \
      ca-certificates \
      curl \
      git \
      openssh-client \
      libressl \
      python3 \
      rsync \
      zip && \
    mkdir -p ~/.ssh && \
    echo $'Host *\nStrictHostKeyChecking no' > ~/.ssh/config && \
    chmod 400 ~/.ssh/config

ENTRYPOINT ["/bin/drone-ansible"]
