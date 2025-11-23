# Phase 2: Core Rendering Implementation Guide

**Goal:** Get Vulkan rendering working - clear screen to a solid color

**Success Criteria:**
- Window opens showing a solid color (not black/undefined)
- No Vulkan validation errors in console
- ESC key cleanly shuts down
- Code remains simple and understandable (C-style, no unnecessary abstraction)

---

## Current State (End of Session 002)

### What We Have
```cpp
struct VulkanState {
    VkInstance instance;           // ✅ Created
    VkSurfaceKHR surface;          // ✅ Created
    VkPhysicalDevice physical_device; // ✅ Selected
    VkDevice device;               // ❌ NULL
    VkQueue graphics_queue;        // ❌ NULL
    VkQueue present_queue;         // ❌ NULL
    VkSwapchainKHR swapchain;      // ❌ NULL
    VkFormat swapchain_format;
    VkExtent2D swapchain_extent;
    VkImage* swapchain_images;
    uint32_t swapchain_image_count;
    VkImageView* swapchain_image_views; // ❌ NULL
};
```

### Existing Functions
- `create_vulkan_instance()` - ✅ Working
- `pick_physical_device()` - ✅ Working (just picks first GPU)
- `cleanup_vulkan()` - ⚠️ Partial (only cleans initialized resources)

---

## Phase 2 Implementation Steps

### Step 1: Find Queue Families

**What:** Identify which queue families support graphics and presentation

**Why:** Vulkan queues are where we submit commands. We need:
- Graphics queue (for drawing commands)
- Present queue (for showing images on screen)
- They might be the same family, or different

**New struct:**
```cpp
struct QueueFamilyIndices {
    uint32_t graphics_family;
    uint32_t present_family;
    bool graphics_family_found;
    bool present_family_found;
};
```

**New function:**
```cpp
static QueueFamilyIndices find_queue_families(VkPhysicalDevice device, VkSurfaceKHR surface);
```

**Implementation details:**
1. Call `vkGetPhysicalDeviceQueueFamilyProperties()` to get count
2. Allocate array of `VkQueueFamilyProperties`
3. Call again to populate array
4. Loop through families:
   - Check `queueFlags & VK_QUEUE_GRAPHICS_BIT` for graphics support
   - Call `vkGetPhysicalDeviceSurfaceSupportKHR()` for present support
5. Return indices (store both even if same)

**Edge cases:**
- Graphics and present might be same queue family (common)
- Need to handle both cases

---

### Step 2: Create Logical Device

**What:** Create `VkDevice` (logical device) with required queues

**Why:** The logical device is our interface to the GPU. Physical device is just for querying capabilities.

**New function:**
```cpp
static bool create_logical_device(VulkanState* vk);
```

**Implementation details:**

1. Find queue families (call function from Step 1)

2. Create queue create infos:
```cpp
VkDeviceQueueCreateInfo queue_create_infos[2];
float queue_priority = 1.0f;
uint32_t queue_create_info_count = 0;

// Graphics queue
VkDeviceQueueCreateInfo graphics_queue_info = {};
graphics_queue_info.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
graphics_queue_info.queueFamilyIndex = indices.graphics_family;
graphics_queue_info.queueCount = 1;
graphics_queue_info.pQueuePriorities = &queue_priority;
queue_create_infos[queue_create_info_count++] = graphics_queue_info;

// Present queue (only if different from graphics)
if (indices.graphics_family != indices.present_family) {
    VkDeviceQueueCreateInfo present_queue_info = {};
    present_queue_info.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    present_queue_info.queueFamilyIndex = indices.present_family;
    present_queue_info.queueCount = 1;
    present_queue_info.pQueuePriorities = &queue_priority;
    queue_create_infos[queue_create_info_count++] = present_queue_info;
}
```

3. Specify device features (none needed yet):
```cpp
VkPhysicalDeviceFeatures device_features = {};
```

4. Required extensions:
```cpp
const char* device_extensions[] = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME  // Required for rendering to screen
};
```

