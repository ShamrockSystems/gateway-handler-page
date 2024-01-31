#!/usr/bin/env bash

# Setup
set -o errexit
set -o nounset
set -o xtrace

IMAGE_NAME="gradescope-calendar"
RELEASE_TAG="latest"
REPOSITORY_USER="GreenCappuccino"
REPOSITORY_NAME="gradescope-calendar"

IMAGE_MAINTAINER="Brian Lu <me@greencappuccino.net>"
IMAGE_DESCRIPTION="This script scrapes your Gradescope account for courses and assignment details."

FEDORA_VERSION="39"
FEDORA_BUILDER_IMAGE="fedora"
PYTHON_VERSION="3.12"

# Builder
BUILDER=$(buildah from registry.fedoraproject.org/${FEDORA_BUILDER_IMAGE}:${FEDORA_VERSION})
BUILDER_MOUNT=$(buildah mount "$BUILDER")

buildah config --label maintainer="$IMAGE_MAINTAINER" "$BUILDER"
buildah config --label name="$IMAGE_NAME" "$BUILDER"

## Build dependencies
buildah run "$BUILDER" dnf install --assumeyes \
  python${PYTHON_VERSION} \
  python${PYTHON_VERSION}-pip \
  python${PYTHON_VERSION}-build \
  python${PYTHON_VERSION}-setuptools \
  python${PYTHON_VERSION}-wheel
buildah config --workingdir /src "$BUILDER"

## Source code
mkdir -p "$BUILDER_MOUNT"/src
cp -r ./* "$BUILDER_MOUNT"/src/

## Perform build
buildah run "$BUILDER" python3 -m build --wheel --outdir dist

# Container
CONTAINER=$(buildah from scratch)
CONTAINER_MOUNT=$(buildah mount "$CONTAINER")
CONTAINER_DNF_FLAGS=(
  --assumeyes
  '--disablerepo=*'
  --enablerepo=fedora
  --enablerepo=updates
  --nodocs
  --setopt install_weak_deps=False
  --installroot "$CONTAINER_MOUNT"
  --releasever "$FEDORA_VERSION"
)
CONTAINER_PIP_FLAGS=(
  --upgrade
  --target="$CONTAINER_MOUNT"/usr/lib/python"${PYTHON_VERSION}"/site-packages
)

## Dependencies
dnf install "${CONTAINER_DNF_FLAGS[@]}" python${PYTHON_VERSION}
mkdir "$CONTAINER_MOUNT"/app
## Install
pip install "$BUILDER_MOUNT"/src/dist/*.whl "${CONTAINER_PIP_FLAGS[@]}"
## Cleanup
dnf clean all "${CONTAINER_DNF_FLAGS[@]}"

# Additional labels
buildah config --workingdir /app "$CONTAINER"
buildah config --label maintainer="$IMAGE_MAINTAINER" "$CONTAINER"
buildah config --label name="$IMAGE_NAME" "$CONTAINER"
buildah config --label version="$RELEASE_TAG" "$CONTAINER"
buildah config --label docker.cmd="podman run -it $BASE_IMAGE_FULL_TAG" "$CONTAINER"
buildah config --label org.opencontainers.image.source="$REPOSITORY_URL" "$CONTAINER"
buildah config --label org.opencontainers.image.description="$IMAGE_DESCRIPTION" "$CONTAINER"
buildah config --label org.opencontainers.image.licenses="AGPL-3.0" "$CONTAINER"

buildah config --entrypoint '["python3", "-m", "gradescopecalendar.entrypoint"]' "$CONTAINER"

# Commit
buildah commit --squash "$CONTAINER" "$IMAGE_NAME"

# Cleanup
buildah rm "$BUILDER"
buildah rm "$CONTAINER"
