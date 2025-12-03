# Bidama Hajiki Development Roadmap

## Gameplay Inspiration

**Target Mechanic:** Zeni Hajiki (coin-flicking game from Ghost of Yotei)

See [docs/GAMEPLAY_VISION.md](./docs/GAMEPLAY_VISION.md) for complete gameplay design.

**Core Loop:**
- Aim your marble at targets
- Charge power and release to shoot
- Score by hitting exactly ONE target marble
- First to 6 points wins
- Pure physics-based skill gameplay

**Why it's perfect:**
- Simple rules, emergent complexity through physics
- Skill-based, not RNG
- Quick, tense matches
- Beautiful glass marbles as the centerpiece

---

## Phase 1: Foundation ✅ Complete

- [x] Archive old over-engineered codebase
- [x] Set up build system (CMake + Makefile) → **Replaced with Zig**
- [x] Create C-style project structure → **Now Zig**
- [x] Initialize Vulkan with GLFW
- [x] Basic window and GPU selection
- [x] **Session 004: Migrate from C++ to Zig**

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

- [ ] Evaluate physics options (zphysics, hand-rolled, JoltC)
- [ ] Create physics world and bodies
- [ ] Sphere-sphere collision detection
- [ ] Sphere-plane collision (floor)
- [ ] Update rendering from physics simulation

## Phase 5: Zeni Hajiki Gameplay

- [ ] Circular arena with boundaries
- [ ] Place target marbles (initial setup)
- [ ] Player shooting mechanics (aim, charge power, release)
- [ ] Collision detection and scoring
  - Hit exactly 1 marble → Player scores
  - Hit 0 or 2+ marbles → Turn ends
  - Knock marble off arena → Opponent scores
- [ ] Simple AI opponent (random aim with slight targeting)
- [ ] Turn-based game loop
- [ ] Win condition (first to 6 points)
- [ ] Victory/defeat screens

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
- **Zig's philosophy aligns with ours** - simple, explicit, no hidden control flow
- **Structs and functions** - no class hierarchies
- **No premature abstraction** - wait until we have 3+ examples
- **Write shaders from scratch** - understand every line
- **Simple, direct code** - if it's confusing, simplify it
- **Data-oriented** - think about memory layout and cache
- **Solve today's problems** - don't future-proof unnecessarily

## Learning Goals

This project is a chance to deeply understand:
- **Zig programming language** - modern systems programming
- Modern Vulkan API and graphics pipelines
- GLSL shader programming
- Physically-based rendering (PBR)
- Ray tracing and path tracing
- Real-time physics simulation
- The beauty of simple, direct code
