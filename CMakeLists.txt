cmake_minimum_required(VERSION 3.20)
project(Marbles VERSION 1.0 LANGUAGES C CXX)

# Use C++17 but write C-style code
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)

# Export compile commands for better IDE support
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Find required packages
find_package(Vulkan REQUIRED)

# GLFW for cross-platform windowing (supports Vulkan)
find_package(glfw3 REQUIRED)

# ODE physics engine
# Use find_package for vcpkg (Windows), pkg-config for native Linux/macOS
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # For Windows cross-compilation via vcpkg
    find_package(ode CONFIG REQUIRED)
    set(ODE_LIBRARIES ODE::ODE)
else()
    # For Linux/macOS via pkg-config
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(ODE REQUIRED ode)
endif()

# Source files
set(SOURCES
    src/main.cpp
)

# Create executable
add_executable(marbles ${SOURCES})

# Include directories (only needed for non-target libs)
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    target_include_directories(marbles PRIVATE
        ${Vulkan_INCLUDE_DIRS}
        ${ODE_INCLUDE_DIRS}
    )
endif()

# Link libraries
target_link_libraries(marbles
    Vulkan::Vulkan
    glfw
    ${ODE_LIBRARIES}
)

# Compiler warnings (catch issues early)
if(MSVC)
    target_compile_options(marbles PRIVATE /W4)
else()
    target_compile_options(marbles PRIVATE -Wall -Wextra -Wpedantic)
endif()
