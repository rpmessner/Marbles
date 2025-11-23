#!/bin/bash
# Setup script for Marbles development environment

echo "Installing dependencies for Marbles..."

if command -v apt-get &> /dev/null; then
    echo "Detected apt (Debian/Ubuntu)"
    sudo apt-get update
    sudo apt-get install -y \
        cmake \
        build-essential \
        libglfw3-dev \
        libvulkan-dev \
        vulkan-tools \
        vulkan-validationlayers-dev \
        libode-dev \
        pkg-config

    echo ""
    echo "Dependencies installed successfully!"
    echo ""
    echo "GPU drivers with Vulkan support:"
    echo "  NVIDIA: Install nvidia-driver-xxx"
    echo "  AMD: Install mesa-vulkan-drivers"
    echo "  Intel: Install mesa-vulkan-drivers intel-media-va-driver"
    echo ""
    echo "Now run: make"

elif command -v brew &> /dev/null; then
    echo "Detected Homebrew (macOS)"
    brew install cmake glfw vulkan-headers vulkan-loader ode

    echo ""
    echo "Dependencies installed successfully!"
    echo "Make sure you have the Vulkan SDK installed from LunarG"
    echo "Now run: make"

else
    echo "Unsupported package manager"
    echo "Please manually install: cmake, glfw3, ode"
    exit 1
fi