5. Create device:
```cpp
VkDeviceCreateInfo create_info = {};
create_info.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
create_info.pQueueCreateInfos = queue_create_infos;
create_info.queueCreateInfoCount = queue_create_info_count;
create_info.pEnabledFeatures = &device_features;
create_info.enabledExtensionCount = 1;
create_info.ppEnabledExtensionNames = device_extensions;

// Enable validation layers in debug mode (same as instance)
if (ENABLE_VALIDATION) {
    create_info.enabledLayerCount = 1;
    create_info.ppEnabledLayerNames = validation_layers;
}

VkResult result = vkCreateDevice(vk->physical_device, &create_info, NULL, &vk->device);
```

6. Get queue handles:
```cpp
vkGetDeviceQueue(vk->device, indices.graphics_family, 0, &vk->graphics_queue);
vkGetDeviceQueue(vk->device, indices.present_family, 0, &vk->present_queue);
```

**Store queue family indices:** You'll need them for swap chain creation. Consider adding to VulkanState:
```cpp
struct VulkanState {
    // ... existing fields ...
    uint32_t graphics_family_index;
    uint32_t present_family_index;
};
```

---

### Step 3: Query Swap Chain Support

**What:** Check what formats, present modes, and capabilities the surface supports

**Why:** Need to know what options are available before creating swap chain

**New struct:**
```cpp
struct SwapChainSupportDetails {
    VkSurfaceCapabilitiesKHR capabilities;
    VkSurfaceFormatKHR* formats;
    uint32_t format_count;
    VkPresentModeKHR* present_modes;
    uint32_t present_mode_count;
};
```

**New function:**
```cpp
static SwapChainSupportDetails query_swap_chain_support(VkPhysicalDevice device, VkSurfaceKHR surface);
```

**Implementation:**
1. Get capabilities:
```cpp
vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device, surface, &details.capabilities);
```

2. Get formats:
```cpp
vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &details.format_count, NULL);
details.formats = malloc(sizeof(VkSurfaceFormatKHR) * details.format_count);
vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &details.format_count, details.formats);
```

3. Get present modes:
```cpp
vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &details.present_mode_count, NULL);
details.present_modes = malloc(sizeof(VkPresentModeKHR) * details.present_mode_count);
vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &details.present_mode_count, details.present_modes);
```

**Don't forget:** Free the allocated arrays when done with them

---

### Step 4: Choose Swap Chain Settings

**What:** Pick the best format, present mode, and extent from available options

**Surface Format:**
Prefer `VK_FORMAT_B8G8R8A8_SRGB` with `VK_COLOR_SPACE_SRGB_NONLINEAR_KHR`

```cpp
static VkSurfaceFormatKHR choose_swap_surface_format(VkSurfaceFormatKHR* formats, uint32_t format_count) {
    // Look for preferred format
    for (uint32_t i = 0; i < format_count; i++) {
        if (formats[i].format == VK_FORMAT_B8G8R8A8_SRGB &&
            formats[i].colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return formats[i];
        }
    }
    // Fall back to first available
    return formats[0];
}
```

**Present Mode:**
Prefer `VK_PRESENT_MODE_MAILBOX_KHR` (triple buffering), fall back to `VK_PRESENT_MODE_FIFO_KHR` (vsync, always available)

```cpp
static VkPresentModeKHR choose_swap_present_mode(VkPresentModeKHR* modes, uint32_t mode_count) {
    for (uint32_t i = 0; i < mode_count; i++) {
        if (modes[i] == VK_PRESENT_MODE_MAILBOX_KHR) {
            return modes[i];
        }
    }
    return VK_PRESENT_MODE_FIFO_KHR; // Always available
}
```

**Swap Extent (Resolution):**
Usually matches window size, but respect min/max from capabilities

```cpp
static VkExtent2D choose_swap_extent(VkSurfaceCapabilitiesKHR capabilities, GLFWwindow* window) {
    // If currentExtent is not the special value, use it
    if (capabilities.currentExtent.width != UINT32_MAX) {
        return capabilities.currentExtent;
    }

    // Otherwise, use window framebuffer size
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);

    VkExtent2D actual_extent = {
        (uint32_t)width,
        (uint32_t)height
    };

    // Clamp to min/max supported
    if (actual_extent.width < capabilities.minImageExtent.width) {
        actual_extent.width = capabilities.minImageExtent.width;
    }
    if (actual_extent.width > capabilities.maxImageExtent.width) {
        actual_extent.width = capabilities.maxImageExtent.width;
    }
    if (actual_extent.height < capabilities.minImageExtent.height) {
        actual_extent.height = capabilities.minImageExtent.height;
    }
    if (actual_extent.height > capabilities.maxImageExtent.height) {
        actual_extent.height = capabilities.maxImageExtent.height;
    }

    return actual_extent;
}
```

