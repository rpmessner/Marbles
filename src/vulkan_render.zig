// Vulkan rendering functions
// Pipeline, buffers, descriptors, draw

const std = @import("std");
const types = @import("types.zig");
const math = @import("math.zig");

const c = types.c;
const VulkanState = types.VulkanState;
const UniformBufferObject = types.UniformBufferObject;
const Vertex = types.Vertex;
const vertices = types.vertices;
const Mat4 = math.Mat4;
const max_frames_in_flight = types.max_frames_in_flight;

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

// Create graphics pipeline
pub fn createGraphicsPipeline(vk: *VulkanState) bool {
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

    // Dynamic state
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
pub fn createVertexBuffer(vk: *VulkanState) bool {
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
pub fn createDescriptorSetLayout(vk: *VulkanState) bool {
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
pub fn createUniformBuffers(vk: *VulkanState) bool {
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
pub fn createDescriptorPool(vk: *VulkanState) bool {
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
pub fn createDescriptorSets(vk: *VulkanState) bool {
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
pub fn updateUniformBuffer(vk: *VulkanState, current_frame: u32, time: f32) void {
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
pub fn createCommandPool(vk: *VulkanState) bool {
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
pub fn createCommandBuffers(vk: *VulkanState) bool {
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
pub fn createSyncObjects(vk: *VulkanState) bool {
    const allocator = std.heap.c_allocator;
    vk.image_available_semaphores = (allocator.alloc(c.VkSemaphore, max_frames_in_flight) catch return false).ptr;
    vk.render_finished_semaphores = (allocator.alloc(c.VkSemaphore, max_frames_in_flight) catch return false).ptr;
    vk.in_flight_fences = (allocator.alloc(c.VkFence, max_frames_in_flight) catch return false).ptr;

    var semaphore_info = std.mem.zeroes(c.VkSemaphoreCreateInfo);
    semaphore_info.sType = c.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

    var fence_info = std.mem.zeroes(c.VkFenceCreateInfo);
    fence_info.sType = c.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    fence_info.flags = c.VK_FENCE_CREATE_SIGNALED_BIT;

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
pub fn recordCommandBuffer(vk: *VulkanState, command_buffer: c.VkCommandBuffer, image_index: u32, current_frame: u32) void {
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
pub fn drawFrame(vk: *VulkanState, current_frame: *u32, time: f32) void {
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
