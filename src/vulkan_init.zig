// Vulkan initialization and cleanup functions
// Instance, device, swapchain, render pass, framebuffers

const std = @import("std");
const types = @import("types.zig");

const c = types.c;
const VulkanState = types.VulkanState;
const QueueFamilyIndices = types.QueueFamilyIndices;
const SwapChainSupportDetails = types.SwapChainSupportDetails;
const enable_validation = types.enable_validation;
const max_frames_in_flight = types.max_frames_in_flight;

// Create Vulkan instance
pub fn createVulkanInstance(vk: *VulkanState) bool {
    var app_info = std.mem.zeroes(c.VkApplicationInfo);
    app_info.sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app_info.pApplicationName = "Bidama Hajiki";
    app_info.applicationVersion = c.VK_MAKE_VERSION(1, 0, 0);
    app_info.pEngineName = "No Engine";
    app_info.engineVersion = c.VK_MAKE_VERSION(1, 0, 0);
    app_info.apiVersion = c.VK_API_VERSION_1_3;

    // Get required extensions from GLFW
    var glfw_extension_count: u32 = 0;
    const glfw_extensions = c.glfwGetRequiredInstanceExtensions(&glfw_extension_count);

    var create_info = std.mem.zeroes(c.VkInstanceCreateInfo);
    create_info.sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    create_info.pApplicationInfo = &app_info;
    create_info.enabledExtensionCount = glfw_extension_count;
    create_info.ppEnabledExtensionNames = glfw_extensions;

    // Enable validation layers in debug mode
    const validation_layers = [_][*c]const u8{"VK_LAYER_KHRONOS_validation"};
    if (enable_validation) {
        create_info.enabledLayerCount = validation_layers.len;
        create_info.ppEnabledLayerNames = &validation_layers;
    }

    const result = c.vkCreateInstance(&create_info, null, &vk.instance);
    if (result != c.VK_SUCCESS) {
        std.debug.print("Failed to create Vulkan instance: {d}\n", .{result});
        return false;
    }

    return true;
}

// Pick a physical device (GPU)
pub fn pickPhysicalDevice(vk: *VulkanState) bool {
    var device_count: u32 = 0;
    _ = c.vkEnumeratePhysicalDevices(vk.instance, &device_count, null);

    if (device_count == 0) {
        std.debug.print("No GPUs with Vulkan support found\n", .{});
        return false;
    }

    const allocator = std.heap.c_allocator;
    const devices = allocator.alloc(c.VkPhysicalDevice, device_count) catch {
        std.debug.print("Failed to allocate memory for devices\n", .{});
        return false;
    };
    defer allocator.free(devices);

    _ = c.vkEnumeratePhysicalDevices(vk.instance, &device_count, devices.ptr);

    // Just pick the first device for now
    // TODO: Score devices and pick the best one (discrete GPU preferred)
    vk.physical_device = devices[0];

    var properties: c.VkPhysicalDeviceProperties = undefined;
    c.vkGetPhysicalDeviceProperties(vk.physical_device, &properties);

    const device_name: [*:0]const u8 = @ptrCast(&properties.deviceName);
    std.debug.print("Using GPU: {s}\n", .{device_name});

    return true;
}

