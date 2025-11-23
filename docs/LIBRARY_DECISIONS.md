# Library Decisions & Modern Alternatives

**Last Updated:** 2025-11-22 (Session 002)
**Status:** Under Review - Considering Modern Alternatives

## Critical Decision: Physics Engine

### Current Choice: ODE (Open Dynamics Engine)
**Version:** 0.16.x
**Last major update:** ~2019
**License:** BSD/LGPL

**Why we initially chose it:**
- Used in original 2004 project
- Available via vcpkg
- Works

**Problems:**
- ❌ **OLD** - Last major development ~2019
- ❌ Limited multi-core support
- ❌ Dated API design
- ❌ Smaller community
- ❌ Not used in modern AAA games

### ⭐ RECOMMENDED: Jolt Physics

**Why Jolt is Better:**
- ✅ **Modern** - Actively developed (2024 updates)
- ✅ **AAA Proven** - Used in Horizon Forbidden West
- ✅ **Multi-core optimized** - Scales with CPU cores
- ✅ **MIT License** - Very permissive
- ✅ **C++17** - Matches our codebase
- ✅ **Excellent documentation** - Worth reading just to learn
- ✅ **vcpkg support** - `vcpkg install joltphysics`
- ✅ **Active development** - v5.2.0 released Nov 2024
- ✅ **Fast** - Outperforms ODE and Bullet in benchmarks
- ✅ **Perfect for marbles** - Excellent sphere collision and rolling physics

**vcpkg Installation:**
```bash
vcpkg install joltphysics:x64-mingw-dynamic  # Windows
vcpkg install joltphysics                     # Linux/macOS
```

**Features available:**
- `[core]` - Base physics engine
- `[debugrenderer]` - Debug visualization
- `[profiler]` - Performance profiling

**Latest versions (2024):**
- v5.2.0 (Nov 27, 2024)
- v5.1.0 (Aug 19, 2024)
- v5.0.0 (Apr 5, 2024)

