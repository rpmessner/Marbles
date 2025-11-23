#!/bin/bash
# Build script for native Linux

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Building Marbles for Linux..."

# Create build directory
mkdir -p "$SCRIPT_DIR/build-linux"
cd "$SCRIPT_DIR/build-linux"

# Configure
cmake "$SCRIPT_DIR" -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build . --config Release

echo ""
echo "Linux build complete!"
echo "Executable: build-linux/marbles"
echo "Run with: ./build-linux/marbles"
