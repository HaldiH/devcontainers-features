#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

. /etc/os-release

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

ROCM_VERSION=${ROCMVERSION}

# Make the directory if it doesn't exist yet.
# This location is recommended by the distribution maintainers.
sudo mkdir --parents --mode=0755 /etc/apt/keyrings

# Download the key, convert the signing-key to a full
# keyring required by apt and store in the keyring directory
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null

# Register ROCm packages
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/$ROCM_VERSION jammy main" \
    | sudo tee --append /etc/apt/sources.list.d/rocm.list
echo -e 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600' \
    | sudo tee /etc/apt/preferences.d/rocm-pin-600
sudo apt-get update

sudo apt-get install -y rocm

sudo tee --append /etc/ld.so.conf.d/rocm.conf <<EOF
/opt/rocm/lib
/opt/rocm/lib64
EOF
sudo ldconfig

echo 'export PATH="/opt/rocm/bin:/opt/rocm/llvm/bin:$PATH"' >> /etc/profile.d/rocm.sh
echo 'export LD_LIBRARY_PATH="/opt/rocm/lib:$LD_LIBRARY_PATH"' >> /etc/profile.d/rocm.sh

rm -rf /var/lib/apt/lists/*