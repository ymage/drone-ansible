#!/usr/bin/env bash
set -euo pipefail

export GOOS=linux
export GOARCH=amd64
export CGO_ENABLED=0
export GO111MODULE=on

go build -v -a -tags netgo -o release/linux/amd64/drone-ansible

IMAGE=drone-ansible
DOCKER_HUB_USER=ymage
VERSION=2.8.1

echo "Build ${IMAGE}:${VERSION}"

# 1. Build the docker image
docker build --tag ${DOCKER_HUB_USER}/${IMAGE}:${VERSION} --file docker/Dockerfile.linux.amd64 .

# Push to dockerhub
docker push ${DOCKER_HUB_USER}/${IMAGE}:${VERSION}