---

### Step 5: Create Swap Chain

**What:** Create the swap chain for presenting rendered images

**New function:**
```cpp
static bool create_swap_chain(VulkanState* vk, GLFWwindow* window);
```

**Implementation:**

1. Query swap chain support
2. Choose settings (format, present mode, extent)
3. Decide image count:
```cpp
uint32_t image_count = swap_chain_support.capabilities.minImageCount + 1;
if (swap_chain_support.capabilities.maxImageCount > 0 &&
    image_count > swap_chain_support.capabilities.maxImageCount) {
    image_count = swap_chain_support.capabilities.maxImageCount;
}
```

4. Create swap chain:
```cpp
VkSwapchainCreateInfoKHR create_info = {};
create_info.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
create_info.surface = vk->surface;
create_info.minImageCount = image_count;
create_info.imageFormat = surface_format.format;
create_info.imageColorSpace = surface_format.colorSpace;
create_info.imageExtent = extent;
create_info.imageArrayLayers = 1;
create_info.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

// If graphics and present families are different, use concurrent mode
uint32_t queue_family_indices[] = {
    vk->graphics_family_index,
    vk->present_family_index
};
if (vk->graphics_family_index != vk->present_family_index) {
    create_info.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
    create_info.queueFamilyIndexCount = 2;
    create_info.pQueueFamilyIndices = queue_family_indices;
} else {
    create_info.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
}

create_info.preTransform = swap_chain_support.capabilities.currentTransform;
create_info.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
create_info.presentMode = present_mode;
create_info.clipped = VK_TRUE;
create_info.oldSwapchain = VK_NULL_HANDLE;

VkResult result = vkCreateSwapchainKHR(vk->device, &create_info, NULL, &vk->swapchain);
```

5. Store format and extent in VulkanState:
```cpp
vk->swapchain_format = surface_format.format;
vk->swapchain_extent = extent;
```

6. Retrieve swap chain images:
```cpp
vkGetSwapchainImagesKHR(vk->device, vk->swapchain, &vk->swapchain_image_count, NULL);
vk->swapchain_images = malloc(sizeof(VkImage) * vk->swapchain_image_count);
vkGetSwapchainImagesKHR(vk->device, vk->swapchain, &vk->swapchain_image_count, vk->swapchain_images);
```

---

### Step 6: Create Image Views

**What:** Create VkImageView for each swap chain image

**Why:** Image views describe how to access images. We need them to use the swap chain images.

**New function:**
```cpp
static bool create_image_views(VulkanState* vk);
```

**Implementation:**
```cpp
vk->swapchain_image_views = malloc(sizeof(VkImageView) * vk->swapchain_image_count);

for (uint32_t i = 0; i < vk->swapchain_image_count; i++) {
    VkImageViewCreateInfo create_info = {};
    create_info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    create_info.image = vk->swapchain_images[i];
    create_info.viewType = VK_IMAGE_VIEW_TYPE_2D;
    create_info.format = vk->swapchain_format;

    // Component mapping (default/identity)
    create_info.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
    create_info.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
    create_info.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
    create_info.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;

    // Subresource range
    create_info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
    create_info.subresourceRange.baseMipLevel = 0;
    create_info.subresourceRange.levelCount = 1;
    create_info.subresourceRange.baseArrayLayer = 0;
    create_info.subresourceRange.layerCount = 1;

    VkResult result = vkCreateImageView(vk->device, &create_info, NULL, &vk->swapchain_image_views[i]);
    if (result != VK_SUCCESS) {
        fprintf(stderr, "Failed to create image view %d\n", i);
        return false;
    }
}
```

---

### Step 7: Create Render Pass

**What:** Describe the rendering operations and attachments

**Why:** Vulkan needs to know what we're rendering to and how to handle the images

**Add to VulkanState:**
```cpp
VkRenderPass render_pass;
```

**New function:**
```cpp
static bool create_render_pass(VulkanState* vk);
```

