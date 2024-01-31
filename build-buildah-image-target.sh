#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Build variables
source ./build-load-vars.sh

# Build
TARGET="$TARGET" ./build-target.sh

# Container
CONTAINER=$(buildah from "$BASE_IMAGE_FULL_TAG")
CONTAINER_MOUNT=$(buildah mount "$CONTAINER")

## Copy
cp -r build/* "$CONTAINER_MOUNT"/usr/share/nginx/html

# Label
buildah config --label maintainer="$IMAGE_MAINTAINER" "$CONTAINER"
buildah config --label name="$IMAGE_NAME" "$CONTAINER"
buildah config --label version="$IMAGE_RELEASE_TAG" "$CONTAINER"
buildah config --label docker.cmd="podman run -it $IMAGE_FULL_TAG" "$CONTAINER"
buildah config --label org.opencontainers.image.source="$REPOSITORY_URL" "$CONTAINER"
buildah config --label org.opencontainers.image.description="$IMAGE_DESCRIPTION" "$CONTAINER"

# Commit
buildah commit "$CONTAINER" "$IMAGE_FULL_TAG"

# Cleanup
buildah rm "$CONTAINER"
