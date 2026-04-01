extends Node2D
## Grid — draws the level grid procedurally using _draw().
## Each tile is a 64×64 px cell rendered as colored shapes.

# --- Tile types ---
enum Tile { FLOOR, WALL, START, EXIT, KEY_RED, KEY_BLUE, KEY_GREEN, KEY_YELLOW, DOOR_RED, DOOR_BLUE, DOOR_GREEN, DOOR_YELLOW, TELEPORT_RED, TELEPORT_BLUE, TELEPORT_GREEN, TELEPORT_YELLOW }

# --- Constants ---
const CELL_SIZE := 64
var grid_cols: int = 10
var grid_rows: int = 8

# --- Colors ---
const COLOR_BG := Color(0.13, 0.13, 0.17)           # dark background behind grid

const COLOR_FLOOR := Color(0.92, 0.88, 0.80)        # warm beige
const COLOR_FLOOR_DARK := Color(0.87, 0.83, 0.75)   # floor edge/shadow
const COLOR_FLOOR_LIGHT := Color(0.96, 0.93, 0.87)  # floor highlight
const COLOR_FLOOR_LINE := Color(0.84, 0.80, 0.72, 0.4) # subtle grid line

const COLOR_WALL := Color(0.35, 0.33, 0.38)         # dark stone
const COLOR_WALL_LIGHT := Color(0.42, 0.40, 0.46)   # wall highlight
const COLOR_WALL_DARK := Color(0.22, 0.20, 0.24)    # wall shadow / mortar
const COLOR_WALL_BORDER := Color(0.18, 0.17, 0.20)  # outer edge

const COLOR_START := Color(0.55, 0.78, 1.0, 0.35)   # soft blue
const COLOR_START_RING := Color(0.55, 0.78, 1.0, 0.55)

const COLOR_EXIT := Color(0.25, 0.75, 0.35)         # green
const COLOR_EXIT_GLOW := Color(0.30, 0.85, 0.40, 0.25)
const COLOR_EXIT_ACCENT := Color(1.0, 0.88, 0.25)   # gold

# Key / Door palette
const KEY_DOOR_COLORS := {
	"red":    Color(0.88, 0.20, 0.18),
	"blue":   Color(0.22, 0.42, 0.92),
	"green":  Color(0.18, 0.75, 0.28),
	"yellow": Color(0.92, 0.82, 0.18),
}
const KEY_DOOR_LIGHT := {
	"red":    Color(1.0, 0.45, 0.40),
	"blue":   Color(0.50, 0.65, 1.0),
	"green":  Color(0.45, 0.90, 0.50),
	"yellow": Color(1.0, 0.95, 0.50),
}
const COLOR_DOOR_FRAME := Color(0.15, 0.10, 0.06)
const COLOR_DOOR_SHADOW := Color(0.0, 0.0, 0.0, 0.3)
const COLOR_KEY_OUTLINE := Color(0.12, 0.08, 0.04)

# Teleporter palette (dark + light shades per color)
const TELEPORT_DARK := {
	"red":    Color(0.80, 0.15, 0.12),
	"blue":   Color(0.18, 0.35, 0.85),
	"green":  Color(0.12, 0.65, 0.22),
	"yellow": Color(0.85, 0.75, 0.12),
}
const TELEPORT_LIGHT := {
	"red":    Color(1.0, 0.50, 0.45),
	"blue":   Color(0.55, 0.70, 1.0),
	"green":  Color(0.50, 0.92, 0.55),
	"yellow": Color(1.0, 0.96, 0.55),
}

# --- Level data (2D array) ---
var grid: Array = []

func _ready() -> void:
	# Grid data is loaded externally by game.gd via load_level_data().
	# Only use test level as fallback if running this scene standalone.
	pass

## Load a level from parsed level data dict (from LevelLoader).
func load_level_data(level_data: Dictionary) -> void:
	grid = level_data.get("grid", [])
	grid_rows = level_data.get("rows", 0)
	grid_cols = level_data.get("cols", 0)
	_center_grid()
	queue_redraw()

func _center_grid() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(800, 600)  # fallback
	var grid_pixel_w := grid_cols * CELL_SIZE
	var grid_pixel_h := grid_rows * CELL_SIZE
	position.x = (viewport_size.x - grid_pixel_w) / 2.0
	position.y = (viewport_size.y - grid_pixel_h) / 2.0

