#!/bin/bash
# Build script for Windows target (cross-compiled from Linux)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building Marbles for Windows (x64)..."

# Create build directory
mkdir -p "$SCRIPT_DIR/build-windows"
cd "$SCRIPT_DIR/build-windows"

# Configure with vcpkg toolchain and MinGW
cmake "$SCRIPT_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/vcpkg/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_TARGET_TRIPLET=x64-mingw-dynamic \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release

echo ""
echo "Windows build complete!"
echo "Executable: build-windows/marbles.exe"
echo ""
echo "To run on Windows, copy marbles.exe and required DLLs:"
echo "  cp build-windows/marbles.exe /mnt/c/your/path/"
echo "  cp ../vcpkg/installed/x64-mingw-dynamic/bin/*.dll /mnt/c/your/path/"
