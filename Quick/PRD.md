# Quick — Product Requirements Document

**Version:** 1.9  
**Date:** March 21, 2026  
**Status:** In Development — Phase 4

---

## 1. Overview

**Quick** is a top-down grid-puzzle game where the player guides a small white hamster through increasingly complex levels. Once the hamster starts moving it **never stops** — the player can only change its direction. Hitting a wall means instant death. The hamster must collect colored keys to unlock matching doors and reach the exit before running out of safe path.

---

## 2. Core Concept

- **Game Name:** Quick  
- **Genre:** Top-down grid puzzle / action-puzzle  
- **Perspective:** Overhead / 2D tile-based  
- **Player Character:** A small white hamster  
- **Core Hook:** Continuous, unstoppable movement — think before you press, because once you go, you can't stop  
- **Goal:** Navigate the grid, collect keys, unlock doors, and reach the level exit — alive  

---

## 3. Game Mechanics

### 3.1 Grid & Movement

| Property | Detail |
|---|---|
| Grid type | Square tile grid |
| Movement | 4-directional (up / down / left / right), **continuous** |
| Speed | Constant — the hamster moves at a fixed rate (e.g., ~6 tiles/sec, tunable) |
| Turn structure | Real-time; the hamster is always moving once the first arrow key is pressed |

#### Movement Rules

1. **Start:** The level begins with the hamster stationary at the Start tile. The hamster does **not** move until the player presses an arrow key for the first time.
2. **Continuous motion:** After the first key press the hamster moves in the current direction at a constant speed and **never stops on its own**.
3. **Direction change:** While moving, the player can press a different arrow key at any time. The hamster immediately turns to the new direction (on the next tile boundary) and continues moving.
4. **Wall collision = death:** If the hamster's next tile is a Wall block, the hamster crashes into it and **dies**. The level is failed and must be restarted.
5. **Door without key = death:** A locked door the hamster cannot open is treated the same as a wall — collision kills the hamster.

### 3.2 Block Types

| Block | Symbol | Appearance | Behavior |
|---|---|---|---|
| **Floor** | `.` | Neutral / empty tile | Passable — the hamster can walk on it |
| **Wall** | `#` | Solid brick/stone | Impassable — blocks movement entirely |
| **Key** | `K` | Small key icon, tinted with a color | Collectible — picked up when the hamster steps on it; added to inventory |
| **Door** | `D` | Door icon, tinted with a color | Locked — blocks movement until the player has a matching-color key; consuming the key opens the door (it becomes floor) |
| **Start** | `S` | Hamster spawn point | The tile where the hamster begins the level |
| **Exit** | `E` | Goal marker (flag / hole / cheese) | Reaching this tile completes the level |
| **Teleporter** | `T` | Two concentric circles in two shades of a color (e.g., light red outer + red inner) | Always placed in same-color pairs. When Quicky enters a teleporter cell, it instantly teleports to the paired teleporter of the same color and continues moving in the same direction |

### 3.3 Keys & Doors

- Keys and doors share a **color** attribute (e.g., red, blue, green, yellow).
- Moving onto a key tile automatically picks it up (no stop, the hamster keeps moving).
- **On pickup** the key tile becomes floor and a matching key icon appears in the **Key Inventory HUD** (top-right corner of the screen).
- Keys are **always single-use**. Picking up a key adds one icon to the HUD; opening a matching door consumes exactly one key and removes its icon. There are no reusable keys.
- Moving into a door tile of a matching color **consumes one key** (the corresponding icon disappears from the HUD) and converts the door to a floor tile — the hamster passes through without stopping.
- Moving into a door tile **without** the matching key is treated as a wall — the hamster **dies** on impact.

### 3.4 Teleporters

- Teleporters share a **color** attribute with keys and doors (red, blue, green, yellow).
- Teleporters always come in **same-color pairs** — exactly two teleporters of each color per level.
- When Quicky steps onto a teleporter tile, it is **instantly teleported** to the paired teleporter of the same color.
- After teleporting, Quicky **continues moving in the same direction** it was traveling before entering the teleporter.
- Teleporters are **not consumed** — they remain on the grid and can be used multiple times.
- Teleporters are drawn as **two concentric circles** in two shades of their color (lighter outer ring, darker inner circle).
- The tile beneath a teleporter is floor — it is always passable.

### 3.5 Win / Lose Conditions

| Condition | Trigger |
|---|---|
| **Win** | Hamster reaches the Exit tile |
| **Death** | Hamster collides with a Wall block or a locked Door it cannot open |

On death the level immediately shows a brief death animation (e.g., poof / stars) and offers **Restart** or **Back to Menu**. There is no undo — continuous movement is unforgiving by design.

---

## 4. Player Character

