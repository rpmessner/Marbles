# Marbles Development Roadmap

## Phase 1: Foundation ✅ (Current)
- [x] Archive old over-engineered codebase
- [x] Set up modern build system (CMake + Makefile)
- [x] Create C-style C++ project structure
- [x] Initialize Vulkan with GLFW
- [x] Basic window and GPU selection

## Phase 2: Core Rendering (Next Up)
- [ ] Create logical device and queues
- [ ] Set up swap chain
- [ ] Implement command buffers and render loop
- [ ] Clear screen to color (first visible output!)
- [ ] Basic camera system (position, view matrix)

## Phase 3: Simple Graphics
- [ ] Write first vertex shader (GLSL)
- [ ] Write first fragment shader (GLSL)
- [ ] Draw a single sphere (the first marble!)
- [ ] Add basic lighting (Phong/Blinn-Phong)
- [ ] Draw a ground plane

## Phase 4: Physics Integration
- [ ] Integrate ODE physics engine
- [ ] Create physics world and bodies
- [ ] Sphere-sphere collision detection
- [ ] Sphere-plane collision (floor)
- [ ] Update rendering from physics simulation

## Phase 5: Basic Gameplay
- [ ] Spawn multiple marbles
- [ ] Player-controlled "shooter" marble
- [ ] Apply forces (shooting mechanics)
- [ ] Simple game rules (knock marbles out of ring)

## Phase 6: Advanced Graphics (The Fun Part!)
- [ ] Implement PBR (Physically-Based Rendering)
- [ ] Create glass material shader
- [ ] Add environment mapping (reflections)
- [ ] Implement refraction through glass
- [ ] Add Fresnel effect
- [ ] HDR rendering pipeline

## Phase 7: Ray Tracing (RTX Magic)
- [ ] Enable Vulkan ray tracing extensions
- [ ] Create acceleration structures
- [ ] Implement ray traced reflections
- [ ] Implement ray traced refractions
- [ ] Add caustics (light through glass)
- [ ] Path tracing for global illumination

## Phase 8: Marble Artistry
- [ ] Implement procedural marble patterns
- [ ] Cat's eye marbles
- [ ] Swirl marbles
- [ ] Galaxy/planetary marbles
- [ ] Solid color marbles (clearies)
- [ ] Texture-based marble designs

## Phase 9: Polish & Juice
- [ ] Sound effects (marble collisions)
- [ ] Camera controls (orbit, zoom)
- [ ] Particle effects
- [ ] UI/HUD
- [ ] Configurable marble types
- [ ] Different play surfaces

## Future Dreams
- [ ] Multiplayer
- [ ] VR support
- [ ] Marble collection/progression
- [ ] Tournament mode
- [ ] Replay system
- [ ] Marble editor

---

## Philosophy Reminders

As we build this:
- **No classes unless necessary** - structs and functions first
- **No premature abstraction** - wait until we have 3+ examples
- **Write shaders from scratch** - understand every line
- **Simple, direct code** - if it's confusing, simplify it
- **Data-oriented** - think about memory layout and cache
- **Solve today's problems** - don't future-proof unnecessarily

## Learning Goals

This project is a chance to deeply understand:
- Modern Vulkan API and graphics pipelines
- GLSL shader programming
- Physically-based rendering (PBR)
- Ray tracing and path tracing
- Real-time physics simulation
- C-style programming in modern C++
- The beauty of simple, direct code