func _load_test_level() -> void:
	# W=Wall, F=Floor, S=Start, E=Exit, Kr=Key red, Dr=Door red, Kb=Key blue, Db=Door blue
	var W  := Tile.WALL
	var F  := Tile.FLOOR
	var S  := Tile.START
	var E  := Tile.EXIT
	var Kr := Tile.KEY_RED
	var Dr := Tile.DOOR_RED
	var Kb := Tile.KEY_BLUE
	var Db := Tile.DOOR_BLUE
	grid = [
		[W, W, W, W, W, W, W, W, W, W],
		[W, S, F, F, W, F, Kr,F, F, W],
		[W, F, W, F, Kb,F, W, F, F, W],
		[W, F, W, F, W, F, F, F, F, W],
		[W, F, F, F, F, F, W, F, F, W],
		[W, W, W, F, F, W, Dr,F, F, W],
		[W, F, F, F, F, Db,F, F, E, W],
		[W, W, W, W, W, W, W, W, W, W],
	]

func _draw() -> void:
	# Background behind the whole grid
	var bg_rect := Rect2(-4, -4, grid_cols * CELL_SIZE + 8, grid_rows * CELL_SIZE + 8)
	draw_rect(bg_rect, COLOR_BG)

	for row in range(grid.size()):
		for col in range(grid[row].size()):
			var tile: Tile = grid[row][col]
			var rect := Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			_draw_tile(tile, rect, col, row)

func _draw_tile(tile: Tile, rect: Rect2, col: int, row: int) -> void:
	match tile:
		Tile.FLOOR:
			_draw_floor(rect)
		Tile.WALL:
			_draw_wall(rect, col, row)
		Tile.START:
			_draw_floor(rect)
			_draw_start_marker(rect)
		Tile.EXIT:
			_draw_floor(rect)
			_draw_exit_marker(rect)
		Tile.KEY_RED, Tile.KEY_BLUE, Tile.KEY_GREEN, Tile.KEY_YELLOW:
			_draw_floor(rect)
			_draw_key(rect, _tile_color(tile), _tile_color_light(tile))
		Tile.DOOR_RED, Tile.DOOR_BLUE, Tile.DOOR_GREEN, Tile.DOOR_YELLOW:
			_draw_door(rect, _tile_color(tile), _tile_color_light(tile))
		Tile.TELEPORT_RED, Tile.TELEPORT_BLUE, Tile.TELEPORT_GREEN, Tile.TELEPORT_YELLOW:
			_draw_floor(rect)
			_draw_teleporter(rect, tile)

func _draw_floor(rect: Rect2) -> void:
	# Base fill
	draw_rect(rect, COLOR_FLOOR)
	# Top-left highlight strip
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 1), COLOR_FLOOR_LIGHT)
	draw_rect(Rect2(rect.position.x, rect.position.y, 1, rect.size.y), COLOR_FLOOR_LIGHT)
	# Bottom-right shadow strip
	draw_rect(Rect2(rect.position.x, rect.end.y - 1, rect.size.x, 1), COLOR_FLOOR_DARK)
	draw_rect(Rect2(rect.end.x - 1, rect.position.y, 1, rect.size.y), COLOR_FLOOR_DARK)
	# Subtle grid lines
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 0.5), COLOR_FLOOR_LINE)
	draw_rect(Rect2(rect.position.x, rect.position.y, 0.5, rect.size.y), COLOR_FLOOR_LINE)

