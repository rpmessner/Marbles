# Bidama Hajiki (ビー玉弾き)

A physics-based marble flicking game inspired by the zeni hajiki minigame from Ghost of Yotei. Written in C-style C++ with Vulkan and RTX ray tracing.

## Philosophy

This project follows **Jonathan Blow's programming philosophy**:
- Simple, direct code that solves the problem at hand
- Data-oriented design - think about actual data layout
- Minimal abstraction - only abstract when truly necessary
- No design patterns for the sake of patterns
- C-style code in C++ (structs + functions, not heavy OOP)
- Solve today's problems today, not hypothetical future ones

## Build Requirements

### Quick Setup
```bash
./setup.sh
```

### Manual Installation

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get install cmake build-essential \
    libglfw3-dev libvulkan-dev vulkan-tools \
    vulkan-validationlayers-dev
```

Physics library will be added in Phase 4 (when needed).

You'll also need GPU drivers with Vulkan support:
- NVIDIA: `sudo apt-get install nvidia-driver-xxx`
- AMD: `sudo apt-get install mesa-vulkan-drivers`
- Intel: `sudo apt-get install mesa-vulkan-drivers`

#### macOS
```bash
brew install cmake glfw vulkan-headers vulkan-loader
```

Download the Vulkan SDK from [LunarG](https://vulkan.lunarg.com/)

Physics library will be added in Phase 4 (when needed).

#### Windows
- Install the Vulkan SDK from [LunarG](https://vulkan.lunarg.com/)
- Install vcpkg and use it to install dependencies:
  ```bash
  vcpkg install glfw3
  ```

Physics library will be added in Phase 4 (when needed).

## Building

### Option 1: Direct Makefile (simpler)
```bash
make
./marbles
```

### Option 2: CMake (if you prefer)
```bash
mkdir build
cd build
cmake ..
make
./marbles
```

## Goals

A beautiful, skill-based marble flicking game with:
- **Zeni hajiki-inspired gameplay** - aim, charge power, flick marbles
- **RTX-powered ray tracing** for realistic glass refraction and caustics
- **Physically-based rendering** - marbles that look like real glass
- **Different marble types**: cat's eye, swirls, clearies, galaxies
- **Modern shader programming** - write GLSL from scratch, understand every line
- **Real-time physics** with Jolt Physics for accurate marble collisions

## Architecture

No UML diagrams. No class hierarchies. Just:
- Plain structs for marble data (position, velocity, type, color)
- Functions that operate on that data
- Handwritten shaders - no shader frameworks
- Direct, understandable code

## Development

### Sessions
See [docs/sessions/](./docs/sessions/) for detailed documentation of each development session.

### Roadmap
See [ROADMAP.md](./ROADMAP.md) for the full development plan.

## Museum

The original "Marbles" college project (2004) is preserved in the `museum/` folder.
It's a textbook example of over-engineered OOP with Singletons, Factories,
and deep inheritance hierarchies. We learned from its mistakes and started fresh.
