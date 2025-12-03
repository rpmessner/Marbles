# Next Session Quick Reference

**Last Session:** 004 - Migration to Zig (2025-12-03)
**Next Focus:** Phase 2 - Core Rendering

**See:** [docs/phase2-rendering-guide.md](./phase2-rendering-guide.md) for complete implementation guide

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
- **Language:** Zig 0.13.0
- **Build:** `zig build` / `zig build run`
- **Cross-compile:** `zig build -Dtarget=x86_64-windows`

### Code Status
- Minimal Vulkan initialization (VulkanState struct)
- GLFW window creation via @cImport
- Physical device (GPU) selection
- Validation layers enabled
- No logical device yet
- No swap chain yet
- No rendering yet

## Session 004 Key Changes

### Migrated from C++ to Zig

**Why:**
- Philosophy alignment - Zig is designed for simple, explicit code
- We were writing "C-style code in C++" - fighting the language
- Better C interop via `@cImport`
- Built-in build system replaces CMake + vcpkg + Makefiles
- Trivial cross-compilation

**Removed:**
- CMakeLists.txt, Makefile
- vcpkg/ directory
- build-linux.sh, build-windows.sh, setup.sh
- src/main.cpp

**Added:**
- build.zig (30 lines)
- src/main.zig (~180 lines)

---

## Next Steps (Phase 2: Core Rendering)

From ROADMAP.md Phase 2:
1. [ ] Create logical device and queues
2. [ ] Set up swap chain
3. [ ] Implement command buffers and render loop
4. [ ] Clear screen to color (first visible output!)
5. [ ] Basic camera system (position, view matrix)

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
│   └── main.zig              # Current: minimal Vulkan init
├── zig-out/                  # Build output (gitignored)
├── .zig-cache/               # Build cache (gitignored)
├── docs/
│   ├── sessions/
│   │   ├── 001-resurrection-and-foundation.md
│   │   ├── 002-cross-platform-build-system.md
│   │   ├── 003-rebranding-and-priorities.md
│   │   └── 004-zig-migration.md
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
    instance: c.VkInstance = null,
    surface: c.VkSurfaceKHR = null,
    physical_device: c.VkPhysicalDevice = null,
    device: c.VkDevice = null,              // Not initialized yet
    graphics_queue: c.VkQueue = null,       // Not initialized yet
    present_queue: c.VkQueue = null,        // Not initialized yet
    swapchain: c.VkSwapchainKHR = null,     // Not initialized yet
    swapchain_format: c.VkFormat = c.VK_FORMAT_UNDEFINED,
    swapchain_extent: c.VkExtent2D = .{ .width = 0, .height = 0 },
    swapchain_images: ?[*]c.VkImage = null,
    swapchain_image_count: u32 = 0,
    swapchain_image_views: ?[*]c.VkImageView = null,
};
```

### Functions (Current)
- `errorCallback()` - GLFW errors
- `keyCallback()` - ESC to quit
- `createVulkanInstance()` - Done
- `pickPhysicalDevice()` - Done
- `cleanupVulkan()` - Partial (only cleans what's initialized)

### Functions (Need to Add for Phase 2)
- `findQueueFamilies()` - Find graphics/present queues
- `createLogicalDevice()` - Create VkDevice
- `createSwapchain()` - Set up swap chain
- `createImageViews()` - Create image views for swap chain
- `createRenderPass()` - Describe rendering operations
- `createFramebuffers()` - Connect image views to render pass
- `createCommandPool()` - Command buffer pool
- `createCommandBuffers()` - Allocate command buffers
- `createSyncObjects()` - Semaphores and fences
- `recordCommandBuffer()` - Record rendering commands
- `drawFrame()` - Main render loop function

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
1. Logical device: https://vulkan-tutorial.com/Drawing_a_triangle/Setup/Logical_device_and_queues
2. Swap chain: https://vulkan-tutorial.com/Drawing_a_triangle/Presentation/Swap_chain
3. Image views: https://vulkan-tutorial.com/Drawing_a_triangle/Presentation/Image_views
4. Render passes: https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Render_passes

### Zig Resources
- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig-Gamedev](https://github.com/zig-gamedev) - Game development ecosystem

### Keep in Mind
- We're using `@cImport` for Vulkan/GLFW - translate C patterns to Zig
- Use `std.mem.zeroes()` to zero-initialize Vulkan structs
- Zig's error handling via `!` and `catch` replaces C's return codes
- Focus on getting something rendering (clear screen to color)
- Don't over-engineer - get it working first

## Session History

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

# Check git is clean
git status

# Check commit history
git log --oneline --graph -5
```

Expected:
- Zig 0.13.0
- Build succeeds with no errors
- Git working tree clean (or only uncommitted docs)

## Session 005 Goals

**Primary:** Get something visible on screen (clear to color)

**Steps:**
1. Implement logical device creation with queue families
2. Create swap chain for rendering
3. Set up render pass and framebuffers
4. Create command buffers and sync objects
5. Implement basic render loop
6. Clear screen to a color (proof of life!)

**Success criteria:**
- Window opens and shows a solid color (not black/undefined)
- No Vulkan validation errors
- Clean shutdown with ESC key
- Code remains simple and understandable

---

**Ready to start rendering!**
