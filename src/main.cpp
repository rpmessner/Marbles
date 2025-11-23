// Bidama Hajiki (ビー玉弾き) - A marble flicking game
// Inspired by the zeni hajiki minigame from Ghost of Yotei
// Following Jonathan Blow's C-style philosophy:
// - Simple, direct code that you can understand
// - Data-oriented thinking
// - No unnecessary abstractions
// - Modern Vulkan API for RTX ray tracing

#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// --- Configuration ---
const int WINDOW_WIDTH = 1024;
const int WINDOW_HEIGHT = 768;
const char* WINDOW_TITLE = "Bidama Hajiki";
const bool ENABLE_VALIDATION = true; // Vulkan validation layers for debugging

// --- Vulkan State ---
// No classes, no wrappers - just plain data
struct VulkanState {
    VkInstance instance;
    VkSurfaceKHR surface;
    VkPhysicalDevice physical_device;
    VkDevice device;
    VkQueue graphics_queue;
    VkQueue present_queue;
    VkSwapchainKHR swapchain;
    VkFormat swapchain_format;
    VkExtent2D swapchain_extent;
    VkImage* swapchain_images;
    uint32_t swapchain_image_count;
    VkImageView* swapchain_image_views;
};

// --- Helper Functions ---

static void error_callback(int error, const char* description) {
    fprintf(stderr, "GLFW Error %d: %s\n", error, description);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    (void)scancode;
    (void)mods;
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
}

// Create Vulkan instance
static bool create_vulkan_instance(VulkanState* vk) {
    VkApplicationInfo app_info = {};
    app_info.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app_info.pApplicationName = "Bidama Hajiki";
    app_info.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    app_info.pEngineName = "No Engine";
    app_info.engineVersion = VK_MAKE_VERSION(1, 0, 0);
    app_info.apiVersion = VK_API_VERSION_1_3;

    // Get required extensions from GLFW
    uint32_t glfw_extension_count = 0;
    const char** glfw_extensions = glfwGetRequiredInstanceExtensions(&glfw_extension_count);

    VkInstanceCreateInfo create_info = {};
    create_info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    create_info.pApplicationInfo = &app_info;
    create_info.enabledExtensionCount = glfw_extension_count;
    create_info.ppEnabledExtensionNames = glfw_extensions;

    // Enable validation layers in debug mode
    const char* validation_layers[] = {"VK_LAYER_KHRONOS_validation"};
    if (ENABLE_VALIDATION) {
        create_info.enabledLayerCount = 1;
        create_info.ppEnabledLayerNames = validation_layers;
    }

    VkResult result = vkCreateInstance(&create_info, NULL, &vk->instance);
    if (result != VK_SUCCESS) {
        fprintf(stderr, "Failed to create Vulkan instance: %d\n", result);
        return false;
    }

    return true;
}

// Pick a physical device (GPU)
static bool pick_physical_device(VulkanState* vk) {
    uint32_t device_count = 0;
    vkEnumeratePhysicalDevices(vk->instance, &device_count, NULL);

    if (device_count == 0) {
        fprintf(stderr, "No GPUs with Vulkan support found\n");
        return false;
    }

    VkPhysicalDevice* devices = (VkPhysicalDevice*)malloc(sizeof(VkPhysicalDevice) * device_count);
    vkEnumeratePhysicalDevices(vk->instance, &device_count, devices);

    // Just pick the first device for now
    // TODO: Score devices and pick the best one (discrete GPU preferred)
    vk->physical_device = devices[0];

    VkPhysicalDeviceProperties properties;
    vkGetPhysicalDeviceProperties(vk->physical_device, &properties);
    printf("Using GPU: %s\n", properties.deviceName);

    free(devices);
    return true;
}

// Cleanup
static void cleanup_vulkan(VulkanState* vk) {
    if (vk->swapchain_image_views) {
        for (uint32_t i = 0; i < vk->swapchain_image_count; i++) {
            vkDestroyImageView(vk->device, vk->swapchain_image_views[i], NULL);
        }
        free(vk->swapchain_image_views);
    }
    if (vk->swapchain_images) {
        free(vk->swapchain_images);
    }
    if (vk->swapchain) {
        vkDestroySwapchainKHR(vk->device, vk->swapchain, NULL);
    }
    if (vk->device) {
        vkDestroyDevice(vk->device, NULL);
    }
    if (vk->surface) {
        vkDestroySurfaceKHR(vk->instance, vk->surface, NULL);
    }
    if (vk->instance) {
        vkDestroyInstance(vk->instance, NULL);
    }
}

// --- Main Program ---

int main(void) {
    // Initialize GLFW
    glfwSetErrorCallback(error_callback);
    if (!glfwInit()) {
        fprintf(stderr, "Failed to initialize GLFW\n");
        return EXIT_FAILURE;
    }

    // Tell GLFW not to create an OpenGL context
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);

    // Create window
    GLFWwindow* window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_TITLE, NULL, NULL);
    if (!window) {
        fprintf(stderr, "Failed to create GLFW window\n");
        glfwTerminate();
        return EXIT_FAILURE;
    }
    glfwSetKeyCallback(window, key_callback);

    // Initialize Vulkan
    VulkanState vk = {};

    printf("Initializing Vulkan...\n");
    if (!create_vulkan_instance(&vk)) {
        glfwDestroyWindow(window);
        glfwTerminate();
        return EXIT_FAILURE;
    }

    // Create window surface
    if (glfwCreateWindowSurface(vk.instance, window, NULL, &vk.surface) != VK_SUCCESS) {
        fprintf(stderr, "Failed to create window surface\n");
        cleanup_vulkan(&vk);
        glfwDestroyWindow(window);
        glfwTerminate();
        return EXIT_FAILURE;
    }

    // Pick GPU
    if (!pick_physical_device(&vk)) {
        cleanup_vulkan(&vk);
        glfwDestroyWindow(window);
        glfwTerminate();
        return EXIT_FAILURE;
    }

    printf("Vulkan initialized successfully\n");
    printf("Press ESC to quit\n");
    printf("\nNOTE: This is a minimal Vulkan setup.\n");
    printf("Next steps: Create logical device, swap chain, and render pipeline.\n");

    // Main loop (just keep window open for now)
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
    }

    // Cleanup
    cleanup_vulkan(&vk);
    glfwDestroyWindow(window);
    glfwTerminate();

    return EXIT_SUCCESS;
}
