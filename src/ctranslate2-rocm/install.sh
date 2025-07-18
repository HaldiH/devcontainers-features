#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

. /etc/os-release

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

apt-get update
apt-get install -y --no-install-recommends \
    cmake \
    clang \
    libomp-dev

git clone https://github.com/arlo-phoenix/CTranslate2-rocm.git --recurse-submodules
cd CTranslate2-rocm
cmake -S . -B build \
    -DWITH_MKL=OFF \
    -DWITH_HIP=ON \
    -DBUILD_TESTS=ON \
    -DWITH_CUDNN=ON \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    ${PYTORCHROCMARCH:+-DCMAKE_HIP_ARCHITECTURES=$PYTORCHROCMARCH}

cmake --build build -- -j$(nproc)
cmake --install build
ldconfig
cd python
pip install -r install_requirements.txt
python setup.py bdist_wheel
pip install dist/*.whl

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf CTranslate2-rocm
