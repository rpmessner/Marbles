# Phase 2: Core Rendering Implementation Guide (Zig)

**Goal:** Get Vulkan rendering working - clear screen to a solid color

**Success Criteria:**
- Window opens showing a solid color (not black/undefined)
- No Vulkan validation errors in console
- ESC key cleanly shuts down
- Code remains simple and understandable

---

## Current State (End of Session 004)

### What We Have
```zig
const VulkanState = struct {
    instance: c.VkInstance = null,           // ✅ Created
    surface: c.VkSurfaceKHR = null,          // ✅ Created
    physical_device: c.VkPhysicalDevice = null, // ✅ Selected
    device: c.VkDevice = null,               // ❌ null
    graphics_queue: c.VkQueue = null,        // ❌ null
    present_queue: c.VkQueue = null,         // ❌ null
    swapchain: c.VkSwapchainKHR = null,      // ❌ null
    swapchain_format: c.VkFormat = c.VK_FORMAT_UNDEFINED,
    swapchain_extent: c.VkExtent2D = .{ .width = 0, .height = 0 },
    swapchain_images: ?[*]c.VkImage = null,
    swapchain_image_count: u32 = 0,
    swapchain_image_views: ?[*]c.VkImageView = null,
};
```

### Existing Functions
- `createVulkanInstance()` - ✅ Working
- `pickPhysicalDevice()` - ✅ Working (picks first GPU)
- `cleanupVulkan()` - ⚠️ Partial (only cleans initialized resources)

---

## Phase 2 Implementation Steps

### Step 1: Find Queue Families

**What:** Identify which queue families support graphics and presentation

**Why:** Vulkan queues are where we submit commands. We need:
- Graphics queue (for drawing commands)
- Present queue (for showing images on screen)

**New struct:**
```zig
const QueueFamilyIndices = struct {
    graphics_family: u32 = undefined,
    present_family: u32 = undefined,
    graphics_found: bool = false,
    present_found: bool = false,

    fn isComplete(self: QueueFamilyIndices) bool {
        return self.graphics_found and self.present_found;
    }
};
```

**New function:**
```zig
fn findQueueFamilies(device: c.VkPhysicalDevice, surface: c.VkSurfaceKHR) QueueFamilyIndices {
    var indices = QueueFamilyIndices{};

    var queue_family_count: u32 = 0;
    c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, null);

    const allocator = std.heap.c_allocator;
    const queue_families = allocator.alloc(c.VkQueueFamilyProperties, queue_family_count) catch return indices;
    defer allocator.free(queue_families);

    c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, queue_families.ptr);

    for (queue_families, 0..) |family, i| {
        const index: u32 = @intCast(i);

        // Check graphics support
        if (family.queueFlags & c.VK_QUEUE_GRAPHICS_BIT != 0) {
            indices.graphics_family = index;
            indices.graphics_found = true;
        }

        // Check present support
        var present_support: c.VkBool32 = c.VK_FALSE;
        _ = c.vkGetPhysicalDeviceSurfaceSupportKHR(device, index, surface, &present_support);
        if (present_support == c.VK_TRUE) {
            indices.present_family = index;
            indices.present_found = true;
        }

        if (indices.isComplete()) break;
    }

    return indices;
}
```

---

### Step 2: Create Logical Device

**What:** Create `VkDevice` (logical device) with required queues

**Add to VulkanState:**
```zig
graphics_family_index: u32 = 0,
present_family_index: u32 = 0,
```

