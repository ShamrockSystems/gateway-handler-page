#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Build variables
source ./build-load-vars.sh

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

## Dependencies
dnf install "${CONTAINER_DNF_FLAGS[@]}" \
    nginx
## Configure
sed -i '/^user /s/^/#/' "$CONTAINER_MOUNT"/etc/nginx/nginx.conf
sed -i 's|^pid.*|pid /dev/null;|' "$CONTAINER_MOUNT"/etc/nginx/nginx.conf
sed -i 's|access_log .*|access_log /dev/stdout;|' "$CONTAINER_MOUNT"/etc/nginx/nginx.conf
sed -i 's|error_log .*|error_log /dev/stderr;|' "$CONTAINER_MOUNT"/etc/nginx/nginx.conf
sed -i 's/listen\s\+80;/listen 8080;/g' "$CONTAINER_MOUNT"/etc/nginx/nginx.conf
sed -i 's/listen\s\+\[::\]:80;/listen [::]:8080;/g' "$CONTAINER_MOUNT"/etc/nginx/nginx.conf
## Cleanup
dnf clean all "${CONTAINER_DNF_FLAGS[@]}"
rm -r "$CONTAINER_MOUNT"/usr/share/nginx/html/*
## Permissions
buildah run "$CONTAINER" -- chown -R nginx:nginx /etc/nginx/
buildah run "$CONTAINER" -- chown -R nginx:nginx /usr/share/nginx/html/
buildah run "$CONTAINER" -- chown -R nginx:nginx /var/log/nginx/

# Label
buildah config --label maintainer="$BASE_IMAGE_MAINTAINER" "$CONTAINER"
buildah config --label name="$BASE_IMAGE_NAME" "$CONTAINER"
buildah config --label version="$BASE_IMAGE_RELEASE_TAG" "$CONTAINER"
buildah config --label docker.cmd="podman run -it $BASE_IMAGE_FULL_TAG" "$CONTAINER"
buildah config --label org.opencontainers.image.source="$REPOSITORY_URL" "$CONTAINER"
buildah config --label org.opencontainers.image.description="$BASE_IMAGE_DESCRIPTION" "$CONTAINER"

# Configuration
buildah config --user nginx "$CONTAINER"
buildah config --workingdir /usr/share/nginx/html "$CONTAINER"
buildah config --entrypoint '["nginx", "-g", "daemon off;"]' "$CONTAINER"

# Commit
buildah commit "$CONTAINER" "$BASE_IMAGE_FULL_TAG"

# Cleanup
buildah rm "$CONTAINER"
