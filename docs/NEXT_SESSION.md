# Next Session Quick Reference

**Last Session:** 005 - Core Rendering (2025-12-04)
**Next Focus:** Phase 3 - Triangle Rendering

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

### Code Status (After Session 005)
- ✅ Vulkan instance and validation layers
- ✅ GLFW window with surface
- ✅ Physical device selection
- ✅ Logical device and queues
- ✅ Swap chain with double buffering
- ✅ Image views
- ✅ Render pass
- ✅ Framebuffers
- ✅ Command pool and buffers
- ✅ Synchronization objects (semaphores, fences)
- ✅ Render loop (clears to dark blue)
- ❌ No graphics pipeline yet
- ❌ No shaders yet
- ❌ No geometry yet

## Session 005 Key Changes

### Implemented Full Vulkan Rendering Pipeline

**Added 10 major components:**
1. Queue family finding
2. Logical device creation
3. Swap chain support queries
4. Swap chain creation
5. Image views
6. Render pass
7. Framebuffers
8. Command pool & buffers
9. Sync objects
10. Render loop with drawFrame()

**Updated for Zig 0.15.2:**
- build.zig: `root_source_file` → `root_module` with `createModule()`
- `callconv(.C)` → `callconv(.c)` (lowercase)

---

## Next Steps (Phase 3: Triangle Rendering)

From ROADMAP.md Phase 3:
1. [ ] Write vertex shader (GLSL → SPIR-V)
2. [ ] Write fragment shader (GLSL → SPIR-V)
3. [ ] Create shader modules in Zig
4. [ ] Set up graphics pipeline
5. [ ] Define vertex input format
6. [ ] Create vertex buffer with triangle data
7. [ ] Draw the triangle!

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
# Compile GLSL to SPIR-V (need glslc from Vulkan SDK)
glslc shader.vert -o shader.vert.spv
glslc shader.frag -o shader.frag.spv
```

### Git
```bash
# Current status
git status --short