func _draw_wall(rect: Rect2, col: int, row: int) -> void:
	# Outer border
	draw_rect(rect, COLOR_WALL_BORDER)
	# Main stone fill (inset)
	var inner := Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4))
	draw_rect(inner, COLOR_WALL)

	# Brick-like pattern — two rows of bricks per tile
	var bw := inner.size.x   # brick area width
	var bh := inner.size.y / 2.0
	var mortar := 1.5

	# Top row: 2 bricks
	var b1 := Rect2(inner.position.x, inner.position.y, bw / 2.0 - mortar / 2.0, bh - mortar / 2.0)
	var b2 := Rect2(inner.position.x + bw / 2.0 + mortar / 2.0, inner.position.y, bw / 2.0 - mortar / 2.0, bh - mortar / 2.0)
	# Bottom row: offset by half, 3 partial bricks
	var b3 := Rect2(inner.position.x, inner.position.y + bh + mortar / 2.0, bw / 3.0 - mortar / 2.0, bh - mortar / 2.0)
	var b4 := Rect2(inner.position.x + bw / 3.0 + mortar / 2.0, inner.position.y + bh + mortar / 2.0, bw / 3.0 - mortar, bh - mortar / 2.0)
	var b5 := Rect2(inner.position.x + 2.0 * bw / 3.0 + mortar / 2.0, inner.position.y + bh + mortar / 2.0, bw / 3.0 - mortar / 2.0, bh - mortar / 2.0)

	# Draw bricks with slight color variation
	draw_rect(b1, COLOR_WALL_LIGHT)
	draw_rect(b2, COLOR_WALL)
	draw_rect(b3, COLOR_WALL)
	draw_rect(b4, COLOR_WALL_LIGHT)
	draw_rect(b5, COLOR_WALL)

	# Mortar lines (dark grooves)
	draw_rect(Rect2(inner.position.x, inner.position.y + bh - mortar / 2.0, bw, mortar), COLOR_WALL_DARK)
	draw_rect(Rect2(inner.position.x + bw / 2.0 - mortar / 2.0, inner.position.y, mortar, bh - mortar / 2.0), COLOR_WALL_DARK)
	draw_rect(Rect2(inner.position.x + bw / 3.0 - mortar / 2.0, inner.position.y + bh + mortar / 2.0, mortar, bh - mortar / 2.0), COLOR_WALL_DARK)
	draw_rect(Rect2(inner.position.x + 2.0 * bw / 3.0 - mortar / 2.0, inner.position.y + bh + mortar / 2.0, mortar, bh - mortar / 2.0), COLOR_WALL_DARK)

	# Top highlight edge
	draw_rect(Rect2(inner.position.x, inner.position.y, inner.size.x, 1), Color(1, 1, 1, 0.06))

func _draw_start_marker(rect: Rect2) -> void:
	var center := rect.get_center()
	# Outer glow ring
	draw_circle(center, CELL_SIZE * 0.30, COLOR_START)
	# Inner ring
	draw_circle(center, CELL_SIZE * 0.22, COLOR_START_RING)
	# Bright center dot
	draw_circle(center, CELL_SIZE * 0.08, Color(0.7, 0.88, 1.0, 0.7))

func _draw_exit_marker(rect: Rect2) -> void:
	var center := rect.get_center()
	# Outer glow
	draw_circle(center, CELL_SIZE * 0.38, COLOR_EXIT_GLOW)
	# Green base
	draw_circle(center, CELL_SIZE * 0.28, COLOR_EXIT)
	# Gold star shape (simplified as overlapping triangles)
	_draw_star(center, CELL_SIZE * 0.16, 5, COLOR_EXIT_ACCENT)
	# Bright center
	draw_circle(center, CELL_SIZE * 0.06, Color(1, 1, 0.85, 0.9))

func _draw_star(center: Vector2, radius: float, points: int, color: Color) -> void:
	var verts := PackedVector2Array()
	var inner_r := radius * 0.45
	for i in range(points * 2):
		var angle := i * PI / points - PI / 2.0
		var r := radius if i % 2 == 0 else inner_r
		verts.append(center + Vector2(cos(angle) * r, sin(angle) * r))
	draw_colored_polygon(verts, color)

