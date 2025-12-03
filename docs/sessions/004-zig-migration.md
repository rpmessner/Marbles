# Session 004: Migration to Zig

**Date:** 2025-12-03
**Duration:** ~1 hour
**Status:** ✅ Complete

## Overview

Migrated the entire project from C++ to Zig. This was a significant architectural decision driven by the realization that we were fighting C++ to write simple, direct code - exactly what Zig is designed for.

## Goals

- [x] Evaluate switching to Zig
- [x] Install Zig 0.13.0
- [x] Create Zig build system (build.zig)
- [x] Port main.cpp to main.zig
- [x] Verify build works
- [x] Remove C++ build artifacts
- [x] Update all documentation

## The Decision

### Why We Switched

We were writing "C-style code in C++" - avoiding classes, RAII, exceptions, templates. We were essentially fighting the language to stay simple.

**The C++ paradox:**
```cpp
// What we wanted to write
struct VulkanState { ... };
static bool create_instance(VulkanState* vk);

// What C++ kept tempting us toward
class VulkanRenderer {
    VkInstance instance;
public:
    VulkanRenderer();
    ~VulkanRenderer();
};
```

**Zig solves this:**
- Built for simple, explicit code
- No hidden control flow (no exceptions, no hidden allocations)
- Excellent C interop via `@cImport`
- Built-in build system replaces CMake + vcpkg + Makefiles
- Trivial cross-compilation

### Why Now?

- Only 204 lines of code to port
- No deep dependencies on C++ features
- Early enough to change direction without pain
- Learning value: Zig + Vulkan instead of just Vulkan

## What We Built

### build.zig (30 lines)
Replaced:
- CMakeLists.txt
- Makefile
- build-linux.sh
- build-windows.sh
- setup.sh
- vcpkg/ (500MB+ of dependencies)

With a single 30-line file:
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "bidama_hajiki",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("vulkan");
    exe.linkLibC();

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}
```

### src/main.zig (~180 lines)

Direct port of main.cpp to idiomatic Zig:
- Same VulkanState struct
- Same initialization flow
- Same cleanup logic
- Zig-native error handling patterns

Key translation patterns:
- `VkSomething info = {}` → `var info = std.mem.zeroes(c.VkSomething)`
- `malloc/free` → `std.heap.c_allocator.alloc/free`
- `fprintf(stderr, ...)` → `std.debug.print(...)`
- Callbacks need `callconv(.C)`

## Technical Decisions

### @cImport vs Zig Wrappers

We chose direct `@cImport` over existing Zig wrappers (zvulkan, zglfw) because:
1. Simpler - fewer dependencies
2. Tutorials translate directly - all Vulkan docs are C/C++
3. We control everything - no abstraction layers to debug
4. Can add wrappers later if needed

### Memory Allocation

Using `std.heap.c_allocator` for now because:
1. Matches C/Vulkan conventions
2. Simple to understand
3. Can switch to a proper allocator later if needed

### Error Handling

Using `bool` returns with error printing (same as C++ version):
```zig
fn createVulkanInstance(vk: *VulkanState) bool {
    // ...
    if (result != c.VK_SUCCESS) {
        std.debug.print("Failed: {d}\n", .{result});
        return false;
    }
    return true;
}
```

Could switch to Zig error unions later, but keeping it simple for now.

## Challenges & Solutions

### Challenge: Installing Zig in WSL2 without sudo
**Solution:** Local installation to ~/zig-linux-x86_64-0.13.0, added to PATH

### Challenge: Translating C callbacks to Zig
**Solution:** Use `callconv(.C)` for GLFW callbacks:
```zig
fn keyCallback(window: ?*c.GLFWwindow, key: c_int, ...) callconv(.C) void {
```

### Challenge: Vulkan struct initialization
**Solution:** `std.mem.zeroes()` for zero-initialization, then set fields

### Challenge: Pointer casting for device name
**Solution:** `@ptrCast` with sentinel type:
```zig
const device_name: [*:0]const u8 = @ptrCast(&properties.deviceName);
```

## Code Statistics

**Before:**
- src/main.cpp: 204 lines
- CMakeLists.txt: 42 lines
- Makefile: 25 lines
- build-linux.sh: 15 lines
- build-windows.sh: 30 lines
- setup.sh: 35 lines
- vcpkg/: ~500MB

**After:**
- src/main.zig: 178 lines
- build.zig: 30 lines
- Total: 208 lines (down from 351 lines + 500MB)

**Files removed:**
- CMakeLists.txt
- Makefile
- build-linux.sh
- build-windows.sh
- setup.sh
- src/main.cpp
- cmake/ directory
- vcpkg/ directory (~500MB freed)
- build/, build-linux/, build-windows/

## Lessons Learned

1. **Timing matters** - Switching languages at 200 lines is trivial. At 2000 lines it would be painful.

2. **Philosophy alignment matters more than language features** - We weren't using C++ features anyway. Zig's philosophy of "no hidden control flow" matches what we were trying to achieve.

3. **Build systems are underrated** - Zig's build system alone justifies the switch. No more CMake + vcpkg + Makefile + shell scripts.

4. **@cImport is magical** - Vulkan and GLFW "just work" with no binding generation.

5. **Learning multiplier** - Now learning Zig AND graphics programming simultaneously.

## Documentation Updated

- README.md - Updated for Zig
- ROADMAP.md - Updated Phase 1, philosophy
- docs/LIBRARY_DECISIONS.md - Complete rewrite for Zig
- docs/NEXT_SESSION.md - Updated for Zig workflow
- docs/phase2-rendering-guide.md - Rewritten with Zig code
- docs/sessions/README.md - Added session 004
- .gitignore - Updated for Zig output directories

## Next Session

**Focus:** Phase 2 - Core Rendering

**Goals:**
1. Create logical device and queues
2. Set up swap chain
3. Implement render pass and framebuffers
4. Create command buffers
5. Clear screen to a color

**Success criteria:**
- Window shows solid color (not black)
- No Vulkan validation errors
- Clean ESC shutdown

## References

- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig-Gamedev Ecosystem](https://github.com/zig-gamedev)
- [Vulkan Tutorial](https://vulkan-tutorial.com/)

---

**Key Takeaway:** When you find yourself fighting a language to write simple code, consider whether you're using the right language. Zig is designed for the exact programming style we wanted.
