# Next Session Quick Reference

**Last Session:** 003 - Rebranding and Priorities (2025-11-22)
**Next Focus:** Phase 2 - Core Rendering

**See:** [docs/phase2-rendering-guide.md](./phase2-rendering-guide.md) for complete implementation guide

## 🎯 Gameplay Vision: Zeni Hajiki

**Target:** Clone of the zeni hajiki minigame from Ghost of Yotei

**Core Mechanic:**
- Aim your marble at targets
- Charge power, release to shoot
- Score by hitting exactly ONE target marble
- First to 6 points wins

**See:** [docs/GAMEPLAY_VISION.md](./GAMEPLAY_VISION.md) for full design

---

## Current Status ✅

### Build System
- ✅ Windows cross-compilation working (`./build-windows.sh` → 257k PE32+ exe)
- ✅ Linux native builds working (`./build-linux.sh` → 17k ELF executable)
- ✅ LSP configured with compile_commands.json
- ✅ vcpkg managing Windows dependencies
- ✅ All commits granular and well-documented

### Code Status
- ✅ Minimal Vulkan initialization (VulkanState struct)
- ✅ GLFW window creation
- ✅ Physical device (GPU) selection
- ✅ Validation layers enabled
- ⏳ No logical device yet
- ⏳ No swap chain yet
- ⏳ No rendering yet

## 🎮 Session 003 Key Decisions

### Project Renamed: Bidama Hajiki (ビー玉弾き)
- "Marbles" now only refers to museum/legacy code
- Bidama (ビー玉) = glass marble, Hajiki (弾き) = flicking
- All build outputs renamed to `bidama_hajiki`

### Gameplay Philosophy: Find the Fun First
1. **Lighting is essential** - Need spatial clarity to judge angles/power
2. **Surface physics = skill** - Friction and drag ARE the gameplay
3. **Controller-first** - PS2 controller as primary input (analog stick for analog power)
4. **Playable > polished** - Get gameplay working before RTX graphics

### Library Philosophy
**"Add libraries only when needed, choose the best at that time"**
- Removed all ODE references (will evaluate physics options in Phase 4)
- No premature dependencies

---

## Next Steps (Phase 2: Core Rendering)

From ROADMAP.md Phase 2:
1. [ ] Create logical device and queues
2. [ ] Set up swap chain
3. [ ] Implement command buffers and render loop
4. [ ] Clear screen to color (first visible output!)
5. [ ] Basic camera system (position, view matrix)

## Key Decisions Made

### Shader Language: GLSL
- Native to Vulkan (compiles to SPIR-V)
- Cross-platform
- Simple toolchain (glslc)
- Aligns with "simple and direct" philosophy

### Build Approach
- Cross-compile from WSL2 to Windows using MinGW-w64
- vcpkg for Windows dependencies
- Platform-specific build scripts
- Separate build directories (build-linux/, build-windows/)

## Commands Cheat Sheet

### Building
```bash
# Linux build (for development/LSP)
./build-linux.sh

# Windows build (for testing on native Windows)
./build-windows.sh

# Both
./build-linux.sh && ./build-windows.sh
```

### Running
```bash
# Linux (if Vulkan drivers available in WSL2)
./build-linux/bidama_hajiki

# Windows (copy to Windows side)
cp build-windows/bidama_hajiki.exe /mnt/c/Users/YourName/Desktop/
cp vcpkg/installed/x64-mingw-dynamic/bin/*.dll /mnt/c/Users/YourName/Desktop/
# Then run on Windows
```

### Git
```bash
# Current branch
git log --oneline --graph -10

# Status
git status --short
```

## File Structure
```
bidama_hajiki/
├── src/
│   └── main.cpp              # Current: minimal Vulkan init
├── build-linux/              # Linux build output (gitignored)
├── build-windows/            # Windows build output (gitignored)
├── vcpkg/                    # Windows dependencies (gitignored)
├── docs/
│   ├── sessions/
│   │   ├── 001-resurrection-and-foundation.md
│   │   └── 002-cross-platform-build-system.md
│   └── NEXT_SESSION.md       # This file
├── cmake/
│   └── toolchain-mingw-w64.cmake
├── museum/                   # Archived old code
├── build-linux.sh
├── build-windows.sh
├── CMakeLists.txt
├── Makefile
├── setup.sh
├── README.md
├── ROADMAP.md
└── .gitignore
```