- **Name:** Quicky
- **Appearance:** Small, round, white hamster with tiny ears, black bead eyes, and a pink nose
- **Animations:**
  - **Idle** — gentle breathing / wiggle while waiting for first input
  - **Running** — fast scurry cycle (per-direction)
  - **Key pickup** — brief sparkle overlay (no pause in movement)
  - **Death** — poof / dizzy-stars on wall collision
  - **Level complete** — celebratory hop
- **Size:** Occupies exactly one grid tile

---

## 5. Level Design

### 5.1 Level Format

Levels are defined as 2D text grids. Example:

```
# # # # # # # #
# S . . # . . #
# . # . Kr. . #
# . # . # # D #
# . . . . . .r#
# # # . # # . #
# . . . . . E #
# # # # # # # #
```

> `Kr` = red key, `Dr` = red door, `Tr` = red teleporter. `.r` after a block denotes color.

### 5.2 Level Progression

Levels are split into two separate tracks:

- **Tutorial levels** — stored in `levels/tutorial/`. Available from the main menu via a dedicated "Tutorial" button. Teach movement, turning, keys/doors, and exit mechanics with forgiving layouts.
- **Real levels** — stored in `levels/`. Numbered independently starting from 1. Unlocked sequentially; "Play" always starts at the player's current progress.

| Phase | Levels | Concepts Introduced |
|---|---|---|
| Easy | 1–5 | Single-color keys & doors; simple timing of turns; teleporters (level 5) |
| Medium | 6–12 | Multiple colors, tighter corridors, key-routing puzzles |
| Hard | 13–20+ | Complex mazes, limited keys, split-second direction changes |

### 5.3 Level Data Storage

- Levels stored as JSON files.
- Each level file includes: `name`, `index`, and `grid` (2D array of tile strings).
- Rows and columns are derived from the grid array at load time. All rows must be equal length.
- Tutorial levels live in `res://levels/tutorial/`, real levels in `res://levels/`.

---

## 6. UI & HUD

| Element | Position | Description |
|---|---|---|
| **Grid View** | Center | Main play area showing the tile map and hamster |
| **Key Inventory** | Top-right | Collected keys displayed as colored key icons; each icon represents one key; when a key is used on a door its icon disappears |
| **Timer** | Top-left | Elapsed time since first move (optional leaderboard metric) |
| **Level Title** | Top-center | Level name (prefixed with "Tutorial:" for tutorial levels) |
| **Difficulty** | Top-left | Current difficulty name |

---

## 7. Controls

| Input | Action |
|---|---|
| Arrow keys | **First press:** launch the hamster in that direction. **While moving:** change direction (applied at next tile boundary) |
| `R` | Restart current level |
| `Esc` | Pause / open menu |

> **Note:** WASD is intentionally excluded to keep controls simple. Undo is not available — continuous movement is a one-way commitment.

---

## 8. Visual Style

- **Art pipeline — two stages:**
  1. **Prototyping (Phases 1–3):** All graphics drawn **procedurally in code** using Godot's `_draw()` API — colored shapes, simple geometry. Zero external image assets needed.
  2. **Polish (Phase 4+):** Optionally replace procedural graphics with pixel-art `.png` sprites (Aseprite / LibreSprite). The swap is a texture change — no game logic changes required.
- **Procedural look:**
  - **Floor** — light beige/tan rounded rectangle
  - **Wall** — dark gray rounded rectangle with subtle border
  - **Key** — colored key shape (circle head + rectangle shaft)
  - **Door** — colored rectangle with keyhole cutout
  - **Start** — subtle pulsing circle
  - **Exit** — green/gold star or flag shape
  - **Teleporter** — two concentric circles; outer ring in lighter shade, inner circle in main color
  - **Quicky** — white circle body, two small round ears, black dot eyes, pink dot nose, tiny tail
- **Palette:** Soft, pastel-friendly colors; distinct hues for each key/door color
- **Tile size:** 64×64 px (configurable)
- **Character:** Stands out against all floor/wall tiles (white body, subtle dark outline)

---

## 9. Audio (Stretch Goal)

| Sound | Trigger |
|---|---|
| Soft footstep | Each move |
| Jingle | Key pickup |
| Click/unlock | Door opened |
| Fanfare | Level complete |
| Background | Light, cheerful loop |

---

## 10. Technical Spec

| Item | Choice |
|---|---|
| **Engine** | Godot 4.6.1 |
| **Language** | GDScript |
| **2D System** | Procedural `_draw()` rendering on a custom Grid node; no TileMap used |
| **UI** | Godot CanvasLayer + Control nodes for HUD overlay |
| **Target platform** | Desktop (Windows / macOS / Linux); web (HTML5 export) |
| **State management** | In-memory game state; level data loaded from JSON or TileMap scenes |
| **Minimum resolution** | 800 × 600 (stretch to fill, pixel-perfect scaling) |

