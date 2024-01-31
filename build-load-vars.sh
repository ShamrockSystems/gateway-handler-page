#!/usr/bin/env bash

# shellcheck disable=SC1090
for f in vars/default/*.sh; do source "$f"; done
# shellcheck disable=SC1090
for f in vars/"$TARGET"/*.sh; do source "$f"; done
source vars/derived.sh