**Key advantages for our project:**
- Better sphere-sphere collision handling
- More accurate friction models (critical for marble rolling)
- Better performance (though not critical for our scale)
- Modern C++ API (easier to work with)
- Actively maintained (won't be abandoned)

### Alternative: Bullet Physics

**Pros:**
- Mature and battle-tested
- Used in many games (Godot 3, etc.)
- Good documentation
- Available in vcpkg

**Cons:**
- C++ 2003 API (dated)
- Not as fast as Jolt
- Less active development than Jolt

### Alternative: PhysX (NVIDIA)

**Pros:**
- Industry standard (Unreal, Unity)
- Best angular stability
- Now open source (v4, v5)
- Available in vcpkg

**Cons:**
- NVIDIA-centric (though works everywhere)
- More complex than needed for marbles
- Heavier weight

### **DECISION:** Switch to Jolt Physics ✅

**When:** Before Phase 4 (Physics Integration)
**Why:** Modern, fast, actively developed, perfect for our use case
**Risk:** Low - better in every way than ODE

---

## Graphics & Windowing Libraries

### Vulkan ✅ CONFIRMED
**Current:** Vulkan 1.3
**Status:** ✅ Correct choice

**Why it's right:**
- Modern, explicit API
- RTX ray tracing support (critical for glass marbles)
- Cross-platform
- Industry standard for modern games
- Excellent documentation

**Alternatives considered:**
- OpenGL - ❌ Too old, no RTX
- DirectX 12 - ❌ Windows-only
- Metal - ❌ macOS-only

**Decision:** Keep Vulkan ✅

### GLFW ✅ CONFIRMED
**Current:** GLFW 3.4
**Status:** ✅ Correct choice

**Why it's right:**
- Simple, clean API
- Cross-platform (Windows, Linux, macOS)
- Vulkan support
- Actively maintained
- Widely used

**Alternatives:**
- SDL2 - More features, but heavier
- Custom platform layer - Unnecessary complexity

**Decision:** Keep GLFW ✅

---

## Build System & Package Management

### vcpkg ✅ CONFIRMED (for Windows)
**Status:** ✅ Correct choice for cross-compilation

**Why it's right:**
- Official Microsoft package manager
- Excellent CMake integration
- Cross-compilation support (MinGW)
- Well-maintained
- Growing package ecosystem

**For our setup:**
- Windows deps: vcpkg
- Linux deps: System package manager (apt)
- macOS deps: Homebrew

**Decision:** Keep vcpkg for Windows ✅

### CMake ✅ CONFIRMED
**Current:** CMake 3.20+
**Status:** ✅ Correct choice

**Why it's right:**
- Industry standard
- Cross-platform
- Excellent vcpkg integration
- Generates compile_commands.json (LSP support)

**We also have:** Simple Makefile (alternative)

**Decision:** Keep both CMake + Makefile ✅

---

## Compiler & Toolchain

### Current Setup ✅ CONFIRMED
- **Linux:** GCC 13.3 / Clang
- **Windows:** MinGW-w64 (x86_64-w64-mingw32-g++ 13.0)
- **C++ Standard:** C++17

**Status:** ✅ Good choices

**Considerations:**
- C++20? - Not needed yet, C++17 is fine
- Clang everywhere? - GCC is working fine
- MSVC for Windows? - MinGW cross-compilation is cleaner

**Decision:** Keep current setup ✅

---

## Shader Language

### GLSL ✅ CONFIRMED
**Status:** ✅ Correct choice

**Why it's right:**
- Native to Vulkan (compiles to SPIR-V)
- Cross-platform
- Simple toolchain (glslc)
- Matches project philosophy (simple, direct)

**Alternatives:**
- HLSL - More tooling, but unnecessary
- Slang - Overkill for this project

**Decision:** Keep GLSL ✅

---

## Future Libraries to Consider

### Asset Loading (When Needed)

**For 3D models (if we need complex marble designs):**
- **Assimp** - Full-featured, might be overkill
- **tinyobjloader** - Lightweight OBJ loader
- **cgltf** - glTF 2.0 loader (modern format)

**Decision:** Defer until Phase 8 (Marble Artistry)

### Image Loading (For Textures)

**Options:**
- **stb_image.h** - Single-header, simple ✅ Recommended
- **SOIL2** - More features
- **DevIL** - Kitchen sink

**Decision:** Use stb_image when needed (Phase 6+)

### Audio (Phase 9: Polish)

**For marble collision sounds:**
- **miniaudio** - Single-header, cross-platform ✅ Recommended
- **OpenAL** - More complex, full 3D audio
- **FMOD** - Commercial option (was in old codebase)

**Decision:** Use miniaudio when we get to Phase 9

### Math Library

**Current:** Using Vulkan's math for now

**Options:**
- **GLM** - Popular, header-only, GLSL-like ✅ Recommended
- **Eigen** - More complex, overkill
- **DirectXMath** - Windows-focused

**Decision:** Add GLM when we need more math (Phase 2-3)

### UI (Far Future)

**For menus, HUDs:**
- **Dear ImGui** - Immediate mode, perfect for debug UI ✅ Recommended
- **Nuklear** - Single-header alternative
- **Custom** - For final game UI

**Decision:** ImGui for debug, defer final UI decisions

---

## Summary of Changes Needed

### High Priority (Before Phase 4)
1. ✅ **Switch ODE → Jolt Physics**
   - Better performance
   - Modern API
   - Active development
   - Perfect for marbles

### Medium Priority (Phase 2-3)
2. **Add GLM** for math utilities
   - Header-only
   - Easy integration
   - GLSL-like syntax

### Low Priority (Phase 6+)
3. **Add stb_image.h** for texture loading
4. **Add Dear ImGui** for debug UI

### Future (Phase 9+)
5. **Add miniaudio** for sound effects

---

## Installation Commands

### Updated Dependencies

**Linux (native build):**
```bash
sudo apt-get install -y \
    cmake build-essential pkg-config \
    libglfw3-dev libvulkan-dev \
    # Remove: libode-dev
    # Jolt will be built from source or vcpkg
```

**Windows (via vcpkg):**
```bash
./vcpkg/vcpkg install \
    glfw3:x64-mingw-dynamic \
    vulkan:x64-mingw-dynamic \
    joltphysics:x64-mingw-dynamic
    # Removed: ode:x64-mingw-dynamic
```

**Optional additions:**
```bash
# For development
./vcpkg/vcpkg install \
    joltphysics[debugrenderer,profiler]:x64-mingw-dynamic \
    glm:x64-mingw-dynamic
```

---

## Philosophy Check

**Jonathan Blow's principles still apply:**
- ✅ Use libraries that are **simple and direct**
- ✅ Don't add dependencies until you **need** them
- ✅ Prefer **actively maintained** libraries
- ✅ Avoid **over-engineered** solutions
- ✅ Choose tools that **just work**

**Changes align with philosophy:**
- Jolt: Modern, well-documented, just works ✅
- Removing dependencies we don't need yet ✅
- Keeping build system simple ✅

---

## Migration Plan: ODE → Jolt

**When to do it:** During Session 003 or before starting Phase 4

**Steps:**
1. Update vcpkg dependencies
2. Update CMakeLists.txt to find Jolt instead of ODE
3. Remove ODE initialization code from main.cpp
4. Add Jolt initialization (when we get to Phase 4)
5. Test builds on both platforms

**Estimated time:** 15-30 minutes
**Risk:** Very low (haven't written ODE code yet)

**Advantage:** Do it NOW before we write physics code

---

## References

### Jolt Physics
- [Jolt Physics GitHub](https://github.com/jrouwe/JoltPhysics)
- [Jolt vcpkg Package](https://vcpkg.io/en/package/joltphysics)
- [Jolt Documentation](https://jrouwe.github.io/JoltPhysics/)
- [Building and Using Jolt](https://jrouwe.github.io/JoltPhysics/md__build_2_r_e_a_d_m_e.html)

### Physics Engine Comparisons
- [Open Source Physics Engines List](https://www.tapiorgames.com/blog/open-source-physics-engines)
- [Best 3D Physics Engines 2025](https://www.slant.co/topics/6628/~3d-physics-engines)
- [Physics Engine Performance Comparison](https://www.researchgate.net/figure/Performance-comparison-of-three-popular-physics-engines-PhysX-Bullet-and-ODE-performed_fig2_258226292)
- [Jolt Physics Raylib Tutorial](https://rodneylab.com/jolt-physics-raylib/)

### vcpkg Resources
- [joltphysics vcpkg Versions](https://vcpkg.link/ports/joltphysics/versions)
- [Jolt vcpkg Port Info](https://vcpkg.roundtrip.dev/ports/joltphysics)

---

## Decision Log

| Library | Old Choice | New Choice | Reason | When |
|---------|-----------|------------|--------|------|
| Physics | ODE 0.16 | Jolt 5.2+ | Modern, faster, AAA-proven | Session 002 |
| Graphics | Vulkan 1.3 | Vulkan 1.3 | ✅ Keep | Session 001 |
| Windowing | GLFW 3.4 | GLFW 3.4 | ✅ Keep | Session 001 |
| Shaders | GLSL | GLSL | ✅ Keep | Session 002 |
| Build | CMake+Make | CMake+Make | ✅ Keep | Session 001 |
| Packages | vcpkg | vcpkg | ✅ Keep | Session 002 |
| Math | (none) | GLM (future) | When needed | TBD |
| Images | (none) | stb_image (future) | When needed | TBD |
| Audio | (none) | miniaudio (future) | When needed | TBD |
| UI | (none) | ImGui (future) | When needed | TBD |

---

**Status:** Ready to migrate ODE → Jolt Physics
**Next Action:** Update dependencies and CMakeLists.txt in Session 003