---

## 11. Project Structure (Planned)

```
Quick/                          # Godot project root
├── project.godot               # Godot project file
├── scenes/
│   ├── main_menu.tscn          # Main menu (Play, Tutorial, Level Select, Difficulty, Quit)
│   ├── game.tscn               # Core gameplay scene (Grid + Player + HUD + Overlays)
│   └── level_select.tscn       # Level select screen (completed real levels only)
├── scripts/
│   ├── game.gd                 # Game loop, level loading, overlay management
│   ├── player.gd               # Hamster movement, direction changes, inventory
│   ├── grid.gd                 # Grid rendering (procedural _draw()), tile queries
│   ├── key_inventory.gd        # HUD key icons — add/remove on pickup/use
│   ├── level_loader.gd         # JSON level parser (real + tutorial paths)
│   ├── save_data.gd            # Autoload singleton — progress & settings persistence
│   ├── main_menu.gd            # Main menu logic
│   └── level_select.gd         # Level select logic
├── levels/
│   ├── level_01.json           # Real level data (name, index, grid)
│   ├── level_02.json
│   ├── ...
│   └── tutorial/
│       ├── level_01.json       # Tutorial levels
│       ├── level_02.json
│       └── level_03.json
├── assets/
│   ├── sprites/                # (future) pixel-art sprites
│   ├── fonts/
│   └── audio/                  # SFX and music
└── export_presets.cfg          # Export configurations
```

---

## 12. Development Phases

> **Progress tracking convention:**  
> Each task row includes a **Status** column. Values:  
> - ✅ — **Done** (completed and verified)  
> - 🔧 — **In progress** (currently being worked on)  
> - ⬜ — **Not started**  
>  
> When a task is completed, update its status here so the PRD always reflects current project state.

### Phase 1 — Foundation (M1–M2) ✅

Get a playable prototype with core movement on screen.

| # | Task | Status | Description | Done when… |
|---|---|---|---|---|
| 1.1 | Project setup | ✅ | Create Godot 4 project, configure resolution (800×600), import placeholder sprites | Project runs, blank window opens |
| 1.2 | TileSet & TileMap | ✅ | Define TileSet with Floor, Wall, Start, Exit tiles; draw all tiles procedurally via `_draw()` | Static grid renders correctly |
| 1.3 | Quicky scene | ✅ | Create hamster scene drawn procedurally (white circle + ears + eyes + nose); place on Start tile | Quicky appears on the grid |
| 1.4 | Input handling | ✅ | Arrow key detection; emit direction signal; ignore input before first press | First press sets direction |
| 1.5 | Continuous movement | ✅ | `_physics_process` moves Quicky at constant speed; snap direction change to tile boundary | Quicky slides smoothly, turns on grid lines |
| 1.6 | Wall collision → death | ✅ | Detect Wall tile ahead; trigger death state, stop movement, show placeholder "you died" | Hitting a wall kills Quicky |
| 1.7 | Exit detection | ✅ | Detect Exit tile; trigger win state, show placeholder "level complete" | Reaching exit completes level |

### Phase 2 — Keys & Doors (M3) ✅

Add the key/door puzzle layer.

| # | Task | Status | Description | Done when… |
|---|---|---|---|---|
| 2.1 | Key tile | ✅ | Add colored Key tile to TileSet; on overlap, remove tile and add key to inventory array | Key disappears when Quicky passes over it |
| 2.2 | Door tile | ✅ | Add colored Door tile to TileSet; on approach, check inventory for matching key | Door blocks or opens correctly |
| 2.3 | Door unlock | ✅ | If matching key held → consume key, convert door to floor, Quicky passes through | Door opens, key removed from inventory |
| 2.4 | Door collision → death | ✅ | If no matching key → treat as wall → death | Quicky dies on locked door |
| 2.5 | Key Inventory HUD | ✅ | CanvasLayer with HBoxContainer in top-right; add/remove colored key icons dynamically | Icons appear on pickup, disappear on use |

### Phase 3 — Level System (M4) ✅

Load levels from data and support progression.

| # | Task | Status | Description | Done when… |
|---|---|---|---|---|
| 3.1 | Level JSON schema | ✅ | Define JSON format: `name`, `index`, `grid` (2D string array). Rows/cols derived from grid. | Schema documented, sample file valid |
| 3.2 | Level loader | ✅ | GDScript parser reads JSON → populates TileMap + spawns Quicky at Start | Test level loads from JSON |
| 3.3 | Level complete → next | ✅ | On win, show summary then advance to next level | Player progresses through levels |
| 3.4 | Level select screen | ✅ | Grid of completed real levels (for replay); persist completion state (ConfigFile) | Player can replay any completed level |
| 3.5 | Design 3 tutorial levels | ✅ | Levels 1–3: teach movement, turning, exit | Playable & solvable tutorials |

