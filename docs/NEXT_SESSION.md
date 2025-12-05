# Next Session Quick Reference

**Last Session:** 006 - Triangle Rendering (2025-12-04)
**Next Focus:** Phase 4 - Transformations / Game Content

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

### Code Status (After Session 006)
- ✅ Full Vulkan rendering pipeline
- ✅ GLSL shaders compiled to SPIR-V
- ✅ Graphics pipeline with dynamic viewport/scissor
- ✅ Vertex buffer with triangle data
- ✅ Draw call - triangle renders on screen!
- ❌ No transformations (everything in NDC)
- ❌ No uniform buffers
- ❌ No textures
- ❌ No 3D yet

## Session 006 Key Changes

### Added Triangle Rendering
- Created vertex and fragment shaders in GLSL
- Compiled to SPIR-V using glslc from Vulkan SDK
- Embedded shaders at compile time with @embedFile
- Implemented full graphics pipeline:
  - Shader stages
  - Vertex input (position only)
  - Input assembly (triangle list)
  - Viewport/scissor (dynamic)
  - Rasterizer (fill mode)
  - Color blending (no blend)
- Created vertex buffer with host-visible memory
- Updated recordCommandBuffer with draw call

**Files added:**
- src/shaders/triangle.vert
- src/shaders/triangle.frag
- src/shaders/triangle.vert.spv
- src/shaders/triangle.frag.spv

---

## Next Steps (Phase 4: Transformations)

**Option A: Graphics Fundamentals**
1. [ ] Add uniform buffer for MVP matrix
2. [ ] Implement basic camera (view matrix)
3. [ ] Add projection matrix (perspective or ortho)
4. [ ] Render multiple objects
5. [ ] Basic 3D shapes

**Option B: Game Content**
1. [ ] Create game table mesh
2. [ ] Render marbles as circles/spheres
3. [ ] Implement aiming line
4. [ ] Basic input handling

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
│   ├── main.zig              # ~1100 lines
│   └── shaders/
│       ├── triangle.vert     # GLSL vertex shader
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
│   │   └── 006-triangle-rendering.md
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

    // TODO: Add for transformations
    // uniform_buffers: [*]VkBuffer,
    // uniform_buffers_memory: [*]VkDeviceMemory,
    // descriptor_pool: VkDescriptorPool,
    // descriptor_sets: [*]VkDescriptorSet,
};
```

### Vertex Format
```zig
const Vertex = struct {
    pos: [2]f32,  // 2D position in NDC
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

## Resources for Next Session

### Vulkan Tutorial Sections
1. Uniform buffers: https://vulkan-tutorial.com/Uniform_buffers
2. Descriptor sets: https://vulkan-tutorial.com/Uniform_buffers/Descriptor_layout_and_buffer
3. 3D rendering: https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Rendering_and_presentation

### Math Resources
- GLM-style math for Zig: Consider zlm or implement simple mat4/vec3
- MVP matrix calculation
- Perspective vs orthographic projection

## Session History

### Session 006 (2025-12-04): Triangle Rendering
- Created GLSL vertex and fragment shaders
- Compiled shaders to SPIR-V
- Implemented full graphics pipeline
- Created vertex buffer with triangle data
- Updated render loop with draw call
- Triangle now visible on dark blue background

### Session 005 (2025-12-04): Core Rendering
- Implemented complete Vulkan rendering pipeline
- Added logical device, swap chain, render pass, framebuffers
- Added command pool/buffers and sync objects
- Implemented drawFrame() render loop
- Updated for Zig 0.15.2 compatibility
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

## Session 007 Goals

**Primary:** Add transformations OR start game content

**Option A - Transformations:**
1. Implement mat4/vec3 math
2. Add uniform buffer for MVP matrix
3. Move triangle with model matrix
4. Add basic camera

**Option B - Game Content:**
1. Create table surface
2. Render marble sprites/circles
3. Implement aim indicator
4. Handle controller input

**Success criteria:**
- Multiple objects on screen, OR
- Game table visible
- No validation errors
- Code remains simple

---

**Ready for transformations or game content!**
