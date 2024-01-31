#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o xtrace

# Initialize build directory
rm -rf ./build
mkdir ./build

# Build variables
source ./build-load-vars.sh

for f in templates/*; do
    envsubst <"$f" |
        gominify --type=html >"build/${f#templates/}"
done

mkdir ./build/assets
cp -r assets/default build/assets
cp -r assets/"$TARGET" build/assets
