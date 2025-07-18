#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

. /etc/os-release

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

export PYTORCH_ROCM_ARCH=${PYTORCHROCMARCH:-gfx1030}

apt-get update
apt-get install -y --no-install-recommends \
    cmake \
    clang \
    libomp-dev

git clone https://github.com/arlo-phoenix/CTranslate2-rocm.git --recurse-submodules
cd CTranslate2-rocm
CLANG_CMAKE_CXX_COMPILER=clang++ CXX=clang++ HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)"     cmake -S . -B build -DWITH_MKL=OFF -DWITH_HIP=ON -DCMAKE_HIP_ARCHITECTURES=$PYTORCH_ROCM_ARCH -DBUILD_TESTS=ON -DWITH_CUDNN=ON
cmake --build build -- -j$(nproc)
cmake --install build
ldconfig
cd python
pip install -r install_requirements.txt
python setup.py bdist_wheel
pip install dist/*.whl
