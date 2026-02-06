#!/bin/bash
set -e

if [ ! -f configure ]; then
    ./autogen.sh
fi

if [ ! -f Makefile ]; then
    ./configure
fi

make -j"$(nproc)"

echo "Build complete: src/typeMode"