func _draw_key(rect: Rect2, tint: Color, tint_light: Color) -> void:
	var cx := rect.get_center().x
	var cy := rect.get_center().y
	var head_r := CELL_SIZE * 0.17

	# Floating shadow
	draw_circle(Vector2(cx + 2, cy + 3), head_r * 1.6, Color(0, 0, 0, 0.12))

	# Key head — outline + fill + highlight
	draw_circle(Vector2(cx, cy - 5), head_r + 2.0, COLOR_KEY_OUTLINE)
	draw_circle(Vector2(cx, cy - 5), head_r, tint)
	draw_circle(Vector2(cx - 2, cy - 8), head_r * 0.35, tint_light)  # highlight
	# Hole in head
	draw_circle(Vector2(cx, cy - 5), head_r * 0.30, COLOR_KEY_OUTLINE)

	# Shaft — with outline
	var sw := 4.0
	var shaft_top := cy - 5 + head_r - 2
	var shaft_bot := cy + 14
	draw_rect(Rect2(cx - sw / 2.0 - 1, shaft_top, sw + 2, shaft_bot - shaft_top + 1), COLOR_KEY_OUTLINE)
	draw_rect(Rect2(cx - sw / 2.0, shaft_top, sw, shaft_bot - shaft_top), tint)
	# Highlight line on shaft
	draw_rect(Rect2(cx - sw / 2.0, shaft_top, 1.5, shaft_bot - shaft_top), tint_light)

	# Teeth — with outline
	draw_rect(Rect2(cx - 1, shaft_bot - 7, 7, 3.5), COLOR_KEY_OUTLINE)
	draw_rect(Rect2(cx, shaft_bot - 6, 5, 2.5), tint)
	draw_rect(Rect2(cx - 1, shaft_bot - 13, 6, 3.5), COLOR_KEY_OUTLINE)
	draw_rect(Rect2(cx, shaft_bot - 12, 4, 2.5), tint)

func _draw_door(rect: Rect2, tint: Color, tint_light: Color) -> void:
	# Dark frame/border
	draw_rect(rect, COLOR_DOOR_FRAME)

	# Door body with inset
	var body := Rect2(rect.position + Vector2(4, 4), rect.size - Vector2(8, 8))
	draw_rect(body, tint)

	# Panels — two raised rectangles on the door
	var panel_margin := 6.0
	var panel_gap := 4.0
	var panel_h := (body.size.y - panel_gap - panel_margin * 2) / 2.0
	var panel_w := body.size.x - panel_margin * 2

	var p1 := Rect2(body.position.x + panel_margin, body.position.y + panel_margin, panel_w, panel_h)
	var p2 := Rect2(body.position.x + panel_margin, body.position.y + panel_margin + panel_h + panel_gap, panel_w, panel_h)

	# Panel recesses (darker)
	var panel_dark := tint.darkened(0.2)
	draw_rect(p1, panel_dark)
	draw_rect(p2, panel_dark)
	# Panel highlights (top-left edges)
	draw_rect(Rect2(p1.position.x, p1.position.y, p1.size.x, 1), tint_light)
	draw_rect(Rect2(p1.position.x, p1.position.y, 1, p1.size.y), tint_light)
	draw_rect(Rect2(p2.position.x, p2.position.y, p2.size.x, 1), tint_light)
	draw_rect(Rect2(p2.position.x, p2.position.y, 1, p2.size.y), tint_light)

	# Frame highlight (top + left edges)
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 2), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(rect.position.x, rect.position.y, 2, rect.size.y), Color(1, 1, 1, 0.05))

	# Keyhole
	var kc := body.get_center() + Vector2(panel_w * 0.3, 0)
	draw_circle(kc + Vector2(0, -2), 4.5, COLOR_DOOR_FRAME)
	draw_rect(Rect2(kc.x - 2, kc.y + 1, 4, 8), COLOR_DOOR_FRAME)
	# Keyhole highlight
	draw_circle(kc + Vector2(-1, -3), 1.5, Color(1, 1, 1, 0.15))

func _draw_teleporter(rect: Rect2, tile: int) -> void:
	var center := rect.get_center()
	var cname := tile_color_name(tile)
	var color_dark: Color = TELEPORT_DARK.get(cname, Color.WHITE)
	var color_light: Color = TELEPORT_LIGHT.get(cname, Color.WHITE)

	# Subtle shadow
	draw_circle(center + Vector2(2, 3), CELL_SIZE * 0.34, Color(0, 0, 0, 0.10))
	# Outer ring (lighter shade)
	draw_circle(center, CELL_SIZE * 0.36, color_light)
	# Gap ring (floor color peek-through for ring effect)
	draw_circle(center, CELL_SIZE * 0.27, COLOR_FLOOR)
	# Inner circle (darker / main shade)
	draw_circle(center, CELL_SIZE * 0.22, color_dark)
	# Bright center highlight
	draw_circle(center + Vector2(-2, -2), CELL_SIZE * 0.08, color_light.lightened(0.35))

