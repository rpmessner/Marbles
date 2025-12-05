// Bidama Hajiki (ビー玉弾き) - A marble flicking game
// Inspired by the zeni hajiki minigame from Ghost of Yotei
// Simple, direct code - data-oriented, minimal abstraction
// Modern Vulkan API for RTX ray tracing

const std = @import("std");

const c = @cImport({
    @cDefine("GLFW_INCLUDE_VULKAN", "1");
    @cInclude("GLFW/glfw3.h");
});

// --- Configuration ---
const window_width: u32 = 1024;
const window_height: u32 = 768;
const window_title = "Bidama Hajiki";
const enable_validation = true;
const max_frames_in_flight: u32 = 2;

// --- Math Utilities ---
const Vec3 = struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }

    fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }

    fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }

    fn normalize(v: Vec3) Vec3 {
        const len = @sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
        if (len == 0) return v;
        return .{ .x = v.x / len, .y = v.y / len, .z = v.z / len };
    }
};

const Mat4 = struct {
    data: [16]f32 = [_]f32{0} ** 16,

    fn identity() Mat4 {
        var m = Mat4{};
        m.data[0] = 1;
        m.data[5] = 1;
        m.data[10] = 1;
        m.data[15] = 1;
        return m;
    }

    fn multiply(a: Mat4, b: Mat4) Mat4 {
        var result = Mat4{};
        for (0..4) |row| {
            for (0..4) |col| {
                var sum: f32 = 0;
                for (0..4) |k| {
                    sum += a.data[row * 4 + k] * b.data[k * 4 + col];
                }
                result.data[row * 4 + col] = sum;
            }
        }
        return result;
    }

    fn perspective(fov_radians: f32, aspect: f32, near: f32, far: f32) Mat4 {
        var m = Mat4{};
        const tan_half_fov = @tan(fov_radians / 2.0);
        m.data[0] = 1.0 / (aspect * tan_half_fov);
        m.data[5] = 1.0 / tan_half_fov;
        m.data[10] = -(far + near) / (far - near);
        m.data[11] = -1.0;
        m.data[14] = -(2.0 * far * near) / (far - near);
        return m;
    }

    fn lookAt(eye: Vec3, center: Vec3, up: Vec3) Mat4 {
        const f = Vec3.normalize(Vec3.sub(center, eye));
        const s = Vec3.normalize(Vec3.cross(f, up));
        const u = Vec3.cross(s, f);

        var m = Mat4.identity();
        m.data[0] = s.x;
        m.data[4] = s.y;
        m.data[8] = s.z;
        m.data[1] = u.x;
        m.data[5] = u.y;
        m.data[9] = u.z;
        m.data[2] = -f.x;
        m.data[6] = -f.y;
        m.data[10] = -f.z;
        m.data[12] = -Vec3.dot(s, eye);
        m.data[13] = -Vec3.dot(u, eye);
        m.data[14] = Vec3.dot(f, eye);
        return m;
    }

    fn rotateZ(angle: f32) Mat4 {
        var m = Mat4.identity();
        const cos_a = @cos(angle);
        const sin_a = @sin(angle);
        m.data[0] = cos_a;
        m.data[1] = sin_a;
        m.data[4] = -sin_a;
        m.data[5] = cos_a;
        return m;
    }
};

// Uniform buffer object - sent to shaders
const UniformBufferObject = struct {
    model: Mat4 = Mat4.identity(),
    view: Mat4 = Mat4.identity(),
    proj: Mat4 = Mat4.identity(),
};

// --- Queue Family Indices ---
const QueueFamilyIndices = struct {
    graphics_family: u32 = 0,
    present_family: u32 = 0,
    graphics_found: bool = false,
    present_found: bool = false,

    fn isComplete(self: QueueFamilyIndices) bool {
        return self.graphics_found and self.present_found;
    }
};

// --- Vulkan State ---
// No classes, no wrappers - just plain data
const VulkanState = struct {
    instance: c.VkInstance = null,
    surface: c.VkSurfaceKHR = null,
    physical_device: c.VkPhysicalDevice = null,
    device: c.VkDevice = null,
    graphics_queue: c.VkQueue = null,
    present_queue: c.VkQueue = null,
    graphics_family_index: u32 = 0,
    present_family_index: u32 = 0,
    swapchain: c.VkSwapchainKHR = null,
    swapchain_format: c.VkFormat = c.VK_FORMAT_UNDEFINED,
    swapchain_extent: c.VkExtent2D = .{ .width = 0, .height = 0 },
    swapchain_images: ?[*]c.VkImage = null,
    swapchain_image_count: u32 = 0,
    swapchain_image_views: ?[*]c.VkImageView = null,
    render_pass: c.VkRenderPass = null,
    framebuffers: ?[*]c.VkFramebuffer = null,
    command_pool: c.VkCommandPool = null,
    command_buffers: ?[*]c.VkCommandBuffer = null,
    image_available_semaphores: ?[*]c.VkSemaphore = null,
    render_finished_semaphores: ?[*]c.VkSemaphore = null,
    in_flight_fences: ?[*]c.VkFence = null,
    // Graphics pipeline
    pipeline_layout: c.VkPipelineLayout = null,
    graphics_pipeline: c.VkPipeline = null,
    // Vertex buffer
    vertex_buffer: c.VkBuffer = null,
    vertex_buffer_memory: c.VkDeviceMemory = null,
    // Uniform buffers (one per frame in flight)
    uniform_buffers: ?[*]c.VkBuffer = null,
    uniform_buffers_memory: ?[*]c.VkDeviceMemory = null,
    uniform_buffers_mapped: ?[*]?*anyopaque = null,
    // Descriptors
    descriptor_set_layout: c.VkDescriptorSetLayout = null,
    descriptor_pool: c.VkDescriptorPool = null,
    descriptor_sets: ?[*]c.VkDescriptorSet = null,
};