**New function:**
```zig
fn createLogicalDevice(vk: *VulkanState) bool {
    const indices = findQueueFamilies(vk.physical_device, vk.surface);
    if (!indices.isComplete()) {
        std.debug.print("Failed to find required queue families\n", .{});
        return false;
    }

    vk.graphics_family_index = indices.graphics_family;
    vk.present_family_index = indices.present_family;

    // Queue create infos
    var queue_create_infos: [2]c.VkDeviceQueueCreateInfo = undefined;
    var queue_create_info_count: u32 = 0;
    const queue_priority: f32 = 1.0;

    // Graphics queue
    queue_create_infos[0] = std.mem.zeroes(c.VkDeviceQueueCreateInfo);
    queue_create_infos[0].sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queue_create_infos[0].queueFamilyIndex = indices.graphics_family;
    queue_create_infos[0].queueCount = 1;
    queue_create_infos[0].pQueuePriorities = &queue_priority;
    queue_create_info_count += 1;

    // Present queue (only if different)
    if (indices.graphics_family != indices.present_family) {
        queue_create_infos[1] = std.mem.zeroes(c.VkDeviceQueueCreateInfo);
        queue_create_infos[1].sType = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
        queue_create_infos[1].queueFamilyIndex = indices.present_family;
        queue_create_infos[1].queueCount = 1;
        queue_create_infos[1].pQueuePriorities = &queue_priority;
        queue_create_info_count += 1;
    }

    // Device features (none needed yet)
    const device_features = std.mem.zeroes(c.VkPhysicalDeviceFeatures);

    // Required extensions
    const device_extensions = [_][*c]const u8{
        c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    };

    // Create device
    var create_info = std.mem.zeroes(c.VkDeviceCreateInfo);
    create_info.sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    create_info.pQueueCreateInfos = &queue_create_infos;
    create_info.queueCreateInfoCount = queue_create_info_count;
    create_info.pEnabledFeatures = &device_features;
    create_info.enabledExtensionCount = device_extensions.len;
    create_info.ppEnabledExtensionNames = &device_extensions;

    // Validation layers (if enabled)
    const validation_layers = [_][*c]const u8{"VK_LAYER_KHRONOS_validation"};
    if (enable_validation) {
        create_info.enabledLayerCount = validation_layers.len;
        create_info.ppEnabledLayerNames = &validation_layers;
    }

    const result = c.vkCreateDevice(vk.physical_device, &create_info, null, &vk.device);
    if (result != c.VK_SUCCESS) {
        std.debug.print("Failed to create logical device: {d}\n", .{result});
        return false;
    }

    // Get queue handles
    c.vkGetDeviceQueue(vk.device, indices.graphics_family, 0, &vk.graphics_queue);
    c.vkGetDeviceQueue(vk.device, indices.present_family, 0, &vk.present_queue);

    return true;
}
```

---

### Step 3: Query Swap Chain Support

**New struct:**
```zig
const SwapChainSupportDetails = struct {
    capabilities: c.VkSurfaceCapabilitiesKHR = undefined,
    formats: []c.VkSurfaceFormatKHR = &.{},
    present_modes: []c.VkPresentModeKHR = &.{},

    fn deinit(self: *SwapChainSupportDetails, allocator: std.mem.Allocator) void {
        if (self.formats.len > 0) allocator.free(self.formats);
        if (self.present_modes.len > 0) allocator.free(self.present_modes);
    }
};
```

**New function:**
```zig
fn querySwapChainSupport(device: c.VkPhysicalDevice, surface: c.VkSurfaceKHR) SwapChainSupportDetails {
    const allocator = std.heap.c_allocator;
    var details = SwapChainSupportDetails{};

    _ = c.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device, surface, &details.capabilities);

    // Formats
    var format_count: u32 = 0;
    _ = c.vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &format_count, null);
    if (format_count > 0) {
        details.formats = allocator.alloc(c.VkSurfaceFormatKHR, format_count) catch return details;
        _ = c.vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &format_count, details.formats.ptr);
    }

    // Present modes
    var mode_count: u32 = 0;
    _ = c.vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &mode_count, null);
    if (mode_count > 0) {
        details.present_modes = allocator.alloc(c.VkPresentModeKHR, mode_count) catch return details;
        _ = c.vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &mode_count, details.present_modes.ptr);
    }

    return details;
}
```

---

### Step 4: Choose Swap Chain Settings

