#!/usr/bin/env sh
set -eu pipefail

mkdir -p /etc/cdi
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk cdi list

exec podman system service --time=0 unix:///tmp/podman.sock
