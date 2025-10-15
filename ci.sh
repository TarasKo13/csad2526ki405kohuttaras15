#!/usr/bin/env bash
set -euo pipefail

echo "[CI] Cleaning existing build directory (if any)"
if [ -d build ]; then
  rm -rf build
fi

echo "[CI] Creating build directory"
mkdir -p build
cd build

echo "[CI] Configuring with CMake"
cmake ..

echo "[CI] Building project"
cmake --build .

echo "[CI] Running tests"
ctest --output-on-failure

echo "[CI] All steps completed successfully"
