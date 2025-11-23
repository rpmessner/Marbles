# Session 002: Cross-Platform Build System

**Date:** 2025-11-22
**Duration:** Extended setup session
**Status:** ✅ Complete

## Overview

Established a complete cross-platform build system that can compile for Windows, Linux, and (future) macOS from a single WSL2 Ubuntu environment. The key insight: use MinGW-w64 to cross-compile Windows executables directly from Linux, avoiding the need for a separate Windows development environment.

## Problem Statement

The user is developing in WSL2 (Ubuntu 24) but wants to:
- Test the game on **native Windows** (better GPU access)
- Maintain build targets for **Linux** (for development/debugging)
- Keep support for **macOS** (future-proofing)
- Fix **LSP errors** in nvim (needs proper compile_commands.json)

## Solution: Cross-Compilation

Instead of maintaining separate Windows and Linux development environments, we set up cross-compilation:
- **Build FROM:** WSL2 Ubuntu
- **Build TO:** Windows x64, Linux x64, (future) macOS
- **Tools:** MinGW-w64, vcpkg, CMake

## Technical Implementation

### 1. MinGW-w64 Cross-Compiler

Installed the MinGW-w64 toolchain for cross-compiling to Windows:

```bash
sudo apt-get install -y mingw-w64 cmake build-essential pkg-config
```

This gives us:
- `x86_64-w64-mingw32-gcc` - C compiler for Windows
- `x86_64-w64-mingw32-g++` - C++ compiler for Windows
- Full Windows SDK without needing Windows

### 2. vcpkg for Windows Dependencies

Cloned and bootstrapped vcpkg for Windows library management:

```bash
git clone https://github.com/Microsoft/vcpkg.git
./vcpkg/bootstrap-vcpkg.sh
./vcpkg/vcpkg install glfw3:x64-mingw-dynamic vulkan:x64-mingw-dynamic ode:x64-mingw-dynamic
```

**Why vcpkg?**
- Handles Windows dependencies cleanly
- Works great with CMake
- Cross-compilation support
- Consistent with modern C++ practices

**Packages installed:**
- `glfw3:x64-mingw-dynamic` - Windowing library
- `vulkan:x64-mingw-dynamic` - Vulkan headers and loader
- `ode:x64-mingw-dynamic` - Physics engine
- Plus dependencies (vulkan-headers, vulkan-loader, etc.)

Total install time: 44 seconds

### 3. CMake Configuration Updates

Updated `CMakeLists.txt` to handle both Linux and Windows builds:

**Key changes:**

```cmake
# Detect platform and use appropriate package finder
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # For Windows cross-compilation via vcpkg
    find_package(ode CONFIG REQUIRED)
    set(ODE_LIBRARIES ODE::ODE)
else()
    # For Linux/macOS via pkg-config
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(ODE REQUIRED ode)
endif()
```

This allows CMake to:
- Use vcpkg's CMake targets for Windows
- Use pkg-config for native Linux/macOS
- Handle include paths automatically per platform

### 4. Build Scripts

Created platform-specific build scripts:

**build-windows.sh:**
```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SCRIPT_DIR/build-windows"
cd "$SCRIPT_DIR/build-windows"

cmake "$SCRIPT_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="$SCRIPT_DIR/vcpkg/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_TARGET_TRIPLET=x64-mingw-dynamic \
    -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
    -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_BUILD_TYPE=Release

cmake --build . --config Release
```

**build-linux.sh:**
```bash
#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SCRIPT_DIR/build-linux"
cd "$SCRIPT_DIR/build-linux"

cmake "$SCRIPT_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

**Philosophy:** Simple, direct scripts that "just work" - no complex build system magic.

### 5. LSP Configuration

The LSP (Language Server Protocol) in nvim needs `compile_commands.json` to understand include paths and compiler flags.

**Solution:**
- CMake generates `compile_commands.json` in each build directory
- Symlinked to project root: `compile_commands.json → build-linux/compile_commands.json`
- LSP now has full context about the codebase

```bash
ln -sf build-linux/compile_commands.json /path/to/Marbles/compile_commands.json
```

**Why build-linux, not build-windows?**
- LSP runs in the Linux environment (WSL2)
- Needs Linux include paths, not MinGW paths
- Windows cross-compilation uses different headers

### 6. Updated .gitignore

Ensured proper files are ignored:

```gitignore
# Build directories
build/
build-*/
cmake-build-*/

