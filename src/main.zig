// Bidama Hajiki (ビー玉弾き) - A marble flicking game
// Inspired by the zeni hajiki minigame from Ghost of Yotei
// Simple, direct code - data-oriented, minimal abstraction
// Modern Vulkan API for RTX ray tracing

const std = @import("std");
const types = @import("types.zig");
const vulkan_init = @import("vulkan_init.zig");
const vulkan_render = @import("vulkan_render.zig");

const c = types.c;
const VulkanState = types.VulkanState;
const window_width = types.window_width;
const window_height = types.window_height;
const window_title = types.window_title;

// --- GLFW Callbacks ---

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
    defer vulkan_init.cleanupVulkan(&vk);

    std.debug.print("Initializing Vulkan...\n", .{});
    if (!vulkan_init.createVulkanInstance(&vk)) {
        return error.VulkanInstanceFailed;
    }

    // Create window surface
    if (c.glfwCreateWindowSurface(vk.instance, window, null, &vk.surface) != c.VK_SUCCESS) {
        std.debug.print("Failed to create window surface\n", .{});
        return error.SurfaceCreationFailed;
    }

    // Pick GPU
    if (!vulkan_init.pickPhysicalDevice(&vk)) {
        return error.NoGpuFound;
    }

    // Create logical device
    if (!vulkan_init.createLogicalDevice(&vk)) {
        return error.DeviceCreationFailed;
    }

    // Create swap chain
    if (!vulkan_init.createSwapChain(&vk, window)) {
        return error.SwapChainFailed;
    }

    // Create image views
    if (!vulkan_init.createImageViews(&vk)) {
        return error.ImageViewsFailed;
    }

    // Create render pass
    if (!vulkan_init.createRenderPass(&vk)) {
        return error.RenderPassFailed;
    }

    // Create framebuffers
    if (!vulkan_init.createFramebuffers(&vk)) {
        return error.FramebuffersFailed;
    }

    // Create descriptor set layout (needed before pipeline)
    if (!vulkan_render.createDescriptorSetLayout(&vk)) {
        return error.DescriptorSetLayoutFailed;
    }

    // Create graphics pipeline
    if (!vulkan_render.createGraphicsPipeline(&vk)) {
        return error.GraphicsPipelineFailed;
    }

    // Create vertex buffer
    if (!vulkan_render.createVertexBuffer(&vk)) {
        return error.VertexBufferFailed;
    }

    // Create uniform buffers
    if (!vulkan_render.createUniformBuffers(&vk)) {
        return error.UniformBuffersFailed;
    }

    // Create descriptor pool
    if (!vulkan_render.createDescriptorPool(&vk)) {
        return error.DescriptorPoolFailed;
    }

    // Create descriptor sets
    if (!vulkan_render.createDescriptorSets(&vk)) {
        return error.DescriptorSetsFailed;
    }

    // Create command pool
    if (!vulkan_render.createCommandPool(&vk)) {
        return error.CommandPoolFailed;
    }

    // Create command buffers
    if (!vulkan_render.createCommandBuffers(&vk)) {
        return error.CommandBuffersFailed;
    }

    // Create sync objects
    if (!vulkan_render.createSyncObjects(&vk)) {
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
        vulkan_render.drawFrame(&vk, &current_frame, time);
    }

    // Wait for device to finish before cleanup
    _ = c.vkDeviceWaitIdle(vk.device);
}
