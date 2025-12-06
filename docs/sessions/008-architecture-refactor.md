# Session 008: Architecture Refactor

**Date:** 2025-12-05
**Focus:** Code organization and modularization

## Summary

Split monolithic main.zig (1450 lines) into logical modules for easier mental parsing. Target was ~500 lines max per file.

## Changes Made

### New Module Structure

```
src/
├── main.zig           (161 lines) - Entry point, GLFW callbacks, main loop
├── math.zig           (102 lines) - Vec3, Mat4 math utilities
├── types.zig          (104 lines) - Config, VulkanState, Vertex, UBO
├── vulkan_init.zig    (537 lines) - Instance, device, swapchain, cleanup
└── vulkan_render.zig  (596 lines) - Pipeline, buffers, descriptors, draw
```

### Module Dependencies

```
main.zig
  └── types.zig (VulkanState, config, c)
  └── vulkan_init.zig (init/cleanup functions)
  └── vulkan_render.zig (render functions)

vulkan_init.zig
  └── types.zig (VulkanState, SwapChainSupportDetails, c)

vulkan_render.zig
  └── types.zig (VulkanState, Vertex, UBO, c)
  └── math.zig (Mat4)

types.zig
  └── math.zig (Mat4 for UBO)
```

### File Contents

**math.zig**
- Vec3: sub, cross, dot, normalize
- Mat4: identity, multiply, perspective, lookAt, rotateZ

**types.zig**
- Config constants (window_width, window_height, etc.)
- C bindings re-export (@cImport for GLFW/Vulkan)
- VulkanState struct (all Vulkan handles)
- UniformBufferObject, QueueFamilyIndices, SwapChainSupportDetails
- Vertex struct and vertices data

**vulkan_init.zig**
- createVulkanInstance
- pickPhysicalDevice, findQueueFamilies
- querySwapChainSupport, chooseSwap* helpers
- createLogicalDevice, createSwapChain
- createImageViews, createRenderPass
- createFramebuffers, cleanupVulkan

**vulkan_render.zig**
- createShaderModule, createGraphicsPipeline
- findMemoryType, createVertexBuffer
- createDescriptorSetLayout, createUniformBuffers
- createDescriptorPool, createDescriptorSets
- updateUniformBuffer, createCommandPool
- createCommandBuffers, createSyncObjects
- recordCommandBuffer, drawFrame

**main.zig**
- errorCallback, keyCallback (GLFW)
- pub fn main() - init sequence and render loop

## Zig Patterns Discussed

### Method vs Free Function Style
Zig uses "uniform function call syntax" - methods are just namespaced functions:
```zig
// These are equivalent:
const result = vec.normalize();
const result = Vec3.normalize(vec);
```
Both work. Zig doesn't enforce OOP vs functional - choose what reads best.

### No Pipe Operator
Unlike Elixir's `|>`, Zig chains via method syntax or intermediate variables.
Zig does have error unions (`!T`) similar to Elixir's `{:ok, value}/{:error, reason}`.

### Key Zig Concepts for Ruby/Elixir Devs
- No garbage collection - manual memory or allocators
- Optionals (`?T`) like Elm's Maybe
- Error unions (`!T`) like Result types
- Comptime for compile-time metaprogramming
- Slices vs arrays vs pointers
- `defer` for cleanup (like Elixir's `after` but better)

## Tech Stack Discussion

### User's Stack
- **Elixir**: Coordination, distributed systems, web backends
- **Zig**: Low-level, graphics, native code
- **Plain JS**: Frontend when needed

### Nix Evaluation
Nix is a good fit specifically for:
- Native/C++ projects with system dependencies (Vulkan, GLFW)
- Reproducible CI environments
- Pinning ancient toolchains

Less valuable for:
- Elixir/Node projects (asdf + Mix/npm already work well)

Recommendation: Use Nix flakes just for bidama_hajiki and undertow_native.

## Commits

1. `refactor: extract math utilities to math.zig`
2. `refactor: extract types and config to types.zig`
3. `refactor: extract Vulkan initialization to vulkan_init.zig`
4. `refactor: extract Vulkan rendering to vulkan_render.zig`
5. `refactor: slim main.zig to entry point only`

## Status After Session

- ✅ All modules under 600 lines
- ✅ Build succeeds
- ✅ Runtime verified (triangle still rotates)
- ✅ Clear separation of concerns
- ✅ Easy to find code by responsibility

## Next Session

Continue with Phase 5 (More Geometry or Game Content) now that codebase is organized.
