# Next Session Quick Reference

**Last Session:** 007 - Transformations (2025-12-05)
**Next Focus:** Phase 5 - More Geometry / Game Content

## Gameplay Vision: Zeni Hajiki

**Target:** Clone of the zeni hajiki minigame from Ghost of Yotei

**Core Mechanic:**
- Aim your marble at targets
- Charge power, release to shoot
- Score by hitting exactly ONE target marble
- First to 6 points wins

**See:** [docs/GAMEPLAY_VISION.md](./GAMEPLAY_VISION.md) for full design

---

## Current Status

### Language & Build System
- **Language:** Zig 0.15.2
- **Build:** `zig build` / `zig build run`
- **Cross-compile:** `zig build -Dtarget=x86_64-windows`

### Code Status (After Session 007)
- ✅ Full Vulkan rendering pipeline
- ✅ GLSL shaders compiled to SPIR-V
- ✅ Graphics pipeline with dynamic viewport/scissor
- ✅ Vertex buffer with triangle data
- ✅ MVP matrix transformations
- ✅ Uniform buffer objects
- ✅ Descriptor sets and pools
- ✅ Time-based rotation animation
- ❌ No textures
- ❌ Only one object (triangle)
- ❌ No depth buffer (no 3D overlap)
- ❌ No input handling

## Session 007 Key Changes

### Added Transformations
- Vec3 struct: sub, cross, dot, normalize
- Mat4 struct: identity, multiply, perspective, lookAt, rotateZ
- UniformBufferObject struct: model, view, proj matrices
- Descriptor set layout for UBO binding
- Uniform buffers (one per frame in flight)
- Descriptor pool and sets
- Time-based rotation in render loop
- Updated vertex shader with MVP transform

**Files changed:**
- src/main.zig (~350 new lines, now 1453 total)
- src/shaders/triangle.vert (added UBO)
- src/shaders/triangle.vert.spv (recompiled)

---

## Next Steps (Phase 5)

**Option A: More Geometry**
1. [ ] Add depth buffer for proper 3D
2. [ ] Render multiple triangles/objects
3. [ ] Push constants for per-object transforms
4. [ ] Basic 3D shapes (cube, quad)
5. [ ] Index buffers

**Option B: Game Content**
1. [ ] Create game table (textured quad)
2. [ ] Render marbles as circles/spheres
3. [ ] Implement aiming line
4. [ ] Basic input handling (gamepad/keyboard)

## Commands Cheat Sheet

### Building
```bash
# Build
zig build

# Build and run
zig build run

# Cross-compile to Windows
zig build -Dtarget=x86_64-windows

# Release build
zig build -Doptimize=ReleaseFast
```

### Shader Compilation
```bash
# Using glslc from Vulkan SDK (if installed)
glslc src/shaders/triangle.vert -o src/shaders/triangle.vert.spv
glslc src/shaders/triangle.frag -o src/shaders/triangle.frag.spv

# Or download from SDK
/tmp/1.3.290.0/x86_64/bin/glslc ...
```

## File Structure
```
bidama_hajiki/
├── src/
│   ├── main.zig              # ~1450 lines
│   └── shaders/
│       ├── triangle.vert     # GLSL vertex shader (with UBO)
│       ├── triangle.frag     # GLSL fragment shader
│       ├── triangle.vert.spv # Compiled SPIR-V
│       └── triangle.frag.spv # Compiled SPIR-V
├── docs/
│   ├── sessions/
│   │   ├── 001-resurrection-and-foundation.md
│   │   ├── 002-cross-platform-build-system.md
│   │   ├── 003-rebranding-and-priorities.md
│   │   ├── 004-zig-migration.md
│   │   ├── 005-core-rendering.md
│   │   ├── 006-triangle-rendering.md
│   │   └── 007-transformations.md
│   ├── NEXT_SESSION.md       # This file
│   ├── GAMEPLAY_VISION.md
│   └── LIBRARY_DECISIONS.md
├── build.zig
├── README.md
└── ROADMAP.md
```

## Code Architecture (Current)