# --- Public helpers ---

## Returns the tile type at a grid coordinate, or -1 if out of bounds.
func get_tile(col: int, row: int) -> int:
	if row < 0 or row >= grid.size() or col < 0 or col >= grid[row].size():
		return -1
	return grid[row][col]

## Set a tile at a grid coordinate (e.g., convert key/door to floor).
func set_tile(col: int, row: int, tile: int) -> void:
	if row >= 0 and row < grid.size() and col >= 0 and col < grid[row].size():
		grid[row][col] = tile
		queue_redraw()

## Returns true if the tile is a teleporter.
static func is_teleporter_tile(tile: int) -> bool:
	return tile in [Tile.TELEPORT_RED, Tile.TELEPORT_BLUE, Tile.TELEPORT_GREEN, Tile.TELEPORT_YELLOW]

## Returns true if the tile is a key.
static func is_key_tile(tile: int) -> bool:
	return tile in [Tile.KEY_RED, Tile.KEY_BLUE, Tile.KEY_GREEN, Tile.KEY_YELLOW]

## Returns true if the tile is a door.
static func is_door_tile(tile: int) -> bool:
	return tile in [Tile.DOOR_RED, Tile.DOOR_BLUE, Tile.DOOR_GREEN, Tile.DOOR_YELLOW]

## Returns the color name string for a key, door, or teleporter tile.
static func tile_color_name(tile: int) -> String:
	match tile:
		Tile.KEY_RED, Tile.DOOR_RED, Tile.TELEPORT_RED:          return "red"
		Tile.KEY_BLUE, Tile.DOOR_BLUE, Tile.TELEPORT_BLUE:       return "blue"
		Tile.KEY_GREEN, Tile.DOOR_GREEN, Tile.TELEPORT_GREEN:    return "green"
		Tile.KEY_YELLOW, Tile.DOOR_YELLOW, Tile.TELEPORT_YELLOW: return "yellow"
		_: return ""

## Returns the matching key tile type for a given door tile.
static func key_for_door(door_tile: int) -> int:
	match door_tile:
		Tile.DOOR_RED:    return Tile.KEY_RED
		Tile.DOOR_BLUE:   return Tile.KEY_BLUE
		Tile.DOOR_GREEN:  return Tile.KEY_GREEN
		Tile.DOOR_YELLOW: return Tile.KEY_YELLOW
		_: return -1

## Returns the Color for a key/door tile.
func _tile_color(tile: int) -> Color:
	var cname := tile_color_name(tile)
	if cname != "" and KEY_DOOR_COLORS.has(cname):
		return KEY_DOOR_COLORS[cname]
	return Color.WHITE

## Returns the lighter Color for a key/door tile (highlights).
func _tile_color_light(tile: int) -> Color:
	var cname := tile_color_name(tile)
	if cname != "" and KEY_DOOR_LIGHT.has(cname):
		return KEY_DOOR_LIGHT[cname]
	return Color.WHITE

## Returns the pixel position (top-left corner) for a grid coordinate.
func grid_to_pixel(col: int, row: int) -> Vector2:
	return Vector2(col * CELL_SIZE, row * CELL_SIZE)

## Returns the center pixel position for a grid coordinate.
func grid_to_pixel_center(col: int, row: int) -> Vector2:
	return Vector2(col * CELL_SIZE + CELL_SIZE / 2.0, row * CELL_SIZE + CELL_SIZE / 2.0)

## Finds the first tile of the given type and returns Vector2i(col, row), or Vector2i(-1,-1).
func find_tile(tile_type: Tile) -> Vector2i:
	for row in range(grid.size()):
		for col in range(grid[row].size()):
			if grid[row][col] == tile_type:
				return Vector2i(col, row)
	return Vector2i(-1, -1)

## Finds the paired teleporter of the same color at a different position.
## Returns Vector2i(col, row) of the paired teleporter, or Vector2i(-1,-1) if none found.
func find_teleporter_pair(src_col: int, src_row: int, tile_type: int) -> Vector2i:
	for row in range(grid.size()):
		for col in range(grid[row].size()):
			if grid[row][col] == tile_type and (col != src_col or row != src_row):
				return Vector2i(col, row)
	return Vector2i(-1, -1)