**Implementation:**
```cpp
// Color attachment (swap chain image)
VkAttachmentDescription color_attachment = {};
color_attachment.format = vk->swapchain_format;
color_attachment.samples = VK_SAMPLE_COUNT_1_BIT;
color_attachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;  // Clear before rendering
color_attachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE; // Store result
color_attachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
color_attachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
color_attachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
color_attachment.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

// Attachment reference
VkAttachmentReference color_attachment_ref = {};
color_attachment_ref.attachment = 0;
color_attachment_ref.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

// Subpass
VkSubpassDescription subpass = {};
subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
subpass.colorAttachmentCount = 1;
subpass.pColorAttachments = &color_attachment_ref;

// Subpass dependency (for image layout transitions)
VkSubpassDependency dependency = {};
dependency.srcSubpass = VK_SUBPASS_EXTERNAL;
dependency.dstSubpass = 0;
dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
dependency.srcAccessMask = 0;
dependency.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
dependency.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;

// Create render pass
VkRenderPassCreateInfo render_pass_info = {};
render_pass_info.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
render_pass_info.attachmentCount = 1;
render_pass_info.pAttachments = &color_attachment;
render_pass_info.subpassCount = 1;
render_pass_info.pSubpasses = &subpass;
render_pass_info.dependencyCount = 1;
render_pass_info.pDependencies = &dependency;

VkResult result = vkCreateRenderPass(vk->device, &render_pass_info, NULL, &vk->render_pass);
```

---

### Step 8: Create Framebuffers

**What:** Create framebuffers for each swap chain image view

**Why:** Framebuffers connect image views to render pass attachments

**Add to VulkanState:**
```cpp
VkFramebuffer* framebuffers;
```

**New function:**
```cpp
static bool create_framebuffers(VulkanState* vk);
```

**Implementation:**
```cpp
vk->framebuffers = malloc(sizeof(VkFramebuffer) * vk->swapchain_image_count);

for (uint32_t i = 0; i < vk->swapchain_image_count; i++) {
    VkImageView attachments[] = {
        vk->swapchain_image_views[i]
    };

    VkFramebufferCreateInfo framebuffer_info = {};
    framebuffer_info.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
    framebuffer_info.renderPass = vk->render_pass;
    framebuffer_info.attachmentCount = 1;
    framebuffer_info.pAttachments = attachments;
    framebuffer_info.width = vk->swapchain_extent.width;
    framebuffer_info.height = vk->swapchain_extent.height;
    framebuffer_info.layers = 1;

    VkResult result = vkCreateFramebuffer(vk->device, &framebuffer_info, NULL, &vk->framebuffers[i]);
    if (result != VK_SUCCESS) {
        fprintf(stderr, "Failed to create framebuffer %d\n", i);
        return false;
    }
}
```

---

### Step 9: Create Command Pool

**What:** Create command pool for allocating command buffers

**Why:** Command buffers are allocated from pools. Pool manages memory for commands.

**Add to VulkanState:**
```cpp
VkCommandPool command_pool;
```

**New function:**
```cpp
static bool create_command_pool(VulkanState* vk);
```

**Implementation:**
```cpp
VkCommandPoolCreateInfo pool_info = {};
pool_info.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
pool_info.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
pool_info.queueFamilyIndex = vk->graphics_family_index;

VkResult result = vkCreateCommandPool(vk->device, &pool_info, NULL, &vk->command_pool);
```

---

### Step 10: Create Command Buffers

**What:** Allocate command buffers (one per frame in flight)

**Why:** Command buffers record rendering commands

**Add to VulkanState:**
```cpp
VkCommandBuffer* command_buffers;
```

**Define constant:**
```cpp
const int MAX_FRAMES_IN_FLIGHT = 2;  // Double buffering
```

**New function:**
```cpp
static bool create_command_buffers(VulkanState* vk);
```

**Implementation:**
```cpp
vk->command_buffers = malloc(sizeof(VkCommandBuffer) * MAX_FRAMES_IN_FLIGHT);

VkCommandBufferAllocateInfo alloc_info = {};
alloc_info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
alloc_info.commandPool = vk->command_pool;
alloc_info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
alloc_info.commandBufferCount = MAX_FRAMES_IN_FLIGHT;

VkResult result = vkAllocateCommandBuffers(vk->device, &alloc_info, vk->command_buffers);
```

---

### Step 11: Create Synchronization Objects

**What:** Create semaphores and fences for frame synchronization

**Why:** Need to coordinate:
- When image is available from swap chain
- When rendering is finished
- When we can reuse command buffers