### VulkanState Struct
```zig
const VulkanState = struct {
    // Instance & device
    instance: VkInstance,
    surface: VkSurfaceKHR,
    physical_device: VkPhysicalDevice,
    device: VkDevice,
    graphics_queue: VkQueue,
    present_queue: VkQueue,

    // Swap chain
    swapchain: VkSwapchainKHR,
    swapchain_images: [*]VkImage,
    swapchain_image_views: [*]VkImageView,

    // Rendering
    render_pass: VkRenderPass,
    framebuffers: [*]VkFramebuffer,
    command_pool: VkCommandPool,
    command_buffers: [*]VkCommandBuffer,

    // Sync
    image_available_semaphores: [*]VkSemaphore,
    render_finished_semaphores: [*]VkSemaphore,
    in_flight_fences: [*]VkFence,

    // Graphics pipeline
    pipeline_layout: VkPipelineLayout,
    graphics_pipeline: VkPipeline,

    // Geometry
    vertex_buffer: VkBuffer,
    vertex_buffer_memory: VkDeviceMemory,

    // Uniform buffers (per frame)
    uniform_buffers: [*]VkBuffer,
    uniform_buffers_memory: [*]VkDeviceMemory,
    uniform_buffers_mapped: [*]?*anyopaque,

    // Descriptors
    descriptor_set_layout: VkDescriptorSetLayout,
    descriptor_pool: VkDescriptorPool,
    descriptor_sets: [*]VkDescriptorSet,
};
```

### Math Types
```zig
const Vec3 = struct {
    x: f32 = 0, y: f32 = 0, z: f32 = 0,
    fn sub(a: Vec3, b: Vec3) Vec3 { ... }
    fn cross(a: Vec3, b: Vec3) Vec3 { ... }
    fn dot(a: Vec3, b: Vec3) f32 { ... }
    fn normalize(v: Vec3) Vec3 { ... }
};

const Mat4 = struct {
    data: [16]f32,
    fn identity() Mat4 { ... }
    fn multiply(a: Mat4, b: Mat4) Mat4 { ... }
    fn perspective(fov, aspect, near, far) Mat4 { ... }
    fn lookAt(eye, center, up) Mat4 { ... }
    fn rotateZ(angle) Mat4 { ... }
};

const UniformBufferObject = struct {
    model: Mat4,
    view: Mat4,
    proj: Mat4,
};
```

### Vertex Format
```zig
const Vertex = struct {
    pos: [2]f32,  // 2D position
    // TODO: Add for next phase
    // color: [3]f32,
    // texCoord: [2]f32,
};
```

## Philosophy Reminders

From ROADMAP.md:
- **Zig's philosophy aligns** - simple, explicit, no hidden control flow
- **Structs and functions** - no class hierarchies
- **No premature abstraction** - wait until we have 3+ examples
- **Write shaders from scratch** - understand every line
- **Simple, direct code** - if it's confusing, simplify it

## Session History

### Session 007 (2025-12-05): Transformations
- Added Vec3 and Mat4 math utilities
- Added uniform buffer objects for MVP matrices
- Added descriptor sets and pools
- Updated vertex shader with UBO
- Triangle now rotates around Z-axis

### Session 006 (2025-12-04): Triangle Rendering
- Created GLSL vertex and fragment shaders
- Compiled shaders to SPIR-V
- Implemented full graphics pipeline
- Created vertex buffer with triangle data
- Triangle now visible on dark blue background

### Session 005 (2025-12-04): Core Rendering
- Implemented complete Vulkan rendering pipeline
- Added logical device, swap chain, render pass, framebuffers
- Added command pool/buffers and sync objects
- Window now clears to dark blue

### Session 004 (2025-12-03): Migration to Zig
- Switched from C++ to Zig
- Replaced CMake/vcpkg/Makefile with Zig build system
- Ported main.cpp to main.zig

### Earlier Sessions
- Session 003: Rebranding to Bidama Hajiki
- Session 002: Cross-platform build system
- Session 001: Project resurrection

---

## Quick Health Check

```bash
# Build and verify
zig build

# Test run (3 second timeout in WSL2)
timeout 3 ./zig-out/bin/bidama_hajiki; echo "Exit: $?"
# Expected: Exit: 124 (timeout = running correctly)

# Check git status
git status --short
```

## Session 008 Goals

**Primary:** Add more geometry OR start game content

**Option A - More Geometry:**
1. Add depth buffer
2. Render multiple objects
3. Push constants for per-object transforms
4. Index buffers for efficient rendering

**Option B - Game Content:**
1. Create table surface
2. Render marble sprites/circles
3. Implement aim indicator
4. Handle gamepad/keyboard input

**Success criteria:**
- Multiple objects on screen, OR
- Game table visible with marble(s)
- No validation errors
- Code remains simple

---

**Ready for more geometry or game content!**
