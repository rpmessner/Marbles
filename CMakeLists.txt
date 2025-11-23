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

# Physics engine will be added in Phase 4 (Physics Integration)
# Candidate: Jolt Physics (modern, AAA-proven, perfect for marbles)
# See docs/LIBRARY_DECISIONS.md for analysis

# Source files
set(SOURCES
    src/main.cpp
)

# Create executable
add_executable(marbles ${SOURCES})

# Link libraries
target_link_libraries(marbles
    Vulkan::Vulkan
    glfw
)

# Compiler warnings (catch issues early)
if(MSVC)
    target_compile_options(marbles PRIVATE /W4)
else()
    target_compile_options(marbles PRIVATE -Wall -Wextra -Wpedantic)
endif()
