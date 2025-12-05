# Session 006: Triangle Rendering (Phase 3)

**Date:** 2025-12-04
**Duration:** ~1 hour
**Status:** ✅ Complete

## Overview

Implemented a complete graphics pipeline to render a colored triangle - the classic "Hello World" of graphics programming. This demonstrates the full Vulkan rendering pipeline from shaders to screen.

## Goals

- [x] Create GLSL vertex shader
- [x] Create GLSL fragment shader
- [x] Compile shaders to SPIR-V
- [x] Implement shader module loading
- [x] Create graphics pipeline
- [x] Create vertex buffer with triangle data
- [x] Update render loop with draw call
- [x] Triangle visible on screen

## What We Built

### GLSL Shaders

**Vertex Shader** (`src/shaders/triangle.vert`):
```glsl
#version 450
layout(location = 0) in vec2 inPosition;
layout(location = 0) out vec3 fragColor;

vec3 colors[3] = vec3[](
    vec3(1.0, 0.0, 0.0),  // red
    vec3(0.0, 1.0, 0.0),  // green
    vec3(0.0, 0.0, 1.0)   // blue
);

void main() {
    gl_Position = vec4(inPosition, 0.0, 1.0);
    fragColor = colors[gl_VertexIndex];
}
```

**Fragment Shader** (`src/shaders/triangle.frag`):
```glsl
#version 450
layout(location = 0) in vec3 fragColor;
layout(location = 0) out vec4 outColor;

void main() {
    outColor = vec4(fragColor, 1.0);
}
```

### Key Functions Added

```zig
// Shader loading
fn createShaderModule(device: VkDevice, code: []const u8) VkShaderModule

// Graphics pipeline (100+ lines)
fn createGraphicsPipeline(vk: *VulkanState) bool

// Memory helpers
fn findMemoryType(vk: *VulkanState, type_filter: u32, properties: VkMemoryPropertyFlags) ?u32

// Vertex buffer
fn createVertexBuffer(vk: *VulkanState) bool
```

### Data Structures

```zig
const Vertex = struct {
    pos: [2]f32,
};

const vertices = [_]Vertex{
    .{ .pos = .{ 0.0, -0.5 } },   // top
    .{ .pos = .{ 0.5, 0.5 } },    // bottom right
    .{ .pos = .{ -0.5, 0.5 } },   // bottom left
};
```

## Technical Decisions

### Shaders in src/shaders/

Placed shaders inside `src/` so `@embedFile` works without path configuration. SPIR-V files are compiled once and embedded at compile time.

### Dynamic Viewport/Scissor

Enabled `VK_DYNAMIC_STATE_VIEWPORT` and `VK_DYNAMIC_STATE_SCISSOR` so we can resize the window later without recreating the pipeline.

### Host-Visible Vertex Buffer

Using `VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT` for simplicity. For production, we'd use a staging buffer with device-local memory.

### Hardcoded Colors via gl_VertexIndex

Colors are indexed by vertex index in the shader, giving us red/green/blue interpolation across the triangle without needing per-vertex color attributes.

## Challenges & Solutions

### Challenge: @embedFile Path Restrictions

Zig 0.15 won't embed files outside the package root.

**Solution:** Moved `shaders/` into `src/shaders/`:
```zig
const vert_code = @embedFile("shaders/triangle.vert.spv");
```

### Challenge: glslc Not Available

No shader compiler installed.

**Solution:** Downloaded from Vulkan SDK:
```bash
wget https://sdk.lunarg.com/sdk/download/.../vulkansdk-linux-x86_64-1.3.290.0.tar.xz
tar -xJf - --wildcards '*/bin/glslc'
/tmp/1.3.290.0/x86_64/bin/glslc shader.vert -o shader.vert.spv
```

## Code Statistics

**Before:**
- src/main.zig: 800 lines

**After:**
- src/main.zig: 1104 lines (+304 lines)
- src/shaders/triangle.vert: 17 lines
- src/shaders/triangle.frag: 9 lines
- src/shaders/*.spv: SPIR-V binaries

**New VulkanState fields:**
- `pipeline_layout: VkPipelineLayout`
- `graphics_pipeline: VkPipeline`
- `vertex_buffer: VkBuffer`
- `vertex_buffer_memory: VkDeviceMemory`

## Lessons Learned

1. **Zig's @embedFile is powerful** - Shader binaries are compiled into the executable at build time. No file loading code needed at runtime.

2. **Graphics pipeline is verbose but straightforward** - Each stage (shaders, vertex input, rasterizer, blending) is configured explicitly. Vulkan hides nothing.

3. **Dynamic state simplifies resize** - Setting viewport/scissor dynamically means we won't need to recreate the pipeline when the window resizes.

4. **Vulkan SDK has standalone tools** - glslc can be extracted and used without installing the full SDK.

## Architecture After Phase 3

```
main()
├── GLFW init
├── Window creation
├── Vulkan init
│   ├── createVulkanInstance()
│   ├── glfwCreateWindowSurface()
│   ├── pickPhysicalDevice()
│   ├── createLogicalDevice()
│   ├── createSwapChain()
│   ├── createImageViews()
│   ├── createRenderPass()
│   ├── createFramebuffers()
│   ├── createGraphicsPipeline()   ← NEW
│   ├── createVertexBuffer()       ← NEW
│   ├── createCommandPool()
│   ├── createCommandBuffers()
│   └── createSyncObjects()
├── Render loop
│   └── drawFrame()
│       ├── Wait for fence
│       ├── Acquire image
│       ├── Record commands
│       │   ├── Begin render pass
│       │   ├── Bind pipeline        ← NEW
│       │   ├── Set viewport/scissor ← NEW
│       │   ├── Bind vertex buffer   ← NEW
│       │   ├── Draw 3 vertices      ← NEW
│       │   └── End render pass
│       ├── Submit
│       └── Present
├── vkDeviceWaitIdle()
└── cleanupVulkan()
```

## Files Added/Modified

**New files:**
- src/shaders/triangle.vert (GLSL source)
- src/shaders/triangle.frag (GLSL source)
- src/shaders/triangle.vert.spv (SPIR-V binary)
- src/shaders/triangle.frag.spv (SPIR-V binary)

**Modified:**
- src/main.zig (+304 lines)

## Next Session

**Focus:** Phase 4 - Multiple Triangles / Transformations

**Potential Goals:**
1. Add uniform buffers for transformations
2. Multiple objects with different positions
3. Basic camera/view matrix
4. Or: Start on game-specific features (table, marbles)

**Success criteria:**
- Multiple shapes on screen
- Or: Game table visible
- No validation errors
- Clean shutdown

## References

- [Vulkan Tutorial - Graphics Pipeline](https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics)
- [Vulkan Tutorial - Vertex Buffers](https://vulkan-tutorial.com/Vertex_buffers)
- [SPIR-V Specification](https://registry.khronos.org/SPIR-V/)

---

**Key Takeaway:** The triangle is the proof that everything works - shaders compile, pipeline is configured correctly, vertex data reaches the GPU, and fragments are written to the screen. Ready to build actual game content.