# vcpkg package manager
vcpkg/
!vcpkg.json
```

## Results

### Build Outputs

**Linux build:**
```
build-linux/marbles (17k)
- Native Linux executable
- For development and debugging in WSL2
- Can run if Vulkan drivers are available
```

**Windows build:**
```
build-windows/marbles.exe (257k)
- PE32+ executable (console) x86-64
- For MS Windows
- Runs on native Windows with GPU access
- Includes required DLLs in vcpkg/installed/x64-mingw-dynamic/bin/
```

**Verification:**
```bash
$ file build-linux/marbles
build-linux/marbles: ELF 64-bit LSB pie executable, x86-64

$ file build-windows/marbles.exe
build-windows/marbles.exe: PE32+ executable (console) x86-64, for MS Windows
```

### Build Commands

**To build for Windows:**
```bash
./build-windows.sh
```

**To build for Linux:**
```bash
./build-linux.sh
```

**To rebuild both:**
```bash
./build-linux.sh && ./build-windows.sh
```

## Shader Language Decision: GLSL

Discussed GLSL vs HLSL for shader programming.

**Decision: GLSL**

**Reasons:**
- Native to Vulkan (compiles directly to SPIR-V)
- Cross-platform (Linux, Mac, Windows)
- Simpler toolchain (glslc comes with Vulkan SDK)
- Better documentation and tutorials for Vulkan
- Already mentioned in README.md
- Aligns with Jonathan Blow philosophy: simple and direct

**GLSL criticisms acknowledged:**
- Dated syntax (based on C from early 2000s)
- Weaker tooling compared to HLSL
- No proper module system (just preprocessor)
- Fragmentation (GLSL versions, vendor differences)

**Why AAA studios often prefer alternatives:**
- HLSL: Better debugging (PIX), modern features
- Custom shader languages: Unity, Unreal, Naughty Dog
- Shader graphs: For non-programmers

**Our take:**
Following Blow's philosophy: "Don't solve problems you don't have yet." GLSL is the direct, simple solution for Vulkan. If it becomes limiting later, we can switch. But for learning Vulkan and ray tracing from first principles, GLSL maps directly to concepts with no translation layer.

## Dependencies Summary

### Linux (WSL2)
```bash
sudo apt-get install -y \
    mingw-w64 \
    cmake \
    build-essential \
    pkg-config \
    libglfw3-dev \
    libvulkan-dev \
    libode-dev
```

### Windows (via vcpkg)
```bash
./vcpkg/vcpkg install \
    glfw3:x64-mingw-dynamic \
    vulkan:x64-mingw-dynamic \
    ode:x64-mingw-dynamic
