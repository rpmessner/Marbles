# Session 005: Core Rendering (Phase 2)

**Date:** 2025-12-04
**Duration:** ~1.5 hours
**Status:** ✅ Complete

## Overview

Implemented the complete Vulkan rendering pipeline to clear the screen to a solid color. This is the "proof of life" milestone - the first visible output from the graphics system.

## Goals

- [x] Create logical device and queues
- [x] Set up swap chain
- [x] Create image views
- [x] Implement render pass
- [x] Create framebuffers
- [x] Set up command pool and buffers
- [x] Create synchronization objects
- [x] Implement render loop
- [x] Clear screen to dark blue color

## What We Built

### Incremental Implementation (10 Steps)

Each step was implemented and verified before moving to the next:

1. **Queue Family Finding** - `QueueFamilyIndices` struct and `findQueueFamilies()` to locate graphics and present queues
2. **Logical Device** - `createLogicalDevice()` creates VkDevice and retrieves queue handles
3. **Swap Chain Helpers** - `SwapChainSupportDetails` struct with format/mode/extent selection functions
4. **Swap Chain** - `createSwapChain()` sets up the presentation system
5. **Image Views** - `createImageViews()` wraps swap chain images for rendering
6. **Render Pass** - `createRenderPass()` describes the rendering operations
7. **Framebuffers** - `createFramebuffers()` connects image views to render pass
8. **Command Pool & Buffers** - Command infrastructure for GPU commands
9. **Sync Objects** - Semaphores and fences for frame synchronization
10. **Render Loop** - `drawFrame()` with double-buffering

### Key Functions Added

```zig
// Queue families
fn findQueueFamilies(device: VkPhysicalDevice, surface: VkSurfaceKHR) QueueFamilyIndices

// Device setup
fn createLogicalDevice(vk: *VulkanState) bool

// Swap chain
fn querySwapChainSupport(device: VkPhysicalDevice, surface: VkSurfaceKHR) SwapChainSupportDetails
fn chooseSwapSurfaceFormat(formats: []VkSurfaceFormatKHR) VkSurfaceFormatKHR
fn chooseSwapPresentMode(modes: []VkPresentModeKHR) VkPresentModeKHR
fn chooseSwapExtent(capabilities: VkSurfaceCapabilitiesKHR, window: *GLFWwindow) VkExtent2D
fn createSwapChain(vk: *VulkanState, window: *GLFWwindow) bool

// Rendering infrastructure
fn createImageViews(vk: *VulkanState) bool
fn createRenderPass(vk: *VulkanState) bool
fn createFramebuffers(vk: *VulkanState) bool
fn createCommandPool(vk: *VulkanState) bool
fn createCommandBuffers(vk: *VulkanState) bool
fn createSyncObjects(vk: *VulkanState) bool

// Render loop
fn recordCommandBuffer(vk: *VulkanState, command_buffer: VkCommandBuffer, image_index: u32) void
fn drawFrame(vk: *VulkanState, current_frame: *u32) void
```

## Technical Decisions

### Double Buffering (max_frames_in_flight = 2)

Using two frames in flight for smooth rendering:
- CPU can prepare frame N+1 while GPU renders frame N
- Requires per-frame command buffers and sync objects
- Standard approach for real-time graphics

### Synchronization Strategy

```
Frame N:
  1. Wait for in_flight_fence[N] (CPU waits for GPU to finish using these resources)
  2. Acquire image from swap chain (signals image_available_semaphore[N])
  3. Record command buffer
  4. Submit (waits on image_available, signals render_finished)
  5. Present (waits on render_finished)
```

### Clear Color: Dark Blue

```zig
const clear_color = VkClearValue{
    .color = VkClearColorValue{ .float32 = [4]f32{ 0.0, 0.2, 0.4, 1.0 } },
};
```

Chose dark blue as a visible but not jarring "proof of life" color.

## Challenges & Solutions

### Challenge: Zig 0.15.2 Breaking Changes

The project was documented for Zig 0.13.0, but the system has Zig 0.15.2.

**Build System Changes:**
```zig
// Old (0.13.0)
const exe = b.addExecutable(.{
    .root_source_file = b.path("src/main.zig"),
    ...
});

// New (0.15.2)
const exe = b.addExecutable(.{
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .link_libc = true,
        ...
    }),
});
```

**Calling Convention:**
```zig
// Old (0.13.0)
fn callback(...) callconv(.C) void

// New (0.15.2)
fn callback(...) callconv(.c) void  // lowercase
```

### Challenge: WSL2 Display Output

Running in WSL2 without X forwarding means we can't see the window. Solution: Use timeout to verify the program runs without crashing:
```bash
timeout 3 ./zig-out/bin/bidama_hajiki
# Exit code 124 = timeout killed it = program was running successfully
```

## Code Statistics

**Before:**
- src/main.zig: 197 lines
- build.zig: 30 lines

**After:**
- src/main.zig: 800 lines (+603 lines)
- build.zig: 30 lines (restructured for 0.15.2)

**New structures:**
- `QueueFamilyIndices` - Queue family tracking
- `SwapChainSupportDetails` - Swap chain capabilities

**New VulkanState fields:**
- device, graphics_queue, present_queue
- graphics_family_index, present_family_index
- swapchain, swapchain_format, swapchain_extent
- swapchain_images, swapchain_image_count, swapchain_image_views
- render_pass, framebuffers
- command_pool, command_buffers
- image_available_semaphores, render_finished_semaphores, in_flight_fences

## Lessons Learned

1. **Zig versions matter** - 0.13 to 0.15 had breaking API changes in both the build system and language syntax.

2. **Incremental verification is key** - Building after each step caught issues early.

3. **Vulkan is verbose but predictable** - Each step follows the same pattern: create info struct, call vkCreate*, check result.

4. **Synchronization is the tricky part** - Getting fences and semaphores right is crucial for avoiding race conditions.

5. **WSL2 works for development** - Even without display forwarding, you can verify programs run correctly.

## Architecture After Phase 2

```
main()
├── GLFW init
├── Window creation
├── Vulkan init
│   ├── createVulkanInstance()
│   ├── glfwCreateWindowSurface()
│   ├── pickPhysicalDevice()
│   ├── createLogicalDevice()      ← NEW
│   ├── createSwapChain()          ← NEW
│   ├── createImageViews()         ← NEW
│   ├── createRenderPass()         ← NEW
│   ├── createFramebuffers()       ← NEW
│   ├── createCommandPool()        ← NEW
│   ├── createCommandBuffers()     ← NEW
│   └── createSyncObjects()        ← NEW
├── Render loop                    ← NEW
│   └── drawFrame()                ← NEW
│       ├── Wait for fence
│       ├── Acquire image
│       ├── Record commands
│       ├── Submit
│       └── Present
├── vkDeviceWaitIdle()             ← NEW
└── cleanupVulkan()                ← UPDATED

```

## Next Session

**Focus:** Phase 3 - Triangle Rendering

**Goals:**
1. Create shader modules (vertex + fragment)
2. Set up graphics pipeline
3. Draw a colored triangle
4. Basic vertex input

**Success criteria:**
- Triangle visible on screen
- Different color than background
- No validation errors

## References

- [Vulkan Tutorial - Drawing a Triangle](https://vulkan-tutorial.com/Drawing_a_triangle)
- [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)
- [Zig Build System](https://ziglang.org/learn/build-system/)

---

**Key Takeaway:** Phase 2 is complete - we have a working Vulkan rendering loop. The window clears to dark blue, proving the entire pipeline from device creation to presentation is functional. Ready for actual geometry rendering in Phase 3.