### Phase 4 — UI & Polish (M5) 🔧

Complete HUD, menus, and game-feel improvements.

| # | Task | Status | Description | Done when… |
|---|---|---|---|---|
| 4.1 | Main menu scene | ✅ | Title "Quick", Play, Tutorial, Level Select, Difficulty, Quit buttons | Menu flows to game |
| 4.2 | Death screen overlay | ✅ | "Quicky crashed!" + Restart / Back to Menu buttons (in-game overlay, not separate scene) | Death flow feels clean |
| 4.3 | Win screen overlay | ✅ | "Level Complete!" + Next Level / Menu buttons (in-game overlay) | Win flow feels clean |
| 4.4 | Difficulty menu | ✅ | Easy (192 px/s) / Medium (288 px/s) / Hard (384 px/s) speed selection; persisted in SaveData | Speed changes per selection |
| 4.5 | Restart shortcut | ✅ | `R` key instantly reloads current level (already implemented, verify) | Quick retry loop works |
| 4.6 | Pause menu | ✅ | `Esc` pauses game; Resume / Restart / Quit options | Pause works mid-level |
| 4.7 | Quicky animations | ⬜ | Idle (breathing), run cycle (4 dir), death (poof), win (hop) — procedural or sprite-based | Animations play at correct moments |
| 4.8 | Tile art pass | ✅ | Polished procedural `_draw()` — brick walls, star exit, paneled doors, shadowed keys, Quicky with whiskers/shading | Grid looks polished |

### Phase 5 — Content (M6) ⬜

Design and ship a full set of levels.

| # | Task | Status | Description | Done when… |
|---|---|---|---|---|
| 5.1 | Levels 1–5 (Easy) | ⬜ | Single-color keys & doors; gentle turn timing | Playtested & solvable |
| 5.2 | Levels 6–12 (Medium) | ⬜ | Multi-color keys; tighter corridors; routing puzzles | Playtested & solvable |
| 5.3 | Levels 13–20 (Hard) | ⬜ | Complex mazes; limited keys; precise direction changes | Playtested & solvable |
| 5.4 | Difficulty curve review | ⬜ | Full playthrough; adjust order/layouts for smooth ramp | No unfair spikes |

### Phase 6 — Audio & Juice (M7) ⬜

Add sound, music, and screen effects.

| # | Task | Status | Description | Done when… |
|---|---|---|---|---|
| 6.1 | SFX | ⬜ | Footstep loop, key jingle, door unlock click, death poof, win fanfare | All triggers have sound |
| 6.2 | Background music | ⬜ | Light, cheerful loop for gameplay; menu music | Music plays & loops correctly |
| 6.3 | Screen shake | ⬜ | Subtle shake on death | Impact feels satisfying |
| 6.4 | Particles | ⬜ | Sparkle on key pickup; dust trail while running | Visual flair present |
| 6.5 | Transitions | ⬜ | Fade-in/out between scenes and levels | Smooth scene changes |

### Phase 7 — Ship (M8) ⬜

Prepare for release.

| # | Task | Status | Description | Done when… |
|---|---|---|---|---|
| 7.1 | Export — Windows | ⬜ | Build & test Windows executable | .exe runs standalone |
| 7.2 | Export — Web | ⬜ | HTML5 export; host on itch.io or similar | Playable in browser |
| 7.3 | Export — macOS/Linux | ⬜ | Build & basic smoke test | Binaries work |
| 7.4 | Icon & branding | ⬜ | App icon, itch.io page banner, screenshots | Store page looks good |
| 7.5 | Bug sweep | ⬜ | Full playthrough on each platform; fix blockers | No critical bugs |

### Phase 8 — Level Editor (Post-launch) ⬜

Community content creation tool.

| # | Task | Status | Description | Done when… |
|---|---|---|---|---|
| 8.1 | Editor UI | ⬜ | In-game tile painter: select block type, click to place/remove | User can paint a grid |
| 8.2 | Validation | ⬜ | Check level is solvable (start & exit exist, path possible) | Invalid levels rejected |
| 8.3 | Save / Load | ⬜ | Export level as JSON; import custom levels | Round-trip works |
| 8.4 | Share | ⬜ | Copy level code to clipboard / paste to load | Players can share levels |

---

## 13. Resolved Decisions

| Question | Decision |
|---|---|
| Hamster name | **Quicky** |
| Key reuse | **Always single-use** — one key opens one door, then both are gone |
| Mobile support | **No** — PC (desktop + web) only |
| Level editor | **Yes** — Phase 8, post-launch |
| Safe-zone block | **No** — the hamster never stops; that's the core challenge |
| Graphics approach | **Procedural** (`_draw()` API) for all phases; optional pixel-art swap in Phase 4+ |

---

*End of PRD*
