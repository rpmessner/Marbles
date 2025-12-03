# Bidama Hajiki (ビー玉弾き)

A physics-based marble flicking game inspired by the zeni hajiki minigame from Ghost of Yotei. Written in Zig with Vulkan and RTX ray tracing.

## Philosophy

This project follows **Jonathan Blow's programming philosophy**:
- Simple, direct code that solves the problem at hand
- Data-oriented design - think about actual data layout
- Minimal abstraction - only abstract when truly necessary
- No design patterns for the sake of patterns
- Structs + functions, not heavy OOP
- Solve today's problems today, not hypothetical future ones

## Why Zig?

We switched from C++ to Zig because:
- **Philosophy alignment** - Zig is designed for the same "simple, direct" style we were forcing C++ into
- **Excellent C interop** - Vulkan and GLFW work seamlessly via `@cImport`
- **Built-in build system** - Replaces CMake + vcpkg + Makefiles
- **Cross-compilation** - Windows builds are trivial: `zig build -Dtarget=x86_64-windows`
- **No hidden control flow** - No exceptions, no hidden allocations, no surprises

## Build Requirements

### Quick Start

```bash
# Install Zig (0.13.0+)
# See https://ziglang.org/download/

# Build
zig build

# Run
zig build run
```

### Dependencies

**Linux:**
```bash
sudo apt-get install libglfw3-dev libvulkan-dev vulkan-tools vulkan-validationlayers-dev
```

**macOS:**
```bash
brew install glfw vulkan-headers vulkan-loader
# Also install Vulkan SDK from https://vulkan.lunarg.com/
```

**Windows:**
- Install the Vulkan SDK from [LunarG](https://vulkan.lunarg.com/)
- GLFW headers/libs (or cross-compile from Linux)

### Cross-Compilation (Windows from Linux)

```bash
zig build -Dtarget=x86_64-windows
```

## Goals

A beautiful, skill-based marble flicking game with:
- **Zeni hajiki-inspired gameplay** - aim, charge power, flick marbles
- **RTX-powered ray tracing** for realistic glass refraction and caustics
- **Physically-based rendering** - marbles that look like real glass
- **Different marble types**: cat's eye, swirls, clearies, galaxies
- **Modern shader programming** - write GLSL from scratch, understand every line

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