```zig
fn chooseSwapSurfaceFormat(formats: []c.VkSurfaceFormatKHR) c.VkSurfaceFormatKHR {
    for (formats) |format| {
        if (format.format == c.VK_FORMAT_B8G8R8A8_SRGB and
            format.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return format;
        }
    }
    return formats[0];
}

fn chooseSwapPresentMode(modes: []c.VkPresentModeKHR) c.VkPresentModeKHR {
    for (modes) |mode| {
        if (mode == c.VK_PRESENT_MODE_MAILBOX_KHR) {
            return mode;
        }
    }
    return c.VK_PRESENT_MODE_FIFO_KHR;
}

fn chooseSwapExtent(capabilities: c.VkSurfaceCapabilitiesKHR, window: ?*c.GLFWwindow) c.VkExtent2D {
    if (capabilities.currentExtent.width != std.math.maxInt(u32)) {
        return capabilities.currentExtent;
    }

    var width: c_int = 0;
    var height: c_int = 0;
    c.glfwGetFramebufferSize(window, &width, &height);

    var extent = c.VkExtent2D{
        .width = @intCast(width),
        .height = @intCast(height),
    };

    extent.width = @max(capabilities.minImageExtent.width,
                        @min(capabilities.maxImageExtent.width, extent.width));
    extent.height = @max(capabilities.minImageExtent.height,
                         @min(capabilities.maxImageExtent.height, extent.height));

    return extent;
}
```

---

### Step 5: Create Swap Chain

```zig
fn createSwapChain(vk: *VulkanState, window: ?*c.GLFWwindow) bool {
    const allocator = std.heap.c_allocator;
    var support = querySwapChainSupport(vk.physical_device, vk.surface);
    defer support.deinit(allocator);

    const surface_format = chooseSwapSurfaceFormat(support.formats);
    const present_mode = chooseSwapPresentMode(support.present_modes);
    const extent = chooseSwapExtent(support.capabilities, window);

    var image_count = support.capabilities.minImageCount + 1;
    if (support.capabilities.maxImageCount > 0 and
        image_count > support.capabilities.maxImageCount) {
        image_count = support.capabilities.maxImageCount;
    }

    var create_info = std.mem.zeroes(c.VkSwapchainCreateInfoKHR);
    create_info.sType = c.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    create_info.surface = vk.surface;
    create_info.minImageCount = image_count;
    create_info.imageFormat = surface_format.format;
    create_info.imageColorSpace = surface_format.colorSpace;
    create_info.imageExtent = extent;
    create_info.imageArrayLayers = 1;
    create_info.imageUsage = c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

    const queue_family_indices = [_]u32{ vk.graphics_family_index, vk.present_family_index };
    if (vk.graphics_family_index != vk.present_family_index) {
        create_info.imageSharingMode = c.VK_SHARING_MODE_CONCURRENT;
        create_info.queueFamilyIndexCount = 2;
        create_info.pQueueFamilyIndices = &queue_family_indices;
    } else {
        create_info.imageSharingMode = c.VK_SHARING_MODE_EXCLUSIVE;
    }

    create_info.preTransform = support.capabilities.currentTransform;
    create_info.compositeAlpha = c.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    create_info.presentMode = present_mode;
    create_info.clipped = c.VK_TRUE;
    create_info.oldSwapchain = null;

    if (c.vkCreateSwapchainKHR(vk.device, &create_info, null, &vk.swapchain) != c.VK_SUCCESS) {
        std.debug.print("Failed to create swap chain\n", .{});
        return false;
    }

    vk.swapchain_format = surface_format.format;
    vk.swapchain_extent = extent;

    // Get swap chain images
    _ = c.vkGetSwapchainImagesKHR(vk.device, vk.swapchain, &vk.swapchain_image_count, null);
    const images = allocator.alloc(c.VkImage, vk.swapchain_image_count) catch return false;
    vk.swapchain_images = images.ptr;
    _ = c.vkGetSwapchainImagesKHR(vk.device, vk.swapchain, &vk.swapchain_image_count, vk.swapchain_images);

    return true;
}
```

---

### Step 6: Create Image Views

