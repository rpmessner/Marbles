# Session 003: Rebranding and Gameplay Priorities

**Date:** 2025-11-22
**Focus:** Project rebranding, gameplay philosophy, and Phase 2 preparation
**Duration:** Planning session (no code changes)

---

## Session Goals

1. ✅ Rebrand project from "Marbles" to **Bidama Hajiki (ビー玉弾き)**
2. ✅ Clarify gameplay priorities: "find the fun" before polish
3. ✅ Clean up legacy ODE references
4. ✅ Establish input method priority (PS2 controller first)
5. ✅ Prepare Phase 2 implementation guide

---

## Major Decisions

### 1. Project Rebranding: Bidama Hajiki

**Decision:** Rename from "Marbles" to **Bidama Hajiki (ビー玉弾き)**

**Rationale:**
- More authentic to the Japanese marble flicking tradition
- Honors the Ghost of Yotei zeni hajiki inspiration
- "Marbles" now only refers to the museum/legacy code
- Bidama (ビー玉) = glass marble, Hajiki (弾き) = flicking

**Changes made:**
- ✅ README.md - New title and description
- ✅ ROADMAP.md - Updated header
- ✅ docs/NEXT_SESSION.md - File structure references
- ✅ src/main.cpp - Comments, window title, app name
- ✅ CMakeLists.txt - Project name, executable name
- ✅ Makefile - Comments, target name
- ✅ build-linux.sh - Echo messages, output references
- ✅ build-windows.sh - Echo messages, output references
- ✅ setup.sh - Comments, messages

**New executable names:**
- Linux: `bidama_hajiki`
- Windows: `bidama_hajiki.exe`

---

### 2. Gameplay Philosophy: Find the Fun First

**Core Principle:** Playable gameplay > Visual polish

**Priorities established:**

#### A. Lighting is Essential, Not Polish
**Why:** Can't judge distance, angles, or power without spatial clarity
- Need Phong lighting to perceive 3D form
- Grid on ground plane for distance judgment
- Camera angle (~30-45°) to see the arena
- Simple shadows for depth perception

**What we skip initially:**
- PBR materials (Phase 6)
- RTX ray tracing (Phase 7)
- Fancy marble patterns (Phase 8)
- Particles/juice (Phase 9)

#### B. Surface Physics = Skill Expression
**Critical insight:** Friction and drag ARE the gameplay

Without proper surface resistance:
- ❌ Every shot is either "too hard" or "too soft"
- ❌ No skill gradient
- ❌ Can't "feel" the difference between 70% and 80% power

With tuned friction:
- ✅ Light tap = marble barely reaches target
- ✅ Medium power = controlled shot
- ✅ Full power = risky (might hit multiple marbles)
- ✅ Players can master the "feel"

**Action item:** Phase 4c will focus heavily on tuning surface material properties

#### C. Controller-First Design
**Decision:** PS2 controller is the primary input method

**Rationale:**
- Analog stick = analog power control (perfect match)
- R2 trigger pressure = charge power (analog input!)
- Tactile, physical feedback
- Better for a "flicking" game than mouse/keyboard

**Planned mapping:**
- **Left stick:** Aim direction (analog precision)
- **Right stick:** Camera rotation around arena
- **R2 trigger:** Hold to charge, release to shoot
- **Face buttons:** Secondary controls, menus
- **Rumble:** Feel collision impacts (if adapter supports it)

**Library:** GLFW already supports gamepad input (no new deps needed)

---

### 3. Library Philosophy: Add When Needed

**Decision:** Remove all ODE references, add physics library only in Phase 4

**Philosophy:**
> "Going forward we only introduce the libraries we need when we need them and choose the most appropriate one at that time"

**ODE references cleaned from:**
- ✅ setup.sh (removed from manual install message)
- ✅ docs/GAMEPLAY_VISION.md (generic physics description)
- Other references remain in session docs (historical record)
- Museum folder untouched (time capsule)

**Note:** When we reach Phase 4, we'll evaluate options (likely Jolt Physics based on docs/LIBRARY_DECISIONS.md analysis, but decide then)

---

## Revised Development Path

### Phase 2: Core Rendering
**Next up - Start in new session**
- Logical device + queues
- Swap chain
- Command buffers + render loop
- Clear screen to color (proof of life!)

