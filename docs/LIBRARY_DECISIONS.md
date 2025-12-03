# Library Decisions & Modern Alternatives

**Last Updated:** 2025-12-03 (Session 004 - Zig Migration)
**Status:** Active - Switched from C++ to Zig

## Major Decision: Language Switch to Zig

### Why Zig?

**The C++ paradox:** We were writing "C-style code in C++" - avoiding classes, RAII, exceptions, templates. We were fighting the language to stay simple.

**Zig solves this:**
- ✅ **Philosophy match** - Built for simple, direct, explicit code
- ✅ **C interop** - `@cImport` works seamlessly with Vulkan/GLFW
- ✅ **Build system included** - Replaces CMake + vcpkg + Makefiles
- ✅ **Cross-compilation** - `zig build -Dtarget=x86_64-windows` just works
- ✅ **No hidden control flow** - No exceptions, no hidden allocations
- ✅ **Comptime** - Compile-time evaluation instead of templates/macros

**Decision:** Switch to Zig ✅ (Session 004)

---

## Critical Decision: Physics Engine

### Current Choice: TBD (Phase 4)

With the Zig switch, our physics options change:

**Option 1: Jolt Physics via C API**
- Jolt has a C API wrapper: [JoltC](https://github.com/jrouwe/JoltPhysics/tree/master/Jolt/C)
- Would work via `@cImport`
- Still AAA-proven, modern, fast

**Option 2: Zig-native physics**
- [zphysics](https://github.com/zig-gamedev/zphysics) - Zig bindings for Jolt
- Part of zig-gamedev ecosystem
- More idiomatic Zig integration

**Option 3: Hand-roll simple physics**
- Marbles are spheres - collision detection is straightforward
- Could implement basic physics ourselves (educational value)
- Only need: sphere-sphere, sphere-plane collision

**Decision:** Defer until Phase 4. Evaluate zphysics vs hand-rolled.

---

## Graphics & Windowing Libraries

### Vulkan ✅ CONFIRMED

**Current:** Vulkan 1.3 via `@cImport`
**Status:** ✅ Works perfectly with Zig

**Why it's right:**
- Modern, explicit API
- RTX ray tracing support (critical for glass marbles)
- Cross-platform
- C API works directly in Zig

**Decision:** Keep Vulkan ✅

### GLFW ✅ CONFIRMED

**Current:** GLFW 3.x via `@cImport`
**Status:** ✅ Works perfectly with Zig

**Why it's right:**
- Simple, clean C API
- Cross-platform
- Vulkan support
- `@cImport` integration is seamless

**Decision:** Keep GLFW ✅

---

## Build System

### Zig Build System ✅ NEW

**Replaced:** CMake + Makefile + vcpkg

**Why it's better:**
- Single `build.zig` file
- Cross-compilation is trivial
- No external dependencies (vcpkg)
- Declarative and readable

**Build commands:**
```bash
zig build          # Build
zig build run      # Build and run
zig build -Dtarget=x86_64-windows  # Cross-compile
```

**Decision:** Use Zig build system exclusively ✅

---

## Shader Language

### GLSL ✅ CONFIRMED

**Status:** ✅ Correct choice

**Why it's right:**
- Native to Vulkan (compiles to SPIR-V)
- Cross-platform
- Simple toolchain (glslc)
- No Zig equivalent needed - shaders are GPU code

**Decision:** Keep GLSL ✅

---

## Future Libraries to Consider

### Math Library

**Options:**
- **zalgebra** - Zig-native math library (vectors, matrices)
- **zmath** - Part of zig-gamedev, SIMD-optimized
- **Hand-roll** - Simple vec3/mat4 for learning

**Decision:** Start with hand-rolled basics, add zmath if needed

### Image Loading

**Options:**
- **stb_image via @cImport** - Single header, works in Zig
- **zigimg** - Zig-native image loading

**Decision:** Use stb_image via @cImport (simple, proven)

### Audio (Phase 9)

**Options:**
- **miniaudio via @cImport** - Single header, works in Zig
- **zaudio** - Zig-native audio (part of zig-gamedev)

**Decision:** Use miniaudio via @cImport when needed

### UI (Debug)

**Options:**
- **Dear ImGui via cimgui** - C bindings work with @cImport
- **zimgui** - Zig bindings for ImGui

**Decision:** Defer until needed

---

## Zig-Gamedev Ecosystem

Worth watching: [github.com/zig-gamedev](https://github.com/zig-gamedev)

Relevant packages:
- **zphysics** - Jolt Physics bindings
- **zmath** - SIMD math library
- **zvulkan** - Vulkan bindings (we use @cImport instead)
- **zglfw** - GLFW bindings (we use @cImport instead)

We're using `@cImport` directly for now (simpler), but these are available if we need more idiomatic Zig wrappers.

---

## Philosophy Check

**Jonathan Blow's principles still apply:**
- ✅ Use libraries that are **simple and direct**
- ✅ Don't add dependencies until you **need** them
- ✅ Prefer **actively maintained** libraries
- ✅ Avoid **over-engineered** solutions
- ✅ Choose tools that **just work**

**Zig aligns perfectly:**
- No hidden allocations
- Explicit error handling
- No inheritance hierarchies to fight
- Build system that doesn't require a PhD

---

## Decision Log

| Category  | Old Choice     | New Choice        | Reason                  | When        |
| --------- | -------------- | ----------------- | ----------------------- | ----------- |
| Language  | C++17          | Zig 0.13          | Philosophy alignment    | Session 004 |
| Build     | CMake+vcpkg    | Zig build system  | Simpler, cross-compile  | Session 004 |
| Graphics  | Vulkan 1.3     | Vulkan 1.3        | ✅ Keep                 | Session 001 |
| Windowing | GLFW 3.4       | GLFW 3.4          | ✅ Keep                 | Session 001 |
| Shaders   | GLSL           | GLSL              | ✅ Keep                 | Session 002 |
| Physics   | Jolt (planned) | TBD               | Re-evaluate for Zig     | Phase 4     |
| Math      | GLM (planned)  | zmath/hand-roll   | Re-evaluate for Zig     | TBD         |

---

## Installation Commands

### Dependencies

**Linux:**
```bash
# System libraries (same as before)
sudo apt-get install -y \
    libglfw3-dev libvulkan-dev \
    vulkan-tools vulkan-validationlayers-dev

# Install Zig
# Download from https://ziglang.org/download/
# Or use a version manager like zigup
```

**macOS:**
```bash
brew install glfw vulkan-headers vulkan-loader
# Install Zig: brew install zig
# Also install Vulkan SDK from https://vulkan.lunarg.com/
```

**Windows:**
- Install Vulkan SDK from [LunarG](https://vulkan.lunarg.com/)
- Install Zig from [ziglang.org](https://ziglang.org/download/)
- Or cross-compile from Linux: `zig build -Dtarget=x86_64-windows`

---

## References

### Zig Resources
- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig-Gamedev](https://github.com/zig-gamedev) - Game development ecosystem
- [Zig Vulkan Examples](https://github.com/Snektron/vulkan-zig)

### Physics Options
- [zphysics](https://github.com/zig-gamedev/zphysics) - Jolt bindings for Zig
- [JoltC](https://github.com/jrouwe/JoltPhysics/tree/master/Jolt/C) - C API for Jolt

---

**Status:** Zig migration complete. Ready for Phase 2 development.
