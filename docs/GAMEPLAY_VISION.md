# Gameplay Vision: Zeni Hajiki Inspired

**Inspiration:** Zeni Hajiki minigame from Ghost of Yotei

## What is Zeni Hajiki?

Zeni Hajiki is a traditional Japanese coin-flicking gambling game featured in Ghost of Yotei. It's become surprisingly popular among players for its simple yet tense physics-based gameplay.

### Core Mechanics

**Objective:** First player to 6 points wins

**Gameplay Loop:**
1. **Aim:** Select your coin/marble and line up your shot
2. **Power:** Hold to charge power, release to flick
3. **Physics:** Watch your projectile collide with targets

**Scoring Rules:**
- ✅ **Success:** Hit exactly ONE target coin → Earn a point
- ❌ **Miss:** Touch zero coins → Turn ends, no points
- ❌ **Multi-hit:** Touch multiple coins → Turn ends, no points
- ❌ **Knock-off:** Push coin(s) off the table → Opponent gains those as points

**What Makes It Compelling:**
- Simple to understand, hard to master
- Pure physics-based skill gameplay
- High tension (one mistake gives opponent points)
- Quick matches (~2-3 minutes)
- Satisfying tactile feedback

## Adaptation for Marbles

### Our Version

Instead of flat coins on a table, we use **beautiful glass marbles** with:
- RTX ray-traced glass refraction
- Physically-based rendering (PBR)
- Realistic marble-to-marble collisions with proper friction and rolling physics
- Different marble types (cat's eye, swirls, galaxies, clearies)

### Gameplay Translation

**Core mechanics stay the same:**
- Aim with camera/cursor
- Hold to charge power (visualize trajectory)
- Release to shoot your marble
- Score by hitting exactly one target marble

**Arena:**
- Circular play area (like traditional marble ring games)
- Marbles that roll out of bounds → opponent scores them
- Static obstacles? (TBD - keep it simple first)

**Visual Polish:**
- Beautiful caustics (light through glass marbles)
- Motion trails for marble paths
- Impact effects when marbles collide
- Camera follows the action

### Progression Ideas (Future)

- Different marble types with varying properties (weight, friction)
- Unlock new marble designs through wins
- Tournament mode
- Multiple arena types
- Multiplayer (local → online eventually)

## Why This Works for Our Project

### Alignment with Philosophy

**Jonathan Blow would approve:**
- **Simple core mechanic** - Aim, power, shoot
- **Emergent complexity** - Physics creates depth, not artificial rules
- **Direct gameplay** - No abstraction layers, pure physics interaction
- **Skill-based** - Player skill matters, not RNG or grinding

### Technical Alignment

**Plays to our strengths:**
- ✅ Physics engine (ODE) - Perfect for collision-based gameplay
- ✅ Beautiful rendering - Marbles are the centerpiece, make them stunning
- ✅ Small scope - One marble arena, not an open world
- ✅ Vulkan/RTX - Make those glass marbles look *incredible*

### Achievable Scope

**MVP (Minimum Viable Product):**
1. Single player vs AI (simple AI: random power/angle with slight targeting)
2. One arena (circular ring)
3. Basic marble types (3-5 visual variants)
4. Core scoring rules
5. Win/lose conditions

**Later additions:**
- Better AI
- More marble types
- Arena variety
- Multiplayer
- Progression system

## User Experience Flow

### Match Flow
```
Start Match
  ↓
Place Marbles (automatic initial placement)
  ↓
Player Turn
  ├─ Aim (camera + cursor)
  ├─ Charge Power (hold button)
  ├─ Release (shoot marble)
  └─ Watch Physics (satisfying!)
  ↓
Score Check
  ├─ Hit 1 target? → Player scores
  ├─ Hit 0 or 2+? → Turn ends
  └─ Knocked off? → Opponent scores
  ↓
AI Turn (same flow)
  ↓
Repeat until someone reaches 6 points
  ↓
Victory Screen
```

### Controls (Initial Design)

**Mouse + Keyboard:**
- Mouse movement → Aim
- Left-click hold → Charge power
- Release → Shoot
- Right-click drag → Rotate camera
- ESC → Menu

**Controller (Future):**
- Left stick → Aim
- Right stick → Camera
- L2/R2 hold → Charge power
- Release → Shoot

### Camera System

**Needs:**
- Free rotation around arena (orbit camera)
- Zoom in/out
- Follow shooter marble during shot
- Return to strategic view after physics settle

## Comparison: Ghost of Yotei vs Our Game

| Aspect | Ghost of Yotei | Our Marbles Game |
|--------|----------------|------------------|
| **Setting** | Flat table, top-down | 3D arena, orbital camera |
| **Objects** | Flat coins | Spherical glass marbles |
| **Graphics** | Stylized 2D-ish | Photorealistic RTX glass |
| **Physics** | 2D sliding physics | Full 3D ODE physics |
| **Feel** | Gambling minigame | Standalone beautiful experience |
| **Duration** | Quick gambling break | Meditative skill challenge |

## Design Principles

### Do's
- ✅ Make marbles visually stunning (this is the hook)
- ✅ Ensure physics feels *right* (realistic collisions)
- ✅ Keep rules simple and clear
- ✅ Provide visual feedback (trajectories, power indicators)
- ✅ Make impacts satisfying (sound, visuals, camera shake?)

### Don'ts
- ❌ Don't add complicated rules for "depth" - physics provides depth
- ❌ Don't add leveling/stats systems initially - keep it pure skill
- ❌ Don't make it about grinding - make each match satisfying
- ❌ Don't add distracting UI - let the marbles be the focus
- ❌ Don't over-engineer - solve today's problems

## Success Metrics

**The game is succeeding if:**
1. Players say "just one more match"
2. Physics feels satisfying and realistic
3. Marbles look absolutely gorgeous
4. Matches are tense and exciting
5. Skill clearly matters (better aim = more wins)

**The game is failing if:**
- Physics feels floaty or unpredictable
- Aiming is frustrating or unclear
- Marbles don't look special
- Matches feel random/luck-based
- Players get bored after 2-3 matches

## Development Phases

### Phase 1-3: Foundation & Graphics (Current)
- Get rendering working
- Make one marble look amazing
- Basic physics setup

### Phase 4: Physics Integration
- Multiple marbles interacting
- Collision detection/response
- Marble-to-marble physics tuning

### Phase 5: Basic Gameplay (The Big One)
- Implement zeni hajiki rules
- Player shooting mechanics
- Scoring system
- Win/lose conditions
- Simple AI opponent

### Phase 6-9: Polish & Features
- Camera system improvements
- Multiple marble types
- Visual effects (caustics, trails, impacts)
- Sound design
- UI/HUD
- Different arenas
- Better AI
- Multiplayer (?)

## Long-term Vision

**The Dream:**
This becomes **the** definitive marble game. When people think of beautiful marbles in a game, they think of this. Like how people think of Rocket League for physics-based car soccer, we want this to be *the* physics-based marble game.

**Tagline Ideas:**
- "The most beautiful marble game ever made"
- "Where physics meets art"
- "Glass, gravity, and glory"
- "Zeni Hajiki, perfected"

## References

### Zeni Hajiki Resources
- [How to Win at Zeni Hajiki - Game8](https://game8.co/games/Ghost-of-Yotei/archives/554951)
- [Ghost of Yotei Zeni Hajiki Guide - Sportskeeda](https://www.sportskeeda.com/esports/playing-zeni-hajiki-mini-game-ghost-yotei-explained)
- [All Zeni Hajiki Locations - PowerPyx](https://www.powerpyx.com/ghost-of-yotei-all-zeni-hajiki-locations/)
- [Zeni Hajiki Strategy - Gamer Guides](https://www.gamerguides.com/ghost-of-yotei/guide/getting-started/tips-and-tricks/gambling-winning-every-zeni-hajiki-match)

### Traditional Marble Games
- Ringer (classic American marbles)
- Ohajiki (Japanese coin/marble flicking)
- Marble racing

### Similar Games
- Pool/Billiards mechanics
- Bocce ball / Pétanque
- Curling

---

**This is our north star.** Simple, beautiful, skill-based marble gameplay inspired by the addictive zeni hajiki minigame, elevated by stunning RTX graphics and precise physics simulation.
