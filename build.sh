#!/usr/bin/env bash
set -euo pipefail

IMAGE=drone-ansible
DOCKER_HUB_USER=ymage
VERSION=2.8.1

echo "Build ${IMAGE}:${VERSION}"

# Build the docker image
docker build --tag ${DOCKER_HUB_USER}/${IMAGE}:${VERSION} --build-arg VERSION=$VERSION --file Dockerfile .

# Push to dockerhub
docker push ${DOCKER_HUB_USER}/${IMAGE}:${VERSION}