// Find queue families that support graphics and presentation
pub fn findQueueFamilies(device: c.VkPhysicalDevice, surface: c.VkSurfaceKHR) QueueFamilyIndices {
    var indices = QueueFamilyIndices{};

    var queue_family_count: u32 = 0;
    c.vkGetPhysicalDeviceQueueFamilyProperties(device, &queue_family_count, null);

    if (queue_family_count == 0) return indices;

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

// Query swap chain support details
pub fn querySwapChainSupport(device: c.VkPhysicalDevice, surface: c.VkSurfaceKHR) SwapChainSupportDetails {
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

fn chooseSwapSurfaceFormat(formats: []c.VkSurfaceFormatKHR) c.VkSurfaceFormatKHR {
    for (formats) |format| {
        if (format.format == c.VK_FORMAT_B8G8R8A8_SRGB and
            format.colorSpace == c.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
        {
            return format;
        }
    }
    return formats[0];
}

fn chooseSwapPresentMode(modes: []c.VkPresentModeKHR) c.VkPresentModeKHR {
    for (modes) |mode| {
        if (mode == c.VK_PRESENT_MODE_MAILBOX_KHR) {
            return mode; // Triple buffering
        }
    }
    return c.VK_PRESENT_MODE_FIFO_KHR; // VSync, always available
}

fn chooseSwapExtent(capabilities: c.VkSurfaceCapabilitiesKHR, window: ?*c.GLFWwindow) c.VkExtent2D {
    if (capabilities.currentExtent.width != std.math.maxInt(u32)) {
        return capabilities.currentExtent;
    }

    var width: c_int = 0;
    var height: c_int = 0;
    c.glfwGetFramebufferSize(window, &width, &height);

    return c.VkExtent2D{
        .width = @max(capabilities.minImageExtent.width, @min(capabilities.maxImageExtent.width, @as(u32, @intCast(width)))),
        .height = @max(capabilities.minImageExtent.height, @min(capabilities.maxImageExtent.height, @as(u32, @intCast(height)))),
    };
}

// Create swap chain
pub fn createSwapChain(vk: *VulkanState, window: ?*c.GLFWwindow) bool {
    const allocator = std.heap.c_allocator;
    var support = querySwapChainSupport(vk.physical_device, vk.surface);
    defer support.deinit();

    if (support.formats.len == 0 or support.present_modes.len == 0) {
        std.debug.print("Swap chain not adequately supported\n", .{});
        return false;
    }

    const surface_format = chooseSwapSurfaceFormat(support.formats);
    const present_mode = chooseSwapPresentMode(support.present_modes);
    const extent = chooseSwapExtent(support.capabilities, window);

    var image_count = support.capabilities.minImageCount + 1;
    if (support.capabilities.maxImageCount > 0 and image_count > support.capabilities.maxImageCount) {
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

    std.debug.print("Swap chain created with {d} images\n", .{vk.swapchain_image_count});
    return true;
}

// Create image views for swap chain images
pub fn createImageViews(vk: *VulkanState) bool {
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

    std.debug.print("Image views created\n", .{});
    return true;
}

// Create render pass
pub fn createRenderPass(vk: *VulkanState) bool {
    // Color attachment (swap chain image)
    var color_attachment = std.mem.zeroes(c.VkAttachmentDescription);
    color_attachment.format = vk.swapchain_format;
    color_attachment.samples = c.VK_SAMPLE_COUNT_1_BIT;
    color_attachment.loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR;
    color_attachment.storeOp = c.VK_ATTACHMENT_STORE_OP_STORE;
    color_attachment.stencilLoadOp = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    color_attachment.stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE;
    color_attachment.initialLayout = c.VK_IMAGE_LAYOUT_UNDEFINED;
    color_attachment.finalLayout = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

    // Attachment reference
    var color_attachment_ref = std.mem.zeroes(c.VkAttachmentReference);
    color_attachment_ref.attachment = 0;
    color_attachment_ref.layout = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

    // Subpass
    var subpass = std.mem.zeroes(c.VkSubpassDescription);
    subpass.pipelineBindPoint = c.VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.colorAttachmentCount = 1;
    subpass.pColorAttachments = &color_attachment_ref;

    // Subpass dependency
    var dependency = std.mem.zeroes(c.VkSubpassDependency);
    dependency.srcSubpass = c.VK_SUBPASS_EXTERNAL;
    dependency.dstSubpass = 0;
    dependency.srcStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    dependency.srcAccessMask = 0;
    dependency.dstStageMask = c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    dependency.dstAccessMask = c.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;

    // Create render pass
    var render_pass_info = std.mem.zeroes(c.VkRenderPassCreateInfo);
    render_pass_info.sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    render_pass_info.attachmentCount = 1;
    render_pass_info.pAttachments = &color_attachment;
    render_pass_info.subpassCount = 1;
    render_pass_info.pSubpasses = &subpass;
    render_pass_info.dependencyCount = 1;
    render_pass_info.pDependencies = &dependency;

    if (c.vkCreateRenderPass(vk.device, &render_pass_info, null, &vk.render_pass) != c.VK_SUCCESS) {
        std.debug.print("Failed to create render pass\n", .{});
        return false;
    }

    std.debug.print("Render pass created\n", .{});
    return true;
}

// Create framebuffers
pub fn createFramebuffers(vk: *VulkanState) bool {
    const allocator = std.heap.c_allocator;
    const fbs = allocator.alloc(c.VkFramebuffer, vk.swapchain_image_count) catch return false;
    vk.framebuffers = fbs.ptr;

    for (0..vk.swapchain_image_count) |i| {
        const attachments = [_]c.VkImageView{vk.swapchain_image_views.?[i]};

        var framebuffer_info = std.mem.zeroes(c.VkFramebufferCreateInfo);
        framebuffer_info.sType = c.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
        framebuffer_info.renderPass = vk.render_pass;
        framebuffer_info.attachmentCount = 1;
        framebuffer_info.pAttachments = &attachments;
        framebuffer_info.width = vk.swapchain_extent.width;
        framebuffer_info.height = vk.swapchain_extent.height;
        framebuffer_info.layers = 1;

        if (c.vkCreateFramebuffer(vk.device, &framebuffer_info, null, &fbs[i]) != c.VK_SUCCESS) {
            std.debug.print("Failed to create framebuffer {d}\n", .{i});
            return false;
        }
    }

    std.debug.print("Framebuffers created\n", .{});
    return true;
}

// Create logical device and get queue handles
pub fn createLogicalDevice(vk: *VulkanState) bool {
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

    // Present queue (only add if different from graphics)
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

    // Validation layers
    const validation_layers = [_][*c]const u8{"VK_LAYER_KHRONOS_validation"};

    // Create device
    var create_info = std.mem.zeroes(c.VkDeviceCreateInfo);
    create_info.sType = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    create_info.pQueueCreateInfos = &queue_create_infos;
    create_info.queueCreateInfoCount = queue_create_info_count;
    create_info.pEnabledFeatures = &device_features;
    create_info.enabledExtensionCount = device_extensions.len;
    create_info.ppEnabledExtensionNames = &device_extensions;

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

    std.debug.print("Logical device created\n", .{});
    return true;
}

// Cleanup all Vulkan resources
pub fn cleanupVulkan(vk: *VulkanState) void {
    const allocator = std.heap.c_allocator;

    // Sync objects
    if (vk.image_available_semaphores) |sems| {
        for (0..max_frames_in_flight) |i| {
            c.vkDestroySemaphore(vk.device, sems[i], null);
        }
        allocator.free(sems[0..max_frames_in_flight]);
    }
    if (vk.render_finished_semaphores) |sems| {
        for (0..max_frames_in_flight) |i| {
            c.vkDestroySemaphore(vk.device, sems[i], null);
        }
        allocator.free(sems[0..max_frames_in_flight]);
    }
    if (vk.in_flight_fences) |fences| {
        for (0..max_frames_in_flight) |i| {
            c.vkDestroyFence(vk.device, fences[i], null);
        }
        allocator.free(fences[0..max_frames_in_flight]);
    }

    // Command pool (frees command buffers automatically)
    if (vk.command_pool != null) {
        c.vkDestroyCommandPool(vk.device, vk.command_pool, null);
    }
    if (vk.command_buffers) |bufs| {
        allocator.free(bufs[0..max_frames_in_flight]);
    }

    // Vertex buffer
    if (vk.vertex_buffer != null) {
        c.vkDestroyBuffer(vk.device, vk.vertex_buffer, null);
    }
    if (vk.vertex_buffer_memory != null) {
        c.vkFreeMemory(vk.device, vk.vertex_buffer_memory, null);
    }

    // Uniform buffers
    if (vk.uniform_buffers) |bufs| {
        for (0..max_frames_in_flight) |i| {
            c.vkDestroyBuffer(vk.device, bufs[i], null);
        }
        allocator.free(bufs[0..max_frames_in_flight]);
    }
    if (vk.uniform_buffers_memory) |mems| {
        for (0..max_frames_in_flight) |i| {
            c.vkFreeMemory(vk.device, mems[i], null);
        }
        allocator.free(mems[0..max_frames_in_flight]);
    }
    if (vk.uniform_buffers_mapped) |mapped| {
        allocator.free(mapped[0..max_frames_in_flight]);
    }

    // Descriptor pool (frees descriptor sets automatically)
    if (vk.descriptor_pool != null) {
        c.vkDestroyDescriptorPool(vk.device, vk.descriptor_pool, null);
    }
    if (vk.descriptor_sets) |sets| {
        allocator.free(sets[0..max_frames_in_flight]);
    }

    // Descriptor set layout
    if (vk.descriptor_set_layout != null) {
        c.vkDestroyDescriptorSetLayout(vk.device, vk.descriptor_set_layout, null);
    }

    // Graphics pipeline
    if (vk.graphics_pipeline != null) {
        c.vkDestroyPipeline(vk.device, vk.graphics_pipeline, null);
    }
    if (vk.pipeline_layout != null) {
        c.vkDestroyPipelineLayout(vk.device, vk.pipeline_layout, null);
    }

    if (vk.framebuffers) |fbs| {
        for (0..vk.swapchain_image_count) |i| {
            c.vkDestroyFramebuffer(vk.device, fbs[i], null);
        }
        allocator.free(fbs[0..vk.swapchain_image_count]);
    }
    if (vk.render_pass != null) {
        c.vkDestroyRenderPass(vk.device, vk.render_pass, null);
    }
    if (vk.swapchain_image_views) |views| {
        for (0..vk.swapchain_image_count) |i| {
            c.vkDestroyImageView(vk.device, views[i], null);
        }
        allocator.free(views[0..vk.swapchain_image_count]);
    }
    if (vk.swapchain_images) |images| {
        allocator.free(images[0..vk.swapchain_image_count]);
    }
    if (vk.swapchain != null) {
        c.vkDestroySwapchainKHR(vk.device, vk.swapchain, null);
    }
    if (vk.device != null) {
        c.vkDestroyDevice(vk.device, null);
    }
    if (vk.surface != null) {
        c.vkDestroySurfaceKHR(vk.instance, vk.surface, null);
    }
    if (vk.instance != null) {
        c.vkDestroyInstance(vk.instance, null);
    }
}