# Recent commits
git log --oneline --graph -10
```

## File Structure
```
bidama_hajiki/
├── src/
│   └── main.zig              # ~800 lines, rendering pipeline complete
├── shaders/                  # TODO: Add in Phase 3
│   ├── shader.vert
│   └── shader.frag
├── zig-out/                  # Build output (gitignored)
├── .zig-cache/               # Build cache (gitignored)
├── docs/
│   ├── sessions/
│   │   ├── 001-resurrection-and-foundation.md
│   │   ├── 002-cross-platform-build-system.md
│   │   ├── 003-rebranding-and-priorities.md
│   │   ├── 004-zig-migration.md
│   │   └── 005-core-rendering.md
│   ├── NEXT_SESSION.md       # This file
│   ├── GAMEPLAY_VISION.md
│   ├── LIBRARY_DECISIONS.md
│   └── phase2-rendering-guide.md
├── museum/                   # Archived old code
├── build.zig                 # Zig build configuration
├── README.md
├── ROADMAP.md
└── .gitignore
```

## Code Architecture (Current)

### VulkanState Struct
```zig
const VulkanState = struct {
    // Instance
    instance: c.VkInstance = null,
    surface: c.VkSurfaceKHR = null,
    physical_device: c.VkPhysicalDevice = null,

    // Device
    device: c.VkDevice = null,
    graphics_queue: c.VkQueue = null,
    present_queue: c.VkQueue = null,
    graphics_family_index: u32 = 0,
    present_family_index: u32 = 0,

    // Swap chain
    swapchain: c.VkSwapchainKHR = null,
    swapchain_format: c.VkFormat = c.VK_FORMAT_UNDEFINED,
    swapchain_extent: c.VkExtent2D = .{ .width = 0, .height = 0 },
    swapchain_images: ?[*]c.VkImage = null,
    swapchain_image_count: u32 = 0,
    swapchain_image_views: ?[*]c.VkImageView = null,

    // Rendering
    render_pass: c.VkRenderPass = null,
    framebuffers: ?[*]c.VkFramebuffer = null,
    command_pool: c.VkCommandPool = null,
    command_buffers: ?[*]c.VkCommandBuffer = null,

    // Sync
    image_available_semaphores: ?[*]c.VkSemaphore = null,
    render_finished_semaphores: ?[*]c.VkSemaphore = null,
    in_flight_fences: ?[*]c.VkFence = null,

    // TODO: Add for Phase 3
    // pipeline_layout: c.VkPipelineLayout = null,
    // graphics_pipeline: c.VkPipeline = null,
    // vertex_buffer: c.VkBuffer = null,
    // vertex_buffer_memory: c.VkDeviceMemory = null,
};
```

### Functions (Current)
- `errorCallback()` - GLFW errors
- `keyCallback()` - ESC to quit
- `createVulkanInstance()` - Instance + validation
- `pickPhysicalDevice()` - GPU selection
- `findQueueFamilies()` - Queue family discovery
- `createLogicalDevice()` - Device + queues
- `querySwapChainSupport()` - Swap chain capabilities
- `chooseSwapSurfaceFormat()` - SRGB preferred
- `chooseSwapPresentMode()` - Mailbox (triple buffer) preferred
- `chooseSwapExtent()` - Match window size
- `createSwapChain()` - Swap chain + images
- `createImageViews()` - Image views
- `createRenderPass()` - Single subpass
- `createFramebuffers()` - Per-image framebuffers
- `createCommandPool()` - Command pool
- `createCommandBuffers()` - Per-frame command buffers
- `createSyncObjects()` - Semaphores + fences
- `recordCommandBuffer()` - Records clear command
- `drawFrame()` - Full frame cycle
- `cleanupVulkan()` - Destroy everything

### Functions (Need to Add for Phase 3)
- `createShaderModule()` - Load SPIR-V
- `createGraphicsPipeline()` - Full pipeline setup
- `createVertexBuffer()` - Geometry data
- Updated `recordCommandBuffer()` - Add draw call

## Philosophy Reminders

From ROADMAP.md:
- **Zig's philosophy aligns** - simple, explicit, no hidden control flow
- **Structs and functions** - no class hierarchies
- **No premature abstraction** - wait until we have 3+ examples
- **Write shaders from scratch** - understand every line
- **Simple, direct code** - if it's confusing, simplify it
- **Data-oriented** - think about memory layout and cache
- **Solve today's problems** - don't future-proof unnecessarily

## Resources for Next Session

### Vulkan Tutorial Sections
1. Shader modules: https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Shader_modules
2. Fixed functions: https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Fixed_functions
3. Graphics pipeline: https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Conclusion
4. Vertex buffers: https://vulkan-tutorial.com/Vertex_buffers/Vertex_input_description

### Zig Resources
- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)

### Keep in Mind
- Shaders are compiled offline with glslc (GLSL → SPIR-V)
- Load .spv files at runtime with @embedFile or file I/O
- Graphics pipeline is immutable - create all variants upfront
- Vertex buffer needs host-visible memory for now (can optimize later)

## Session History

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
- Removed all C++ build artifacts
- Updated all documentation

### Session 003 (2025-11-22): Rebranding and Priorities
- Renamed project to Bidama Hajiki (ビー玉弾き)
- Established "find the fun first" philosophy
- Decided on controller-first input design
- Clarified lighting and physics as essential, not polish
- Cleaned legacy ODE references
- Created comprehensive Phase 2 implementation guide

### Session 002 (2025-11-22): Cross-Platform Build System
- Set up Windows cross-compilation (MinGW-w64)
- Configured vcpkg for Windows dependencies
- Created platform-specific build scripts
- Established LSP integration with compile_commands.json

### Session 001 (2025-11-22): Resurrection and Foundation
- Archived legacy "Marbles" codebase to museum/
- Started fresh with minimal Vulkan initialization
- Established C-style programming approach
- Created project structure and build system

---

## Quick Health Check Before Starting

Run these to verify everything is ready:

```bash
# Check Zig version
zig version

# Check build works
zig build

# Check it runs (will timeout after 3s in WSL2 without display)
timeout 3 ./zig-out/bin/bidama_hajiki; echo "Exit: $?"

# Check git is clean
git status
```

Expected:
- Zig 0.15.2
- Build succeeds with no errors
- Exit code 124 (timeout) = program running correctly
- Git working tree clean (or only uncommitted docs)

## Session 006 Goals

**Primary:** Draw a colored triangle

**Steps:**
1. Create shaders/ directory with vertex and fragment shaders
2. Compile shaders to SPIR-V
3. Implement createShaderModule()
4. Implement createGraphicsPipeline()
5. Define vertex format and create triangle data
6. Update recordCommandBuffer() with draw call
7. See triangle on screen!

**Success criteria:**
- Colored triangle visible on dark blue background
- No Vulkan validation errors
- Clean shutdown with ESC key
- Code remains simple and understandable

---

**Ready to draw a triangle!**
