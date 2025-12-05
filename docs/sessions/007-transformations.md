# Session 007: Transformations

**Date:** 2025-12-05
**Phase:** 4 - MVP Matrices
**Duration:** ~1 session

## Summary

Added Model-View-Projection (MVP) matrix transformations to the rendering pipeline. The triangle now rotates around the Z-axis with a camera looking at the origin. This proves the uniform buffer system works correctly.

## Goals

- [x] Add Vec3 and Mat4 math utilities
- [x] Add uniform buffer objects for MVP matrices
- [x] Add descriptor sets and pools
- [x] Update vertex shader to use MVP transform
- [x] Implement time-based animation

## Technical Implementation

### Math Utilities (Lines 21-117)

Added custom Vec3 and Mat4 structs:

```zig
const Vec3 = struct {
    x: f32 = 0, y: f32 = 0, z: f32 = 0,
    fn sub(a: Vec3, b: Vec3) Vec3 { ... }
    fn cross(a: Vec3, b: Vec3) Vec3 { ... }
    fn dot(a: Vec3, b: Vec3) f32 { ... }
    fn normalize(v: Vec3) Vec3 { ... }
};

const Mat4 = struct {
    data: [16]f32 = [_]f32{0} ** 16,
    fn identity() Mat4 { ... }
    fn multiply(a: Mat4, b: Mat4) Mat4 { ... }
    fn perspective(fov, aspect, near, far) Mat4 { ... }
    fn lookAt(eye, center, up) Mat4 { ... }
    fn rotateZ(angle) Mat4 { ... }
};
```

Mat4 uses row-major order with 16 contiguous floats.

### Uniform Buffer Object (Lines 119-124)

```zig
const UniformBufferObject = struct {
    model: Mat4 = Mat4.identity(),
    view: Mat4 = Mat4.identity(),
    proj: Mat4 = Mat4.identity(),
};
```

### VulkanState New Fields (Lines 168-175)

```zig
// Uniform buffers (one per frame in flight)
uniform_buffers: ?[*]c.VkBuffer = null,
uniform_buffers_memory: ?[*]c.VkDeviceMemory = null,
uniform_buffers_mapped: ?[*]?*anyopaque = null,
// Descriptors
descriptor_set_layout: c.VkDescriptorSetLayout = null,
descriptor_pool: c.VkDescriptorPool = null,
descriptor_sets: ?[*]c.VkDescriptorSet = null,
```

### New Functions

1. **createDescriptorSetLayout()** (Lines 793-812)
   - Defines UBO binding at binding 0
   - Accessible from vertex shader stage

2. **createUniformBuffers()** (Lines 815-860)
   - Creates one buffer per frame in flight (double buffering)
   - Uses persistent mapping (mapped once, never unmapped)
   - Host-visible and host-coherent memory

3. **createDescriptorPool()** (Lines 863-881)
   - Pool sized for max_frames_in_flight UBO descriptors

4. **createDescriptorSets()** (Lines 884-927)
   - Allocates one descriptor set per frame
   - Updates each set to point to its uniform buffer

5. **updateUniformBuffer()** (Lines 930-954)
   - Called each frame with current time
   - Model: rotates around Z based on time
   - View: camera at (2,2,2) looking at origin
   - Proj: 45-degree FOV perspective
   - Includes Vulkan Y-flip (clip space inversion)

### Vertex Shader Update

```glsl
#version 450

layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) in vec2 inPosition;
layout(location = 0) out vec3 fragColor;

void main() {
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 0.0, 1.0);
    fragColor = colors[gl_VertexIndex];
}
```

### Pipeline Layout Update

Pipeline layout now includes the descriptor set layout:
```zig
pipeline_layout_info.setLayoutCount = 1;
pipeline_layout_info.pSetLayouts = &vk.descriptor_set_layout;
```

### Render Loop Changes

- recordCommandBuffer() now takes `current_frame` parameter
- Binds descriptor set for current frame
- drawFrame() now takes `time` parameter
- Calls updateUniformBuffer() before rendering
- Main loop tracks elapsed time since start

## Files Changed

- `src/main.zig` - Added ~350 lines (now 1453 total)
- `src/shaders/triangle.vert` - Added UBO layout block
- `src/shaders/triangle.vert.spv` - Recompiled

## Key Decisions

1. **Row-major Mat4**: Matches typical math conventions
2. **Persistent mapping**: More efficient than map/unmap each frame
3. **Double-buffered UBOs**: One per frame in flight prevents race conditions
4. **Vulkan Y-flip**: Applied in projection matrix (ubo.proj.data[5] *= -1)
5. **Z-axis rotation**: Triangle spins parallel to screen

## Vulkan Concepts Introduced

- **Descriptor Set Layout**: Describes shader resource bindings
- **Descriptor Pool**: Allocator for descriptor sets
- **Descriptor Sets**: Actual bindings connecting buffers to shaders
- **Uniform Buffers**: Per-frame data sent to shaders
- **Persistent Buffer Mapping**: Keep memory mapped for lifetime

## Result

Triangle rotates around Z-axis at ~1 radian/second. Camera positioned at (2,2,2) with up vector (0,0,1), looking at origin. 45-degree field of view perspective projection.

## Next Steps (Phase 5 Options)

**Option A: More Geometry**
- Multiple objects (require per-object push constants or descriptor sets)
- 3D shapes (cubes, spheres)
- Depth buffer

**Option B: Game Content**
- Game table mesh
- Marble circles/spheres
- Basic input handling

## Code Statistics

- Total lines: 1453
- New lines this session: ~350
- Functions added: 5
- Structs added: 3 (Vec3, Mat4, UniformBufferObject)