// --- Helper Functions ---

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.c) void {
    std.debug.print("GLFW Error {d}: {s}\n", .{ err, description });
}

fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void {
    _ = scancode;
    _ = mods;
    if (key == c.GLFW_KEY_ESCAPE and action == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
}

// Create Vulkan instance
fn createVulkanInstance(vk: *VulkanState) bool {
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
fn pickPhysicalDevice(vk: *VulkanState) bool {
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
fn findQueueFamilies(device: c.VkPhysicalDevice, surface: c.VkSurfaceKHR) QueueFamilyIndices {
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

// --- Swap Chain Support ---
const SwapChainSupportDetails = struct {
    capabilities: c.VkSurfaceCapabilitiesKHR = undefined,
    formats: []c.VkSurfaceFormatKHR = &.{},
    present_modes: []c.VkPresentModeKHR = &.{},

    fn deinit(self: *SwapChainSupportDetails) void {
        const allocator = std.heap.c_allocator;
        if (self.formats.len > 0) allocator.free(self.formats);
        if (self.present_modes.len > 0) allocator.free(self.present_modes);
    }
};

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
fn createSwapChain(vk: *VulkanState, window: ?*c.GLFWwindow) bool {
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

    std.debug.print("Image views created\n", .{});
    return true;
}

// Create render pass
fn createRenderPass(vk: *VulkanState) bool {
    // Color attachment (swap chain image)
    var color_attachment = std.mem.zeroes(c.VkAttachmentDescription);
    color_attachment.format = vk.swapchain_format;
    color_attachment.samples = c.VK_SAMPLE_COUNT_1_BIT;
    color_attachment.loadOp = c.VK_ATTACHMENT_LOAD_OP_CLEAR; // Clear before rendering
    color_attachment.storeOp = c.VK_ATTACHMENT_STORE_OP_STORE; // Store result
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
fn createFramebuffers(vk: *VulkanState) bool {
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

// Create shader module from embedded SPIR-V
fn createShaderModule(device: c.VkDevice, code: []const u8) c.VkShaderModule {
    var create_info = std.mem.zeroes(c.VkShaderModuleCreateInfo);
    create_info.sType = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    create_info.codeSize = code.len;
    create_info.pCode = @ptrCast(@alignCast(code.ptr));

    var shader_module: c.VkShaderModule = null;
    if (c.vkCreateShaderModule(device, &create_info, null, &shader_module) != c.VK_SUCCESS) {
        std.debug.print("Failed to create shader module\n", .{});
        return null;
    }
    return shader_module;
}

// Vertex data - simple 2D triangle
const Vertex = struct {
    pos: [2]f32,
};

const vertices = [_]Vertex{
    .{ .pos = .{ 0.0, -0.5 } }, // top
    .{ .pos = .{ 0.5, 0.5 } }, // bottom right
    .{ .pos = .{ -0.5, 0.5 } }, // bottom left
};

// Create graphics pipeline
fn createGraphicsPipeline(vk: *VulkanState) bool {
    // Load shaders (embedded at compile time)
    const vert_code = @embedFile("shaders/triangle.vert.spv");
    const frag_code = @embedFile("shaders/triangle.frag.spv");

    const vert_module = createShaderModule(vk.device, vert_code);
    const frag_module = createShaderModule(vk.device, frag_code);
    defer c.vkDestroyShaderModule(vk.device, vert_module, null);
    defer c.vkDestroyShaderModule(vk.device, frag_module, null);

    if (vert_module == null or frag_module == null) {
        std.debug.print("Failed to create shader modules\n", .{});
        return false;
    }

    // Shader stages
    var vert_stage = std.mem.zeroes(c.VkPipelineShaderStageCreateInfo);
    vert_stage.sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    vert_stage.stage = c.VK_SHADER_STAGE_VERTEX_BIT;
    vert_stage.module = vert_module;
    vert_stage.pName = "main";

    var frag_stage = std.mem.zeroes(c.VkPipelineShaderStageCreateInfo);
    frag_stage.sType = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    frag_stage.stage = c.VK_SHADER_STAGE_FRAGMENT_BIT;
    frag_stage.module = frag_module;
    frag_stage.pName = "main";

    const shader_stages = [_]c.VkPipelineShaderStageCreateInfo{ vert_stage, frag_stage };

    // Vertex input - describe our Vertex struct
    var binding_desc = std.mem.zeroes(c.VkVertexInputBindingDescription);
    binding_desc.binding = 0;
    binding_desc.stride = @sizeOf(Vertex);
    binding_desc.inputRate = c.VK_VERTEX_INPUT_RATE_VERTEX;

    var attr_desc = std.mem.zeroes(c.VkVertexInputAttributeDescription);
    attr_desc.binding = 0;
    attr_desc.location = 0;
    attr_desc.format = c.VK_FORMAT_R32G32_SFLOAT;
    attr_desc.offset = 0;

    var vertex_input = std.mem.zeroes(c.VkPipelineVertexInputStateCreateInfo);
    vertex_input.sType = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    vertex_input.vertexBindingDescriptionCount = 1;
    vertex_input.pVertexBindingDescriptions = &binding_desc;
    vertex_input.vertexAttributeDescriptionCount = 1;
    vertex_input.pVertexAttributeDescriptions = &attr_desc;

    // Input assembly
    var input_assembly = std.mem.zeroes(c.VkPipelineInputAssemblyStateCreateInfo);
    input_assembly.sType = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    input_assembly.topology = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    input_assembly.primitiveRestartEnable = c.VK_FALSE;

    // Viewport and scissor (dynamic)
    var viewport = c.VkViewport{
        .x = 0.0,
        .y = 0.0,
        .width = @floatFromInt(vk.swapchain_extent.width),
        .height = @floatFromInt(vk.swapchain_extent.height),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };

    var scissor = c.VkRect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = vk.swapchain_extent,
    };

    var viewport_state = std.mem.zeroes(c.VkPipelineViewportStateCreateInfo);
    viewport_state.sType = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    viewport_state.viewportCount = 1;
    viewport_state.pViewports = &viewport;
    viewport_state.scissorCount = 1;
    viewport_state.pScissors = &scissor;

    // Dynamic state - viewport and scissor will be set at draw time
    const dynamic_states = [_]c.VkDynamicState{
        c.VK_DYNAMIC_STATE_VIEWPORT,
        c.VK_DYNAMIC_STATE_SCISSOR,
    };
    var dynamic_state = std.mem.zeroes(c.VkPipelineDynamicStateCreateInfo);
    dynamic_state.sType = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
    dynamic_state.dynamicStateCount = dynamic_states.len;
    dynamic_state.pDynamicStates = &dynamic_states;

    // Rasterizer
    var rasterizer = std.mem.zeroes(c.VkPipelineRasterizationStateCreateInfo);
    rasterizer.sType = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    rasterizer.depthClampEnable = c.VK_FALSE;
    rasterizer.rasterizerDiscardEnable = c.VK_FALSE;
    rasterizer.polygonMode = c.VK_POLYGON_MODE_FILL;
    rasterizer.lineWidth = 1.0;
    rasterizer.cullMode = c.VK_CULL_MODE_BACK_BIT;
    rasterizer.frontFace = c.VK_FRONT_FACE_CLOCKWISE;
    rasterizer.depthBiasEnable = c.VK_FALSE;

    // Multisampling (disabled)
    var multisampling = std.mem.zeroes(c.VkPipelineMultisampleStateCreateInfo);
    multisampling.sType = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    multisampling.sampleShadingEnable = c.VK_FALSE;
    multisampling.rasterizationSamples = c.VK_SAMPLE_COUNT_1_BIT;

    // Color blending
    var color_blend_attachment = std.mem.zeroes(c.VkPipelineColorBlendAttachmentState);
    color_blend_attachment.colorWriteMask = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT |
        c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT;
    color_blend_attachment.blendEnable = c.VK_FALSE;

    var color_blending = std.mem.zeroes(c.VkPipelineColorBlendStateCreateInfo);
    color_blending.sType = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    color_blending.logicOpEnable = c.VK_FALSE;
    color_blending.attachmentCount = 1;
    color_blending.pAttachments = &color_blend_attachment;

    // Pipeline layout - include descriptor set layout for uniform buffer
    var pipeline_layout_info = std.mem.zeroes(c.VkPipelineLayoutCreateInfo);
    pipeline_layout_info.sType = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    pipeline_layout_info.setLayoutCount = 1;
    pipeline_layout_info.pSetLayouts = &vk.descriptor_set_layout;

    if (c.vkCreatePipelineLayout(vk.device, &pipeline_layout_info, null, &vk.pipeline_layout) != c.VK_SUCCESS) {
        std.debug.print("Failed to create pipeline layout\n", .{});
        return false;
    }

    // Create the graphics pipeline
    var pipeline_info = std.mem.zeroes(c.VkGraphicsPipelineCreateInfo);
    pipeline_info.sType = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    pipeline_info.stageCount = 2;
    pipeline_info.pStages = &shader_stages;
    pipeline_info.pVertexInputState = &vertex_input;
    pipeline_info.pInputAssemblyState = &input_assembly;
    pipeline_info.pViewportState = &viewport_state;
    pipeline_info.pRasterizationState = &rasterizer;
    pipeline_info.pMultisampleState = &multisampling;
    pipeline_info.pColorBlendState = &color_blending;
    pipeline_info.pDynamicState = &dynamic_state;
    pipeline_info.layout = vk.pipeline_layout;
    pipeline_info.renderPass = vk.render_pass;
    pipeline_info.subpass = 0;

    if (c.vkCreateGraphicsPipelines(vk.device, null, 1, &pipeline_info, null, &vk.graphics_pipeline) != c.VK_SUCCESS) {
        std.debug.print("Failed to create graphics pipeline\n", .{});
        return false;
    }

    std.debug.print("Graphics pipeline created\n", .{});
    return true;
}

// Find memory type for buffer allocation
fn findMemoryType(vk: *VulkanState, type_filter: u32, properties: c.VkMemoryPropertyFlags) ?u32 {
    var mem_properties: c.VkPhysicalDeviceMemoryProperties = undefined;
    c.vkGetPhysicalDeviceMemoryProperties(vk.physical_device, &mem_properties);

    for (0..mem_properties.memoryTypeCount) |i| {
        const idx: u5 = @intCast(i);
        if ((type_filter & (@as(u32, 1) << idx)) != 0 and
            (mem_properties.memoryTypes[i].propertyFlags & properties) == properties)
        {
            return @intCast(i);
        }
    }
    return null;
}

// Create vertex buffer
fn createVertexBuffer(vk: *VulkanState) bool {
    const buffer_size: c.VkDeviceSize = @sizeOf(@TypeOf(vertices));

    // Create buffer
    var buffer_info = std.mem.zeroes(c.VkBufferCreateInfo);
    buffer_info.sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    buffer_info.size = buffer_size;
    buffer_info.usage = c.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
    buffer_info.sharingMode = c.VK_SHARING_MODE_EXCLUSIVE;

    if (c.vkCreateBuffer(vk.device, &buffer_info, null, &vk.vertex_buffer) != c.VK_SUCCESS) {
        std.debug.print("Failed to create vertex buffer\n", .{});
        return false;
    }

    // Get memory requirements
    var mem_requirements: c.VkMemoryRequirements = undefined;
    c.vkGetBufferMemoryRequirements(vk.device, vk.vertex_buffer, &mem_requirements);

    // Allocate memory
    var alloc_info = std.mem.zeroes(c.VkMemoryAllocateInfo);
    alloc_info.sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    alloc_info.allocationSize = mem_requirements.size;
    alloc_info.memoryTypeIndex = findMemoryType(
        vk,
        mem_requirements.memoryTypeBits,
        c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
    ) orelse {
        std.debug.print("Failed to find suitable memory type\n", .{});
        return false;
    };

    if (c.vkAllocateMemory(vk.device, &alloc_info, null, &vk.vertex_buffer_memory) != c.VK_SUCCESS) {
        std.debug.print("Failed to allocate vertex buffer memory\n", .{});
        return false;
    }

    // Bind buffer to memory
    _ = c.vkBindBufferMemory(vk.device, vk.vertex_buffer, vk.vertex_buffer_memory, 0);

    // Copy vertex data to buffer
    var data: ?*anyopaque = null;
    _ = c.vkMapMemory(vk.device, vk.vertex_buffer_memory, 0, buffer_size, 0, &data);
    @memcpy(@as([*]u8, @ptrCast(data))[0..@sizeOf(@TypeOf(vertices))], std.mem.asBytes(&vertices));
    c.vkUnmapMemory(vk.device, vk.vertex_buffer_memory);

    std.debug.print("Vertex buffer created\n", .{});
    return true;
}

// Create descriptor set layout - describes the uniform buffer binding
fn createDescriptorSetLayout(vk: *VulkanState) bool {
    var ubo_layout_binding = std.mem.zeroes(c.VkDescriptorSetLayoutBinding);
    ubo_layout_binding.binding = 0;
    ubo_layout_binding.descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    ubo_layout_binding.descriptorCount = 1;
    ubo_layout_binding.stageFlags = c.VK_SHADER_STAGE_VERTEX_BIT;

    var layout_info = std.mem.zeroes(c.VkDescriptorSetLayoutCreateInfo);
    layout_info.sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    layout_info.bindingCount = 1;
    layout_info.pBindings = &ubo_layout_binding;

    if (c.vkCreateDescriptorSetLayout(vk.device, &layout_info, null, &vk.descriptor_set_layout) != c.VK_SUCCESS) {
        std.debug.print("Failed to create descriptor set layout\n", .{});
        return false;
    }

    std.debug.print("Descriptor set layout created\n", .{});
    return true;
}

// Create uniform buffers - one per frame in flight
fn createUniformBuffers(vk: *VulkanState) bool {
    const allocator = std.heap.c_allocator;
    const buffer_size: c.VkDeviceSize = @sizeOf(UniformBufferObject);

    vk.uniform_buffers = (allocator.alloc(c.VkBuffer, max_frames_in_flight) catch return false).ptr;
    vk.uniform_buffers_memory = (allocator.alloc(c.VkDeviceMemory, max_frames_in_flight) catch return false).ptr;
    vk.uniform_buffers_mapped = (allocator.alloc(?*anyopaque, max_frames_in_flight) catch return false).ptr;

    for (0..max_frames_in_flight) |i| {
        var buffer_info = std.mem.zeroes(c.VkBufferCreateInfo);
        buffer_info.sType = c.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
        buffer_info.size = buffer_size;
        buffer_info.usage = c.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
        buffer_info.sharingMode = c.VK_SHARING_MODE_EXCLUSIVE;

        if (c.vkCreateBuffer(vk.device, &buffer_info, null, &vk.uniform_buffers.?[i]) != c.VK_SUCCESS) {
            std.debug.print("Failed to create uniform buffer\n", .{});
            return false;
        }

        var mem_requirements: c.VkMemoryRequirements = undefined;
        c.vkGetBufferMemoryRequirements(vk.device, vk.uniform_buffers.?[i], &mem_requirements);

        var alloc_info = std.mem.zeroes(c.VkMemoryAllocateInfo);
        alloc_info.sType = c.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
        alloc_info.allocationSize = mem_requirements.size;
        alloc_info.memoryTypeIndex = findMemoryType(
            vk,
            mem_requirements.memoryTypeBits,
            c.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | c.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
        ) orelse return false;

        if (c.vkAllocateMemory(vk.device, &alloc_info, null, &vk.uniform_buffers_memory.?[i]) != c.VK_SUCCESS) {
            std.debug.print("Failed to allocate uniform buffer memory\n", .{});
            return false;
        }

        _ = c.vkBindBufferMemory(vk.device, vk.uniform_buffers.?[i], vk.uniform_buffers_memory.?[i], 0);

        // Keep mapped for the lifetime of the application
        _ = c.vkMapMemory(vk.device, vk.uniform_buffers_memory.?[i], 0, buffer_size, 0, &vk.uniform_buffers_mapped.?[i]);
    }

    std.debug.print("Uniform buffers created\n", .{});
    return true;
}

// Create descriptor pool
fn createDescriptorPool(vk: *VulkanState) bool {
    var pool_size = std.mem.zeroes(c.VkDescriptorPoolSize);
    pool_size.type = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    pool_size.descriptorCount = max_frames_in_flight;

    var pool_info = std.mem.zeroes(c.VkDescriptorPoolCreateInfo);
    pool_info.sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    pool_info.poolSizeCount = 1;
    pool_info.pPoolSizes = &pool_size;
    pool_info.maxSets = max_frames_in_flight;

    if (c.vkCreateDescriptorPool(vk.device, &pool_info, null, &vk.descriptor_pool) != c.VK_SUCCESS) {
        std.debug.print("Failed to create descriptor pool\n", .{});
        return false;
    }

    std.debug.print("Descriptor pool created\n", .{});
    return true;
}

// Create descriptor sets - one per frame in flight
fn createDescriptorSets(vk: *VulkanState) bool {
    const allocator = std.heap.c_allocator;

    // All sets use the same layout
    var layouts: [max_frames_in_flight]c.VkDescriptorSetLayout = undefined;
    for (0..max_frames_in_flight) |i| {
        layouts[i] = vk.descriptor_set_layout;
    }

    var alloc_info = std.mem.zeroes(c.VkDescriptorSetAllocateInfo);
    alloc_info.sType = c.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    alloc_info.descriptorPool = vk.descriptor_pool;
    alloc_info.descriptorSetCount = max_frames_in_flight;
    alloc_info.pSetLayouts = &layouts;

    vk.descriptor_sets = (allocator.alloc(c.VkDescriptorSet, max_frames_in_flight) catch return false).ptr;

    if (c.vkAllocateDescriptorSets(vk.device, &alloc_info, vk.descriptor_sets) != c.VK_SUCCESS) {
        std.debug.print("Failed to allocate descriptor sets\n", .{});
        return false;
    }

    // Update each descriptor set to point to its uniform buffer
    for (0..max_frames_in_flight) |i| {
        var buffer_info = std.mem.zeroes(c.VkDescriptorBufferInfo);
        buffer_info.buffer = vk.uniform_buffers.?[i];
        buffer_info.offset = 0;
        buffer_info.range = @sizeOf(UniformBufferObject);

        var descriptor_write = std.mem.zeroes(c.VkWriteDescriptorSet);
        descriptor_write.sType = c.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
        descriptor_write.dstSet = vk.descriptor_sets.?[i];
        descriptor_write.dstBinding = 0;
        descriptor_write.dstArrayElement = 0;
        descriptor_write.descriptorType = c.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
        descriptor_write.descriptorCount = 1;
        descriptor_write.pBufferInfo = &buffer_info;

        c.vkUpdateDescriptorSets(vk.device, 1, &descriptor_write, 0, null);
    }

    std.debug.print("Descriptor sets created\n", .{});
    return true;
}

// Update uniform buffer with current MVP matrices
fn updateUniformBuffer(vk: *VulkanState, current_frame: u32, time: f32) void {
    var ubo = UniformBufferObject{};

    // Rotate around Z axis
    ubo.model = Mat4.rotateZ(time);

    // Camera looking at origin
    ubo.view = Mat4.lookAt(
        .{ .x = 2.0, .y = 2.0, .z = 2.0 },
        .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .{ .x = 0.0, .y = 0.0, .z = 1.0 },
    );

    // Perspective projection
    const aspect = @as(f32, @floatFromInt(vk.swapchain_extent.width)) /
        @as(f32, @floatFromInt(vk.swapchain_extent.height));
    ubo.proj = Mat4.perspective(std.math.pi / 4.0, aspect, 0.1, 10.0);

    // Vulkan clip space has inverted Y
    ubo.proj.data[5] *= -1;

    // Copy to mapped memory
    const dst = vk.uniform_buffers_mapped.?[current_frame];
    @memcpy(@as([*]u8, @ptrCast(dst))[0..@sizeOf(UniformBufferObject)], std.mem.asBytes(&ubo));
}

// Create command pool
fn createCommandPool(vk: *VulkanState) bool {
    var pool_info = std.mem.zeroes(c.VkCommandPoolCreateInfo);
    pool_info.sType = c.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    pool_info.flags = c.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    pool_info.queueFamilyIndex = vk.graphics_family_index;

    if (c.vkCreateCommandPool(vk.device, &pool_info, null, &vk.command_pool) != c.VK_SUCCESS) {
        std.debug.print("Failed to create command pool\n", .{});
        return false;
    }

    std.debug.print("Command pool created\n", .{});
    return true;
}

// Create command buffers
fn createCommandBuffers(vk: *VulkanState) bool {
    const allocator = std.heap.c_allocator;
    const bufs = allocator.alloc(c.VkCommandBuffer, max_frames_in_flight) catch return false;
    vk.command_buffers = bufs.ptr;

    var alloc_info = std.mem.zeroes(c.VkCommandBufferAllocateInfo);
    alloc_info.sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    alloc_info.commandPool = vk.command_pool;
    alloc_info.level = c.VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    alloc_info.commandBufferCount = max_frames_in_flight;

    if (c.vkAllocateCommandBuffers(vk.device, &alloc_info, vk.command_buffers) != c.VK_SUCCESS) {
        std.debug.print("Failed to allocate command buffers\n", .{});
        return false;
    }

    std.debug.print("Command buffers created\n", .{});
    return true;
}

// Create synchronization objects
fn createSyncObjects(vk: *VulkanState) bool {
    const allocator = std.heap.c_allocator;
    vk.image_available_semaphores = (allocator.alloc(c.VkSemaphore, max_frames_in_flight) catch return false).ptr;
    vk.render_finished_semaphores = (allocator.alloc(c.VkSemaphore, max_frames_in_flight) catch return false).ptr;
    vk.in_flight_fences = (allocator.alloc(c.VkFence, max_frames_in_flight) catch return false).ptr;

    var semaphore_info = std.mem.zeroes(c.VkSemaphoreCreateInfo);
    semaphore_info.sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

    var fence_info = std.mem.zeroes(c.VkFenceCreateInfo);
    fence_info.sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    fence_info.flags = c.VK_FENCE_CREATE_SIGNALED_BIT; // Start signaled

    for (0..max_frames_in_flight) |i| {
        if (c.vkCreateSemaphore(vk.device, &semaphore_info, null, &vk.image_available_semaphores.?[i]) != c.VK_SUCCESS or
            c.vkCreateSemaphore(vk.device, &semaphore_info, null, &vk.render_finished_semaphores.?[i]) != c.VK_SUCCESS or
            c.vkCreateFence(vk.device, &fence_info, null, &vk.in_flight_fences.?[i]) != c.VK_SUCCESS)
        {
            std.debug.print("Failed to create sync objects for frame {d}\n", .{i});
            return false;
        }
    }

    std.debug.print("Sync objects created\n", .{});
    return true;
}

// Record command buffer for a frame
fn recordCommandBuffer(vk: *VulkanState, command_buffer: c.VkCommandBuffer, image_index: u32, current_frame: u32) void {
    var begin_info = std.mem.zeroes(c.VkCommandBufferBeginInfo);
    begin_info.sType = c.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    _ = c.vkBeginCommandBuffer(command_buffer, &begin_info);

    var render_pass_info = std.mem.zeroes(c.VkRenderPassBeginInfo);
    render_pass_info.sType = c.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    render_pass_info.renderPass = vk.render_pass;
    render_pass_info.framebuffer = vk.framebuffers.?[image_index];
    render_pass_info.renderArea.offset = c.VkOffset2D{ .x = 0, .y = 0 };
    render_pass_info.renderArea.extent = vk.swapchain_extent;

    // Dark blue clear color
    const clear_color = c.VkClearValue{
        .color = c.VkClearColorValue{ .float32 = [4]f32{ 0.0, 0.2, 0.4, 1.0 } },
    };
    render_pass_info.clearValueCount = 1;
    render_pass_info.pClearValues = &clear_color;

    c.vkCmdBeginRenderPass(command_buffer, &render_pass_info, c.VK_SUBPASS_CONTENTS_INLINE);

    // Bind the graphics pipeline
    c.vkCmdBindPipeline(command_buffer, c.VK_PIPELINE_BIND_POINT_GRAPHICS, vk.graphics_pipeline);

    // Bind descriptor set for this frame's uniform buffer
    c.vkCmdBindDescriptorSets(
        command_buffer,
        c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        vk.pipeline_layout,
        0,
        1,
        &vk.descriptor_sets.?[current_frame],
        0,
        null,
    );

    // Set viewport
    var viewport = c.VkViewport{
        .x = 0.0,
        .y = 0.0,
        .width = @floatFromInt(vk.swapchain_extent.width),
        .height = @floatFromInt(vk.swapchain_extent.height),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };
    c.vkCmdSetViewport(command_buffer, 0, 1, &viewport);

    // Set scissor
    var scissor = c.VkRect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = vk.swapchain_extent,
    };
    c.vkCmdSetScissor(command_buffer, 0, 1, &scissor);

    // Bind vertex buffer
    const vertex_buffers = [_]c.VkBuffer{vk.vertex_buffer};
    const offsets = [_]c.VkDeviceSize{0};
    c.vkCmdBindVertexBuffers(command_buffer, 0, 1, &vertex_buffers, &offsets);

    // Draw the triangle!
    c.vkCmdDraw(command_buffer, 3, 1, 0, 0);

    c.vkCmdEndRenderPass(command_buffer);
    _ = c.vkEndCommandBuffer(command_buffer);
}

// Draw a frame
fn drawFrame(vk: *VulkanState, current_frame: *u32, time: f32) void {
    // Wait for previous frame
    _ = c.vkWaitForFences(vk.device, 1, &vk.in_flight_fences.?[current_frame.*], c.VK_TRUE, std.math.maxInt(u64));
    _ = c.vkResetFences(vk.device, 1, &vk.in_flight_fences.?[current_frame.*]);

    // Update uniform buffer with current MVP matrices
    updateUniformBuffer(vk, current_frame.*, time);

    // Acquire image
    var image_index: u32 = 0;
    _ = c.vkAcquireNextImageKHR(vk.device, vk.swapchain, std.math.maxInt(u64), vk.image_available_semaphores.?[current_frame.*], null, &image_index);

    // Reset and record command buffer
    _ = c.vkResetCommandBuffer(vk.command_buffers.?[current_frame.*], 0);
    recordCommandBuffer(vk, vk.command_buffers.?[current_frame.*], image_index, current_frame.*);

    // Submit
    var submit_info = std.mem.zeroes(c.VkSubmitInfo);
    submit_info.sType = c.VK_STRUCTURE_TYPE_SUBMIT_INFO;

    const wait_semaphores = [_]c.VkSemaphore{vk.image_available_semaphores.?[current_frame.*]};
    const wait_stages = [_]c.VkPipelineStageFlags{c.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};
    submit_info.waitSemaphoreCount = 1;
    submit_info.pWaitSemaphores = &wait_semaphores;
    submit_info.pWaitDstStageMask = &wait_stages;
    submit_info.commandBufferCount = 1;
    submit_info.pCommandBuffers = &vk.command_buffers.?[current_frame.*];

    const signal_semaphores = [_]c.VkSemaphore{vk.render_finished_semaphores.?[current_frame.*]};
    submit_info.signalSemaphoreCount = 1;
    submit_info.pSignalSemaphores = &signal_semaphores;

    _ = c.vkQueueSubmit(vk.graphics_queue, 1, &submit_info, vk.in_flight_fences.?[current_frame.*]);

    // Present
    var present_info = std.mem.zeroes(c.VkPresentInfoKHR);
    present_info.sType = c.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    present_info.waitSemaphoreCount = 1;
    present_info.pWaitSemaphores = &signal_semaphores;

    const swapchains = [_]c.VkSwapchainKHR{vk.swapchain};
    present_info.swapchainCount = 1;
    present_info.pSwapchains = &swapchains;
    present_info.pImageIndices = &image_index;

    _ = c.vkQueuePresentKHR(vk.present_queue, &present_info);

    current_frame.* = (current_frame.* + 1) % max_frames_in_flight;
}

// Create logical device and get queue handles
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

// Cleanup
fn cleanupVulkan(vk: *VulkanState) void {
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
        std.heap.c_allocator.free(fbs[0..vk.swapchain_image_count]);
    }
    if (vk.render_pass != null) {
        c.vkDestroyRenderPass(vk.device, vk.render_pass, null);
    }
    if (vk.swapchain_image_views) |views| {
        for (0..vk.swapchain_image_count) |i| {
            c.vkDestroyImageView(vk.device, views[i], null);
        }
        std.heap.c_allocator.free(views[0..vk.swapchain_image_count]);
    }
    if (vk.swapchain_images) |images| {
        std.heap.c_allocator.free(images[0..vk.swapchain_image_count]);
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

// --- Main Program ---

pub fn main() !void {
    // Initialize GLFW
    _ = c.glfwSetErrorCallback(errorCallback);
    if (c.glfwInit() == c.GLFW_FALSE) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return error.GlfwInitFailed;
    }
    defer c.glfwTerminate();

    // Tell GLFW not to create an OpenGL context
    c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);
    c.glfwWindowHint(c.GLFW_RESIZABLE, c.GLFW_FALSE);

    // Create window
    const window = c.glfwCreateWindow(window_width, window_height, window_title, null, null);
    if (window == null) {
        std.debug.print("Failed to create GLFW window\n", .{});
        return error.WindowCreationFailed;
    }
    defer c.glfwDestroyWindow(window);

    _ = c.glfwSetKeyCallback(window, keyCallback);

    // Initialize Vulkan
    var vk = VulkanState{};
    defer cleanupVulkan(&vk);

    std.debug.print("Initializing Vulkan...\n", .{});
    if (!createVulkanInstance(&vk)) {
        return error.VulkanInstanceFailed;
    }

    // Create window surface
    if (c.glfwCreateWindowSurface(vk.instance, window, null, &vk.surface) != c.VK_SUCCESS) {
        std.debug.print("Failed to create window surface\n", .{});
        return error.SurfaceCreationFailed;
    }

    // Pick GPU
    if (!pickPhysicalDevice(&vk)) {
        return error.NoGpuFound;
    }

    // Create logical device
    if (!createLogicalDevice(&vk)) {
        return error.DeviceCreationFailed;
    }

    // Create swap chain
    if (!createSwapChain(&vk, window)) {
        return error.SwapChainFailed;
    }

    // Create image views
    if (!createImageViews(&vk)) {
        return error.ImageViewsFailed;
    }

    // Create render pass
    if (!createRenderPass(&vk)) {
        return error.RenderPassFailed;
    }

    // Create framebuffers
    if (!createFramebuffers(&vk)) {
        return error.FramebuffersFailed;
    }

    // Create descriptor set layout (needed before pipeline)
    if (!createDescriptorSetLayout(&vk)) {
        return error.DescriptorSetLayoutFailed;
    }

    // Create graphics pipeline
    if (!createGraphicsPipeline(&vk)) {
        return error.GraphicsPipelineFailed;
    }

    // Create vertex buffer
    if (!createVertexBuffer(&vk)) {
        return error.VertexBufferFailed;
    }

    // Create uniform buffers
    if (!createUniformBuffers(&vk)) {
        return error.UniformBuffersFailed;
    }

    // Create descriptor pool
    if (!createDescriptorPool(&vk)) {
        return error.DescriptorPoolFailed;
    }

    // Create descriptor sets
    if (!createDescriptorSets(&vk)) {
        return error.DescriptorSetsFailed;
    }

    // Create command pool
    if (!createCommandPool(&vk)) {
        return error.CommandPoolFailed;
    }

    // Create command buffers
    if (!createCommandBuffers(&vk)) {
        return error.CommandBuffersFailed;
    }

    // Create sync objects
    if (!createSyncObjects(&vk)) {
        return error.SyncObjectsFailed;
    }

    std.debug.print("Vulkan initialized successfully\n", .{});
    std.debug.print("Press ESC to quit\n", .{});

    // Main render loop
    var current_frame: u32 = 0;
    const start_time = std.time.milliTimestamp();
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glfwPollEvents();
        const elapsed = std.time.milliTimestamp() - start_time;
        const time: f32 = @as(f32, @floatFromInt(elapsed)) / 1000.0;
        drawFrame(&vk, &current_frame, time);
    }

    // Wait for device to finish before cleanup
    _ = c.vkDeviceWaitIdle(vk.device);
}