```zig
fn createImageViews(vk: *VulkanState) bool {
    const allocator = std.heap.c_allocator;
    const views = allocator.alloc(c.VkImageView, vk.swapchain_image_count) catch return false;
    vk.swapchain_image_views = views.ptr;

    for (0..vk.swapchain_image_count) |i| {
        var create_info = std.mem.zeroes(c.VkImageViewCreateInfo);
        create_info.sType = c.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
        create_info.image = vk.swapchain_images.?[i];
        create_info.viewType = c.VK_IMAGE_VIEW_TYPE_2D;
        create_info.format = vk.swapchain_format;
        create_info.components.r = c.VK_COMPONENT_SWIZZLE_IDENTITY;
        create_info.components.g = c.VK_COMPONENT_SWIZZLE_IDENTITY;
        create_info.components.b = c.VK_COMPONENT_SWIZZLE_IDENTITY;
        create_info.components.a = c.VK_COMPONENT_SWIZZLE_IDENTITY;
        create_info.subresourceRange.aspectMask = c.VK_IMAGE_ASPECT_COLOR_BIT;
        create_info.subresourceRange.baseMipLevel = 0;
        create_info.subresourceRange.levelCount = 1;
        create_info.subresourceRange.baseArrayLayer = 0;
        create_info.subresourceRange.layerCount = 1;

        if (c.vkCreateImageView(vk.device, &create_info, null, &views[i]) != c.VK_SUCCESS) {
            std.debug.print("Failed to create image view {d}\n", .{i});
            return false;
        }
    }

    return true;
}
```

---

### Steps 7-12: Render Pass, Framebuffers, Commands, Sync, Render Loop

The remaining steps follow the same pattern:
1. Add new fields to VulkanState
2. Create initialization function
3. Update cleanup

**Fields to add:**
```zig
render_pass: c.VkRenderPass = null,
framebuffers: ?[*]c.VkFramebuffer = null,
command_pool: c.VkCommandPool = null,
command_buffers: ?[*]c.VkCommandBuffer = null,
image_available_semaphores: ?[*]c.VkSemaphore = null,
render_finished_semaphores: ?[*]c.VkSemaphore = null,
in_flight_fences: ?[*]c.VkFence = null,
```

**Constant:**
```zig
const max_frames_in_flight: u32 = 2;
```

See [vulkan-tutorial.com](https://vulkan-tutorial.com/Drawing_a_triangle) for detailed implementation of each step. The pattern is the same - translate C++ to Zig using:
- `std.mem.zeroes()` for zero-initialization
- `@intCast()` for integer type conversions
- Zig slices instead of pointer + count
- Error union returns (`!bool`) or bool with error printing

---

## Main Loop Update

```zig
var current_frame: u32 = 0;
while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
    c.glfwPollEvents();
    drawFrame(&vk, &current_frame);
}

// Wait for device to finish before cleanup
_ = c.vkDeviceWaitIdle(vk.device);
```

---

## Testing

### Expected Output
When you run the program:
1. Window opens
2. Shows dark blue color (0.0, 0.2, 0.4)
3. No validation errors in console
4. ESC key closes window cleanly

### Common Issues

**Black screen:**
- Check clear color is being set
- Verify render pass is executing
- Check framebuffer creation

**Validation errors:**
- Most common: incorrect synchronization
- Check semaphores/fences are used correctly
- Verify queue family indices

---

## Zig-Specific Tips

**Zero initialization:**
```zig
var info = std.mem.zeroes(c.VkSomeStructure);
```

**Pointer casting:**
```zig
const device_name: [*:0]const u8 = @ptrCast(&properties.deviceName);
```

**Integer casting:**
```zig
const index: u32 = @intCast(i);
```

**Optional pointer access:**
```zig
if (vk.swapchain_images) |images| {
    // use images[i]
}
```

**Error handling pattern:**
```zig
fn createSomething(vk: *VulkanState) bool {
    // ... do work ...
    if (result != c.VK_SUCCESS) {
        std.debug.print("Failed: {d}\n", .{result});
        return false;
    }
    return true;
}
```

---

## Resources

**Vulkan Tutorial:**
- Logical device: https://vulkan-tutorial.com/Drawing_a_triangle/Setup/Logical_device_and_queues
- Swap chain: https://vulkan-tutorial.com/Drawing_a_triangle/Presentation/Swap_chain
- Render pass: https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Render_passes
- Command buffers: https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Command_buffers

**Zig Resources:**
- [Zig Language Reference](https://ziglang.org/documentation/master/)
- [Zig std.mem](https://ziglang.org/documentation/master/std/#std.mem)

---

## Next Phase Preview

Once Phase 2 is complete (clear screen working):

**Phase 3 will add:**
- Vertex buffers (sphere vertices)
- Vertex/fragment shaders (GLSL)
- Graphics pipeline
- Phong lighting
- Camera matrices (view/projection)
- Ground plane with grid

But first - get that clear screen working!