### Phase 3: Graphics for Spatial Clarity
**Goal: See what you're doing**
- Draw spheres (marbles)
- **Phong lighting** (essential for depth perception)
- Ground plane with grid
- Camera system (30-45° angle, orbit controls)
- Optional: Simple shadows

### Phase 4: Physics Integration
**Goal: Find the fun feel**
- Choose physics library (evaluate when we get here)
- Marble-marble collisions
- **Surface friction/drag tuning** (CRITICAL)
- Rolling resistance
- Marble restitution (bounciness)

### Phase 5: Core Gameplay
**Goal: Playable game loop**
- **PS2 controller input** (primary)
- Aim mechanic
- Power charge + shoot
- Score detection (hit exactly 1 marble)
- Basic AI opponent

### Phase 6+: Polish
- PBR materials
- RTX ray tracing
- Marble patterns
- Juice and effects

---

## Technical Notes for Phase 2

### What We Have Now
- ✅ VkInstance created
- ✅ VkSurfaceKHR created
- ✅ VkPhysicalDevice selected (GPU)
- ⏳ VkDevice not created yet
- ⏳ VkQueue not created yet
- ⏳ VkSwapchainKHR not created yet
- ⏳ No rendering yet

### What Phase 2 Needs
See `docs/phase2-rendering-guide.md` for implementation details:
1. Find queue families (graphics + present)
2. Create logical device
3. Create swap chain
4. Create image views
5. Set up command pool
6. Allocate command buffers
7. Implement render loop
8. Clear screen to solid color

**Success criteria:**
- Window shows solid color (not black/undefined)
- No Vulkan validation errors
- Clean shutdown with ESC
- Code remains simple and understandable

---

## Files Modified This Session

### Rebranding changes:
- `README.md` - Title, description, goals
- `ROADMAP.md` - Header
- `docs/NEXT_SESSION.md` - File paths, executable names
- `src/main.cpp` - Comments, WINDOW_TITLE, app name
- `CMakeLists.txt` - Project name, executable target
- `Makefile` - Comment, TARGET variable
- `build-linux.sh` - Echo messages
- `build-windows.sh` - Echo messages
- `setup.sh` - Comments, messages, removed ODE

### New documentation:
- `docs/sessions/003-rebranding-and-priorities.md` (this file)
- `docs/phase2-rendering-guide.md` (implementation guide)

---

## Key Quotes from Session

> "I think as far as visual quality goes, we should focus on lighting so that we can see what we're doing in the actual gameplay"

> "I think moving beyond playing on a flat infinitely hard surface is going to be a priority soon; we'll need a playing surface that exhibits the sufficient amount of drag so that skill is able to be expressed"

> "I want to 'find the fun' before moving ahead with polish"

> "I have a PlayStation 2 controller that I can plug into this system... I want to gametest w/ the controller as a first class gameplay method; keyboard and mouse seem like they would simply be inferior here"

> "Going forward we only introduce the libraries we need when we need them and choose the most appropriate one at that time"

---

## Session Statistics

**Files changed:** 10 (documentation + build files)
**Code changes:** Naming/branding only (no logic changes)
**Session type:** Planning and documentation
**Commits expected:** 1-2 (rebranding + session docs)

---

## Philosophy Reinforced

### Jonathan Blow Principles Applied
1. **Simple, direct code** - No premature abstraction
2. **Solve today's problems** - Add libraries when needed, not before
3. **Playable over perfect** - Find the fun before polish

### Game Design Principles
1. **Controller-first** - Match input to gameplay (analog stick for analog power)
2. **Physics = gameplay** - Friction and drag are skill expression
3. **Clarity before beauty** - See the 3D space before making it gorgeous
4. **Iterate on feel** - Playtest early, tune physics to feel amazing

---

## Next Session: Phase 2 - Core Rendering

**Goal:** Get a window showing a solid color (proof Vulkan rendering works)

**See:** `docs/phase2-rendering-guide.md` for full implementation details

**Expected outcome:**
- Vulkan render loop working
- Swap chain presenting frames
- Command buffers recording/submitting
- Clear screen to color
- Foundation ready for Phase 3 (drawing actual geometry)

---

**Status:** Ready for Phase 2 implementation
**Mood:** 🎮 Focused on finding the fun
