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

// --- Vulkan State ---
// No classes, no wrappers - just plain data
const VulkanState = struct {
    instance: c.VkInstance = null,
    surface: c.VkSurfaceKHR = null,
    physical_device: c.VkPhysicalDevice = null,
    device: c.VkDevice = null,
    graphics_queue: c.VkQueue = null,
    present_queue: c.VkQueue = null,
    swapchain: c.VkSwapchainKHR = null,
    swapchain_format: c.VkFormat = c.VK_FORMAT_UNDEFINED,
    swapchain_extent: c.VkExtent2D = .{ .width = 0, .height = 0 },
    swapchain_images: ?[*]c.VkImage = null,
    swapchain_image_count: u32 = 0,
    swapchain_image_views: ?[*]c.VkImageView = null,
};

// --- Helper Functions ---

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.debug.print("GLFW Error {d}: {s}\n", .{ err, description });
}

fn keyCallback(window: ?*c.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.C) void {
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

// Cleanup
fn cleanupVulkan(vk: *VulkanState) void {
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

    std.debug.print("Vulkan initialized successfully\n", .{});
    std.debug.print("Press ESC to quit\n", .{});
    std.debug.print("\nNOTE: This is a minimal Vulkan setup.\n", .{});
    std.debug.print("Next steps: Create logical device, swap chain, and render pipeline.\n", .{});

    // Main loop
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glfwPollEvents();
    }
}
