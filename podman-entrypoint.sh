#!/usr/bin/env sh
set -eu


if [ "${ENABLE_NVIDIA_GPU:-0}" = "1" ]; then
    echo "ENABLE_NVIDIA_GPU=1; generating NVIDIA CDI spec..."
    mkdir -p /etc/cdi
    nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    nvidia-ctk cdi list
else
    echo "ENABLE_NVIDIA_GPU is not enabled; skipping NVIDIA CDI setup."
fi

exec podman system service --time=0 unix:///tmp/podman.sock
