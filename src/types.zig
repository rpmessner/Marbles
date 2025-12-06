// Type definitions for Bidama Hajiki
// Config, Vulkan state, and data types

const std = @import("std");
const math = @import("math.zig");

pub const Mat4 = math.Mat4;
pub const Vec3 = math.Vec3;

// Re-export c bindings for other modules
pub const c = @cImport({
    @cDefine("GLFW_INCLUDE_VULKAN", "1");
    @cInclude("GLFW/glfw3.h");
});

// --- Configuration ---
pub const window_width: u32 = 1024;
pub const window_height: u32 = 768;
pub const window_title = "Bidama Hajiki";
pub const enable_validation = true;
pub const max_frames_in_flight: u32 = 2;

// --- Uniform Buffer Object ---
pub const UniformBufferObject = struct {
    model: Mat4 = Mat4.identity(),
    view: Mat4 = Mat4.identity(),
    proj: Mat4 = Mat4.identity(),
};

// --- Queue Family Indices ---
pub const QueueFamilyIndices = struct {
    graphics_family: u32 = 0,
    present_family: u32 = 0,
    graphics_found: bool = false,
    present_found: bool = false,

    pub fn isComplete(self: QueueFamilyIndices) bool {
        return self.graphics_found and self.present_found;
    }
};

// --- Swap Chain Support ---
pub const SwapChainSupportDetails = struct {
    capabilities: c.VkSurfaceCapabilitiesKHR = undefined,
    formats: []c.VkSurfaceFormatKHR = &.{},
    present_modes: []c.VkPresentModeKHR = &.{},

    pub fn deinit(self: *SwapChainSupportDetails) void {
        const allocator = std.heap.c_allocator;
        if (self.formats.len > 0) allocator.free(self.formats);
        if (self.present_modes.len > 0) allocator.free(self.present_modes);
    }
};

// --- Vulkan State ---
// No classes, no wrappers - just plain data
pub const VulkanState = struct {
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

// --- Vertex Data ---
pub const Vertex = struct {
    pos: [2]f32,
};

pub const vertices = [_]Vertex{
    .{ .pos = .{ 0.0, -0.5 } }, // top
    .{ .pos = .{ 0.5, 0.5 } }, // bottom right
    .{ .pos = .{ -0.5, 0.5 } }, // bottom left
};