**Add to VulkanState:**
```cpp
VkSemaphore* image_available_semaphores;
VkSemaphore* render_finished_semaphores;
VkFence* in_flight_fences;
```

**New function:**
```cpp
static bool create_sync_objects(VulkanState* vk);
```

**Implementation:**
```cpp
vk->image_available_semaphores = malloc(sizeof(VkSemaphore) * MAX_FRAMES_IN_FLIGHT);
vk->render_finished_semaphores = malloc(sizeof(VkSemaphore) * MAX_FRAMES_IN_FLIGHT);
vk->in_flight_fences = malloc(sizeof(VkFence) * MAX_FRAMES_IN_FLIGHT);

VkSemaphoreCreateInfo semaphore_info = {};
semaphore_info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

VkFenceCreateInfo fence_info = {};
fence_info.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
fence_info.flags = VK_FENCE_CREATE_SIGNALED_BIT; // Start signaled

for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
    if (vkCreateSemaphore(vk->device, &semaphore_info, NULL, &vk->image_available_semaphores[i]) != VK_SUCCESS ||
        vkCreateSemaphore(vk->device, &semaphore_info, NULL, &vk->render_finished_semaphores[i]) != VK_SUCCESS ||
        vkCreateFence(vk->device, &fence_info, NULL, &vk->in_flight_fences[i]) != VK_SUCCESS) {
        fprintf(stderr, "Failed to create synchronization objects for frame %d\n", i);
        return false;
    }
}
```

---

### Step 12: Implement Render Loop

**What:** Record commands and submit each frame

**New function:**
```cpp
static void record_command_buffer(VulkanState* vk, VkCommandBuffer command_buffer, uint32_t image_index);
```

**Command buffer recording:**
```cpp
// Begin command buffer
VkCommandBufferBeginInfo begin_info = {};
begin_info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
vkBeginCommandBuffer(command_buffer, &begin_info);

// Begin render pass
VkRenderPassBeginInfo render_pass_info = {};
render_pass_info.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
render_pass_info.renderPass = vk->render_pass;
render_pass_info.framebuffer = vk->framebuffers[image_index];
render_pass_info.renderArea.offset = (VkOffset2D){0, 0};
render_pass_info.renderArea.extent = vk->swapchain_extent;

// Clear color (dark blue to prove it's working)
VkClearValue clear_color = {{{0.0f, 0.2f, 0.4f, 1.0f}}};
render_pass_info.clearValueCount = 1;
render_pass_info.pClearValues = &clear_color;

vkCmdBeginRenderPass(command_buffer, &render_pass_info, VK_SUBPASS_CONTENTS_INLINE);

// No draw commands yet - just clearing

vkCmdEndRenderPass(command_buffer);
vkEndCommandBuffer(command_buffer);
```

**Main render loop function:**
```cpp
static void draw_frame(VulkanState* vk, uint32_t* current_frame);
```

**Implementation:**
```cpp
// Wait for previous frame
vkWaitForFences(vk->device, 1, &vk->in_flight_fences[*current_frame], VK_TRUE, UINT64_MAX);
vkResetFences(vk->device, 1, &vk->in_flight_fences[*current_frame]);

// Acquire image
uint32_t image_index;
vkAcquireNextImageKHR(vk->device, vk->swapchain, UINT64_MAX,
                      vk->image_available_semaphores[*current_frame],
                      VK_NULL_HANDLE, &image_index);

// Reset and record command buffer
vkResetCommandBuffer(vk->command_buffers[*current_frame], 0);
record_command_buffer(vk, vk->command_buffers[*current_frame], image_index);

// Submit command buffer
VkSubmitInfo submit_info = {};
submit_info.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;

VkSemaphore wait_semaphores[] = {vk->image_available_semaphores[*current_frame]};
VkPipelineStageFlags wait_stages[] = {VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};
submit_info.waitSemaphoreCount = 1;
submit_info.pWaitSemaphores = wait_semaphores;
submit_info.pWaitDstStageMask = wait_stages;
submit_info.commandBufferCount = 1;
submit_info.pCommandBuffers = &vk->command_buffers[*current_frame];

VkSemaphore signal_semaphores[] = {vk->render_finished_semaphores[*current_frame]};
submit_info.signalSemaphoreCount = 1;
submit_info.pSignalSemaphores = signal_semaphores;

vkQueueSubmit(vk->graphics_queue, 1, &submit_info, vk->in_flight_fences[*current_frame]);

// Present
VkPresentInfoKHR present_info = {};
present_info.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
present_info.waitSemaphoreCount = 1;
present_info.pWaitSemaphores = signal_semaphores;

VkSwapchainKHR swapchains[] = {vk->swapchain};
present_info.swapchainCount = 1;
present_info.pSwapchains = swapchains;
present_info.pImageIndices = &image_index;

vkQueuePresentKHR(vk->present_queue, &present_info);

// Advance frame
*current_frame = (*current_frame + 1) % MAX_FRAMES_IN_FLIGHT;
```

