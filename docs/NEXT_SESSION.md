# Next Session Quick Reference

**Last Session:** 008 - Architecture Refactor (2025-12-05)
**Next Focus:** Phase 5 - More Geometry / Game Content

## Current Status

### Language & Build System
- **Language:** Zig 0.15.2
- **Build:** `zig build` / `zig build run`
- **Cross-compile:** `zig build -Dtarget=x86_64-windows`

### Code Status (After Session 008)
- ✅ Modular architecture (5 files, all under 600 lines)
- ✅ Full Vulkan rendering pipeline
- ✅ MVP matrix transformations
- ✅ Time-based rotation animation
- ❌ No textures
- ❌ Only one object (triangle)
- ❌ No depth buffer (no 3D overlap)
- ❌ No input handling

## Module Structure

```
src/
├── main.zig           (161 lines) - Entry point, GLFW callbacks, main loop
├── math.zig           (102 lines) - Vec3, Mat4 math utilities
├── types.zig          (104 lines) - Config, VulkanState, Vertex, UBO
├── vulkan_init.zig    (537 lines) - Instance, device, swapchain, cleanup
└── vulkan_render.zig  (596 lines) - Pipeline, buffers, descriptors, draw
```

### Where to Find Things

| What | File | Function/Struct |
|------|------|-----------------|
| Window creation | main.zig | main() |
| Vulkan instance | vulkan_init.zig | createVulkanInstance() |
| GPU selection | vulkan_init.zig | pickPhysicalDevice() |
| Swap chain | vulkan_init.zig | createSwapChain() |
| Graphics pipeline | vulkan_render.zig | createGraphicsPipeline() |
| Vertex buffer | vulkan_render.zig | createVertexBuffer() |
| Uniform buffers | vulkan_render.zig | createUniformBuffers() |
| Descriptor sets | vulkan_render.zig | createDescriptorSets() |
| Draw call | vulkan_render.zig | drawFrame() |
| Matrix math | math.zig | Mat4.* |
| All Vulkan handles | types.zig | VulkanState |
| Vertex data | types.zig | vertices |

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
```

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

## Session 008 Summary

Split main.zig (1450 lines) into 5 modules:
- math.zig - Vec3, Mat4 math utilities
- types.zig - Config, VulkanState, all type definitions
- vulkan_init.zig - All initialization and cleanup
- vulkan_render.zig - Pipeline, buffers, rendering
- main.zig - Entry point only

Also discussed:
- Zig idioms (method syntax vs free functions)
- Zig features for Ruby/Elixir devs (optionals, error unions, comptime)
- Tech stack recommendations (Elixir + Zig + plain JS)
- Nix for native projects (good fit for Vulkan/GLFW deps)
- Functional JS philosophy for LLM-assisted development

## Gameplay Vision: Zeni Hajiki

**Target:** Clone of the zeni hajiki minigame from Ghost of Yotei

**Core Mechanic:**
- Aim your marble at targets
- Charge power, release to shoot
- Score by hitting exactly ONE target marble
- First to 6 points wins

**See:** [docs/GAMEPLAY_VISION.md](./GAMEPLAY_VISION.md) for full design

---

**Ready for Phase 5!**