```

## Lessons Learned

### Cross-Compilation Insights

1. **MinGW-w64 is powerful** - Build Windows executables without Windows
2. **vcpkg simplifies Windows dependencies** - No manual DLL hunting
3. **CMake can handle complexity** - When used judiciously
4. **Separate build directories keep things clean** - No cross-contamination

### LSP Configuration

1. **compile_commands.json is essential** - LSP can't work without it
2. **Symlink to Linux build** - LSP runs in native environment
3. **CMake generates it automatically** - With `CMAKE_EXPORT_COMPILE_COMMANDS ON`

### Build System Philosophy

Despite adding complexity (vcpkg, CMake), we maintained simplicity:
- **One command per platform** - `./build-windows.sh` or `./build-linux.sh`
- **Scripts are self-contained** - No manual configuration needed
- **Clear separation** - build-windows/ vs build-linux/ vs vcpkg/
- **Git-friendly** - All build artifacts ignored

## Challenges Encountered

### 1. Line Endings (CRLF vs LF)

**Problem:** Scripts created on Windows had CRLF line endings
**Error:** `bad interpreter: /bin/bash^M`
**Solution:** `sed -i 's/\r$//' script.sh`

### 2. ODE Library Detection

**Problem:** pkg-config found Linux ODE when cross-compiling
**Solution:** Platform-specific library detection in CMakeLists.txt

### 3. vcpkg Warnings

**Warning:** "DLLs that link with obsolete C RunTime"
**Impact:** None for our use case (MinGW DLLs work fine)
**Action:** Acknowledged, no changes needed

## Current Status

### What Works ✅
- Cross-compilation to Windows from Linux
- Native Linux builds for development
- LSP fully configured with proper compile commands
- Separate build directories per platform
- Simple one-command builds per platform
- vcpkg managing Windows dependencies
- CMake handling platform differences

### Ready for Next Session
- Phase 2: Core Rendering (logical device, queues, swap chain)
- Write first GLSL shaders (Phase 3)
- Everything builds cleanly on both platforms
- Development environment is solid

## Files Modified/Created

### Created
- `vcpkg/` (cloned, added to .gitignore)
- `build-windows.sh`
- `build-linux.sh`
- `cmake/toolchain-mingw-w64.cmake` (created but not used - vcpkg's toolchain preferred)
- `compile_commands.json` (symlink to build-linux/)
- `docs/sessions/002-cross-platform-build-system.md` (this file)

### Modified
- `CMakeLists.txt` - Platform-specific ODE detection
- `.gitignore` - Added build-*/ and vcpkg/ exclusions

### Build Outputs
- `build-linux/marbles` (17k, ELF 64-bit)
- `build-windows/marbles.exe` (257k, PE32+)
- `build-linux/compile_commands.json`
- `build-windows/compile_commands.json`

## Code Statistics

**Build system complexity:**
- Build scripts: 2 files, ~50 lines total
- CMake updates: ~30 lines added
- vcpkg dependencies: 3 packages, 7 total with transitive deps
- Build time: <5 seconds per platform
- Total setup time: ~10 minutes (including vcpkg downloads)

**Philosophy check:**
- Still following "simple and direct"? ✅ Yes
- Solving today's problems? ✅ Yes (need Windows builds now)
- Premature optimization? ❌ No (need cross-platform now)
- Over-engineered? ❌ No (minimal abstraction, clear scripts)

## Running the Game

### On Linux (WSL2)
```bash
./build-linux/marbles
# Note: Requires Vulkan drivers in WSL2
```

### On Windows
```bash
# From WSL2, copy to Windows:
cp build-windows/marbles.exe /mnt/c/Users/YourName/Desktop/
cp vcpkg/installed/x64-mingw-dynamic/bin/*.dll /mnt/c/Users/YourName/Desktop/

# Then run on Windows side:
# Double-click marbles.exe or run from cmd.exe
```

**Required DLLs for Windows:**
- `glfw3.dll`
- `libode_double.dll`
- `vulkan-1.dll`

All located in `vcpkg/installed/x64-mingw-dynamic/bin/`

## References

### Cross-Compilation
- MinGW-w64 documentation
- vcpkg documentation: https://vcpkg.io/
- CMake cross-compiling: https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html

### LSP Configuration
- clangd compile_commands.json spec
- Language Server Protocol documentation

### Shader Languages
- GLSL specification
- Vulkan SPIR-V integration
- Jonathan Blow's talks on shader systems

## Next Session Prep

Before Session 003:
1. Test Windows build on native Windows ✅ (user confirmed)
2. Verify LSP errors are gone in nvim ✅ (user confirmed)
3. Read Vulkan Tutorial - Logical Device section
4. Read Vulkan Tutorial - Swap Chain section
5. Prepare to write first real Vulkan rendering code

## Reflections

This session was about **infrastructure done right**. We added complexity (vcpkg, cross-compilation), but:
- It solves a real problem (need Windows builds now)
- It's transparent (simple scripts, clear separation)
- It's maintainable (all automated, well-documented)
- It follows the philosophy (direct, understandable)

The key insight: **Cross-compilation eliminates environment juggling**. One development environment (WSL2), multiple build targets. The user can code in their preferred Linux setup while still targeting Windows for GPU testing.

This is the kind of upfront investment that pays off: we can now iterate rapidly on both platforms without context switching.

## End of Session

**Outcome:** ✅ Success - Cross-platform builds working
**Mood:** 🚀 Ready to write real rendering code
**Next Session:** Vulkan logical device, swap chain, and first pixels!

---

**Build targets verified:**
- ✅ Linux: 17k ELF executable
- ✅ Windows: 257k PE32+ executable
- ✅ LSP: compile_commands.json configured
- ✅ Ready for Phase 2 development