**Update main loop:**
```cpp
uint32_t current_frame = 0;
while (!glfwWindowShouldClose(window)) {
    glfwPollEvents();
    draw_frame(&vk, &current_frame);
}

// Wait for device to finish before cleanup
vkDeviceWaitIdle(vk.device);
```

---

### Step 13: Update Cleanup

**Update cleanup_vulkan()** to handle all new resources:
```cpp
static void cleanup_vulkan(VulkanState* vk) {
    // Sync objects
    if (vk->image_available_semaphores) {
        for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
            vkDestroySemaphore(vk->device, vk->image_available_semaphores[i], NULL);
            vkDestroySemaphore(vk->device, vk->render_finished_semaphores[i], NULL);
            vkDestroyFence(vk->device, vk->in_flight_fences[i], NULL);
        }
        free(vk->image_available_semaphores);
        free(vk->render_finished_semaphores);
        free(vk->in_flight_fences);
    }

    // Command pool (frees command buffers automatically)
    if (vk->command_pool) {
        vkDestroyCommandPool(vk->device, vk->command_pool, NULL);
    }
    if (vk->command_buffers) {
        free(vk->command_buffers);
    }

    // Framebuffers
    if (vk->framebuffers) {
        for (uint32_t i = 0; i < vk->swapchain_image_count; i++) {
            vkDestroyFramebuffer(vk->device, vk->framebuffers[i], NULL);
        }
        free(vk->framebuffers);
    }

    // Render pass
    if (vk->render_pass) {
        vkDestroyRenderPass(vk->device, vk->render_pass, NULL);
    }

    // Image views
    if (vk->swapchain_image_views) {
        for (uint32_t i = 0; i < vk->swapchain_image_count; i++) {
            vkDestroyImageView(vk->device, vk->swapchain_image_views[i], NULL);
        }
        free(vk->swapchain_image_views);
    }

    // Swap chain images (don't destroy - owned by swap chain)
    if (vk->swapchain_images) {
        free(vk->swapchain_images);
    }

    // Swap chain
    if (vk->swapchain) {
        vkDestroySwapchainKHR(vk->device, vk->swapchain, NULL);
    }

    // Device
    if (vk->device) {
        vkDestroyDevice(vk->device, NULL);
    }

    // Surface
    if (vk->surface) {
        vkDestroySurfaceKHR(vk->instance, vk->surface, NULL);
    }

    // Instance
    if (vk->instance) {
        vkDestroyInstance(vk->instance, NULL);
    }
}
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

**Crash on cleanup:**
- Ensure all resources cleaned in reverse order of creation
- Check for NULL before destroying
- Must call `vkDeviceWaitIdle()` before cleanup

---

## Code Organization Tips

**Keep it simple:**
- All functions static in main.cpp for now
- No need for separate files yet
- Clear function names describe what they do

**Error handling:**
- Check VkResult for VK_SUCCESS
- Print informative error messages
- Return false from initialization functions on error

**Memory management:**
- malloc/free for dynamic arrays
- Free swap chain support details after use
- Don't leak memory on error paths

---

## Resources

**Vulkan Tutorial:**
- Logical device: https://vulkan-tutorial.com/Drawing_a_triangle/Setup/Logical_device_and_queues
- Swap chain: https://vulkan-tutorial.com/Drawing_a_triangle/Presentation/Swap_chain
- Render pass: https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Render_passes
- Command buffers: https://vulkan-tutorial.com/Drawing_a_triangle/Drawing/Command_buffers

**Vulkan Spec:**
- Check function signatures/parameters

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

But first - get that clear screen working! 🎨
