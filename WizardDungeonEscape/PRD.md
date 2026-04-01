# Wizard Dungeon Escape — Product Requirements Document

## 1. Overview

**Title:** Wizard Dungeon Escape  
**Engine:** Godot 4.x (GDScript)  
**Genre:** Top-down 2D dungeon puzzle/action  
**Platform:** PC (Windows)  

A single-player top-down 2D game where the player controls a wizard trapped in a dungeon. The wizard must navigate through rooms filled with enemies and walls, using a limited set of magical spells to survive and reach the exit door.

---

## 2. Core Concept

- **Perspective:** Top-down (bird's-eye view).
- **Setting:** A dark dungeon with thin walls forming corridors and rooms.
- **Player Character:** A wizard with limited life points and a small repertoire of powerful spells.
- **Objective:** Reach the exit door of each level to win.

---

## 3. Player Character — The Wizard

| Attribute        | Value                  |
|------------------|------------------------|
| Starting HP      | 2 life points          |
| Movement         | 8-directional via WASD / Arrow keys |
| Speed            | 150 px/s (tunable)     |
| Collision        | Standard — blocked by walls (unless using Phase spell) |

### 3.1 Spells

The wizard has **3 spells**, each usable up to **5 times** per level.

| # | Name            | Key  | Description |
|---|-----------------|------|-------------|
| 1 | **Line Blast**  | `1` / LMB | Fires an instant beam in the direction the wizard is facing. Every enemy on the line is killed instantly. The beam stops when it hits a wall. |
| 2 | **Smite**       | `2` / RMB | Instantly kills the single enemy closest to the wizard (anywhere on screen). |
| 3 | **Phase Walk**  | `3` / Space | For 5 seconds the wizard can move through walls. A visual timer is displayed. If the wizard is still inside a wall when the timer expires, they **lose 1 life point**. If HP reaches 0, the wizard dies and the level restarts. |

### 3.2 Facing Direction

The wizard faces the direction of the last movement input. Line Blast fires in this direction. A small visual indicator (arrow / glow) shows the current facing direction.

---

## 4. Enemies — Goblins

| Attribute     | Value |
|---------------|-------|
| HP            | 1 (killed instantly by any damaging spell) |
| Behaviour     | Random wandering — picks a random direction, walks for 1-3 seconds, pauses briefly, then picks a new direction. Bounces off walls. |
| Damage        | Touching the wizard costs the wizard **1 life point** (with a short invincibility window of ~1 s to prevent instant multi-hits). |
| Count (Lv 1)  | 2 goblins |

Enemies do **not** chase the player — they move randomly.

---

## 5. Environment

### 5.1 Walls
- Thin rectangular segments (TileMap or Line2D-based).
- Block movement for both the wizard and enemies.
- Block the Line Blast spell.
- The wizard can pass through walls during Phase Walk.

### 5.2 Door (Exit)
- Placed at a specific location in the level.
- Visually distinct (e.g., wooden door sprite / colored rectangle).
- When the wizard touches the door → **Level Complete**.

### 5.3 Level 1 Layout (Initial Level)

```
 ┌────────────────────────────────┐
 │                                │
 │   W          ║                 │
 │              ║     E1          │
 │              ║                 │
 │    ═══════   ║                 │
 │              ║                 │
 │                    ════════    │
 │         E2                    │
 │                          [D]  │
 │                                │
 └────────────────────────────────┘

 W  = Wizard start position
 E1 = Enemy (goblin) 1
 E2 = Enemy (goblin) 2
 [D]= Exit door
 ║ ═ = Walls (thin segments)
```

The layout has a few internal walls that force the player to navigate around or use Phase Walk, while enemies roam unpredictably.

---

## 6. Game Flow

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  Title    │────▶│   Level 1    │────▶│  Win Screen   │
│  Screen   │     │  (gameplay)  │     │  "You Win!"   │
└──────────┘     └──────┬───────┘     └──────────────┘
                        │ HP = 0
                        ▼
                 ┌──────────────┐
                 │ Game Over    │
                 │ "Try Again"  │
                 └──────────────┘
```

1. **Title Screen** — "Wizard Dungeon Escape" + "Press ENTER to Start".
2. **Gameplay** — The wizard navigates the dungeon, uses spells, avoids enemies, reaches the door.
3. **Win Screen** — Displayed when the wizard reaches the door. Option to replay.
4. **Game Over** — Displayed when HP reaches 0. Option to restart the level.

---

## 7. HUD (Heads-Up Display)

Displayed as an overlay during gameplay:

| Element             | Position      | Details |
|---------------------|---------------|---------|
| Life Points (HP)    | Top-left      | Heart icons × current HP |
| Spell 1 charges     | Bottom-left   | Icon + "×N" remaining |
| Spell 2 charges     | Bottom-center | Icon + "×N" remaining |
| Spell 3 charges     | Bottom-right  | Icon + "×N" remaining + active timer bar when in use |
| Facing indicator    | On wizard     | Small arrow showing current facing direction |

---

## 8. Controls

| Action         | Primary Key | Alternate |
|----------------|------------|-----------|
| Move Up        | W          | ↑         |
| Move Down      | S          | ↓         |
| Move Left      | A          | ←         |
| Move Right     | D          | →         |
| Cast Spell 1   | 1          | Left Mouse Button |
| Cast Spell 2   | 2          | Right Mouse Button |
| Cast Spell 3   | 3          | Spacebar  |
| Pause          | Escape     | —         |

---

## 9. Visual Style

- **Simple and readable** — colored shapes / simple sprites.
- **Wizard:** Blue robed figure (circle + hat triangle, or simple sprite).
- **Goblins:** Green figures (circle with pointy ears, or simple sprite).
- **Walls:** Dark gray thin rectangles.
- **Floor:** Darker background tile.
- **Door:** Brown rectangle with a handle.
- **Spells:**
  - Line Blast → bright yellow line that flashes briefly.
  - Smite → lightning bolt effect on the targeted enemy.
  - Phase Walk → wizard becomes semi-transparent; a circular timer overlay appears.

---

## 10. Audio (Future / Optional)

- Background dungeon ambience.
- Spell cast sound effects (zap, thunder, shimmer).
- Enemy death sound.
- Door open / level complete jingle.
- Game over sound.

*Audio is out-of-scope for the initial implementation.*

---

## 11. Technical Architecture

```
res://
├── project.godot
├── scenes/
│   ├── Main.tscn              # Entry scene — title screen + game manager
│   ├── Level1.tscn            # First dungeon level
│   ├── Wizard.tscn            # Player character scene
│   ├── Goblin.tscn            # Enemy scene (instanced per enemy)
│   ├── Door.tscn              # Exit door
│   ├── LineBlast.tscn         # Spell 1 visual effect
│   ├── SmiteEffect.tscn       # Spell 2 visual effect
│   └── HUD.tscn               # HUD overlay
├── scripts/
│   ├── Main.gd
│   ├── Wizard.gd
│   ├── Goblin.gd
│   ├── Door.gd
│   ├── LineBlast.gd
│   ├── SmiteEffect.gd
│   ├── HUD.gd
│   └── GameState.gd           # Singleton / autoload for game state
└── assets/                     # Sprites, fonts (placeholder shapes initially)
```

### 11.1 Key Godot Nodes

| Entity    | Node Type             | Reason |
|-----------|-----------------------|--------|
| Wizard    | CharacterBody2D       | Physics-based movement with wall collision |
| Goblin    | CharacterBody2D       | Physics-based movement with wall collision |
| Walls     | StaticBody2D + CollisionShape2D | Impassable barriers |
| Door      | Area2D                | Detects overlap with wizard |
| Line Blast| RayCast2D + Line2D    | Instant beam detection + visual |
| Smite     | Visual-only (particles/sprite) | Target is computed in code |
| HUD       | CanvasLayer + Control  | Always-on-top overlay |

### 11.2 Collision Layers

| Layer | Name    | Used By |
|-------|---------|---------|
| 1     | Walls   | Wall StaticBody2D |
| 2     | Player  | Wizard CharacterBody2D |
| 3     | Enemies | Goblin CharacterBody2D |
| 4     | Door    | Door Area2D |

- Wizard collides with: Walls (1), Enemies (3), Door (4).
- Enemies collide with: Walls (1), Player (2).
- Line Blast raycasts against: Walls (1), Enemies (3).
- During Phase Walk: Wizard's wall collision (layer 1 mask) is temporarily disabled.

---

## 12. Scope — Version 1.0 (MVP)

### In Scope
- [x] Single level (Level 1) with predefined layout.
- [x] Wizard movement (8-directional).
- [x] 3 spells with charge limits (5 each).
- [x] 2 enemy goblins with random movement.
- [x] Win condition (reach door).
- [x] Lose condition (HP reaches 0).
- [x] HUD showing HP and spell charges.
- [x] Title screen and win/game-over screens.
- [x] Simple shape-based visuals (no external assets required).

### Out of Scope (Future)
- Multiple levels / procedural generation.
- Additional enemy types (chasers, ranged).
- More spells.
- Pickups (health potions, spell recharges).
- Audio / music.
- Leaderboards / scoring.
- Save system.

---

## 13. Success Criteria

1. The game launches and displays the title screen.
2. The player can move the wizard in all 8 directions.
3. All 3 spells function correctly with charge limits.
4. Enemies wander randomly and damage the wizard on contact.
5. The wizard can reach the door to win the level.
6. Game over triggers when HP = 0 and allows restart.
7. HUD accurately reflects HP and spell charges.

---

*Document version: 1.0 — April 1, 2026*