## Code Architecture (Current)

### VulkanState Struct
```cpp
struct VulkanState {
    VkInstance instance;
    VkSurfaceKHR surface;
    VkPhysicalDevice physical_device;
    VkDevice device;              // Not initialized yet
    VkQueue graphics_queue;       // Not initialized yet
    VkQueue present_queue;        // Not initialized yet
    VkSwapchainKHR swapchain;     // Not initialized yet
    VkFormat swapchain_format;
    VkExtent2D swapchain_extent;
    VkImage* swapchain_images;
    uint32_t swapchain_image_count;
    VkImageView* swapchain_image_views;
};
```

### Functions (Current)
- `error_callback()` - GLFW errors
- `key_callback()` - ESC to quit
- `create_vulkan_instance()` - ✅ Done
- `pick_physical_device()` - ✅ Done
- `cleanup_vulkan()` - Partial (only cleans what's initialized)

### Functions (Need to Add)
- `find_queue_families()` - Find graphics/present queues
- `create_logical_device()` - Create VkDevice
- `create_swapchain()` - Set up swap chain
- `create_image_views()` - Create image views for swap chain
- `create_command_pool()` - Command buffer pool
- `create_command_buffers()` - Allocate command buffers
- `record_command_buffer()` - Record rendering commands
- `draw_frame()` - Main render loop function

## Philosophy Reminders

From ROADMAP.md:
- **No classes unless necessary** - structs and functions first
- **No premature abstraction** - wait until we have 3+ examples
- **Write shaders from scratch** - understand every line
- **Simple, direct code** - if it's confusing, simplify it
- **Data-oriented** - think about memory layout and cache
- **Solve today's problems** - don't future-proof unnecessarily

## Resources for Next Session

### Vulkan Tutorial Sections to Read
1. Logical device and queues: https://vulkan-tutorial.com/Drawing_a_triangle/Setup/Logical_device_and_queues
2. Swap chain: https://vulkan-tutorial.com/Drawing_a_triangle/Presentation/Swap_chain
3. Image views: https://vulkan-tutorial.com/Drawing_a_triangle/Presentation/Image_views
4. Render passes: https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Render_passes

### Keep in Mind
- We're NOT using C++ wrappers (vulkan.hpp) - using raw C API
- We're NOT using VulkanMemoryAllocator yet - solve that problem when we get to it
- Focus on getting something rendering (clear screen to color)
- Don't over-engineer - get it working first

## Session History

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

## Optional: Cleanup Unused vcpkg Packages

vcpkg currently has ODE installed from Session 002, but we removed it from the build.

**To clean up (optional):**
```bash
cd vcpkg
./vcpkg remove ode:x64-mingw-dynamic
```

This saves ~20MB but isn't critical. Your builds work fine as-is.

---

## Quick Health Check Before Starting

Run these to verify everything is ready:

```bash
# Check builds work
./build-linux.sh
./build-windows.sh

# Check LSP has compile commands
ls -la compile_commands.json

# Check git is clean
git status

# Check commit history looks good
git log --oneline --graph -15
```

Expected:
- Both builds succeed
- compile_commands.json → build-linux/compile_commands.json
- Git working tree clean (or only local test files)
- 12-13 commits since initial commit

## Session 003 Goals

**Primary:** Get something visible on screen (clear to color)

**Steps:**
1. Implement logical device creation with queue families
2. Create swap chain for rendering
3. Set up command buffers
4. Implement basic render loop
5. Clear screen to a color (proof of life!)

**Success criteria:**
- Window opens and shows a solid color (not black/undefined)
- No Vulkan validation errors
- Clean shutdown with ESC key
- Code remains simple and understandable

---

**Ready to start rendering!** 🎨
