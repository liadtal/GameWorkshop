extends Node2D
## Player — Quicky the hamster, drawn procedurally.
## Handles input, direction, and movement state.

const CELL_SIZE := 64
const BODY_RADIUS := 22.0

# --- Direction enum ---
enum Dir { NONE, UP, DOWN, LEFT, RIGHT }

# --- State ---
var current_dir: Dir = Dir.NONE      # No direction until first input
var queued_dir: Dir = Dir.NONE       # Direction queued by player (applied at tile boundary)
var has_started: bool = false         # True after first arrow press
var is_moving: bool = false           # True while sliding
var is_dead: bool = false             # True after wall collision

# --- Inventory ---
var inventory: Array = []              # Array of color name strings ("red", "blue", etc.)

# --- Grid tracking ---
var grid_col: int = 0                 # Current grid column
var grid_row: int = 0                 # Current grid row
var target_pixel: Vector2 = Vector2.ZERO  # Pixel position we're sliding toward
var grid_ref: Node2D = null           # Reference to Grid node (set by game.gd)

# --- Movement ---
const BASE_SPEED := 192.0                 # Default (Easy) speed in px/sec
var speed: float = BASE_SPEED             # Actual speed (set by difficulty)
var kids_mode: bool = false               # Kid's Mode: one tile per key press

# --- Signals ---
signal direction_changed(new_dir: int)
signal started_moving
signal died
signal reached_exit
signal key_picked_up(color_name: String)
signal key_used(color_name: String)

# Colors
const COLOR_BODY := Color(1.0, 1.0, 1.0)            # white
const COLOR_OUTLINE := Color(0.25, 0.25, 0.25)       # dark outline
const COLOR_EAR_INNER := Color(1.0, 0.71, 0.76)      # pink inner ear
const COLOR_EYE := Color(0.07, 0.07, 0.07)            # near-black
const COLOR_EYE_SHINE := Color(1.0, 1.0, 1.0)         # white highlight
const COLOR_NOSE := Color(1.0, 0.56, 0.63)            # pink nose
const COLOR_CHEEK := Color(1.0, 0.80, 0.82, 0.4)      # faint blush

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if is_dead or grid_ref == null:
		return

	var new_dir: Dir = Dir.NONE
	if Input.is_action_just_pressed("move_up"):
		new_dir = Dir.UP
	elif Input.is_action_just_pressed("move_down"):
		new_dir = Dir.DOWN
	elif Input.is_action_just_pressed("move_left"):
		new_dir = Dir.LEFT
	elif Input.is_action_just_pressed("move_right"):
		new_dir = Dir.RIGHT

	if new_dir == Dir.NONE:
		return

	# First press launches Quicky
	if not has_started:
		has_started = true
		current_dir = new_dir
		queued_dir = new_dir
		is_moving = true
		# Check if first tile in that direction is a wall or locked door
		var delta_v: Vector2i = dir_to_vec(current_dir)
		var next_col: int = grid_col + delta_v.x
		var next_row: int = grid_row + delta_v.y
		var next_tile: int = grid_ref.get_tile(next_col, next_row)
		if next_tile == grid_ref.Tile.WALL or next_tile == -1:
			_die()
		elif grid_ref.is_door_tile(next_tile):
			if not _try_unlock_door(next_col, next_row, next_tile):
				_die()
			else:
				_set_target_from_dir()
		else:
			_set_target_from_dir()
		started_moving.emit()
		direction_changed.emit(current_dir)
		return

	# Kid's Mode: each press moves one tile in the pressed direction
	if kids_mode:
		if is_moving:
			return  # still sliding to a tile, ignore input
		current_dir = new_dir
		queued_dir = new_dir
		is_moving = true
		var delta_v: Vector2i = dir_to_vec(current_dir)
		var next_col: int = grid_col + delta_v.x
		var next_row: int = grid_row + delta_v.y
		var next_tile: int = grid_ref.get_tile(next_col, next_row)
		if next_tile == grid_ref.Tile.WALL or next_tile == -1:
			_die()
		elif grid_ref.is_door_tile(next_tile):
			if not _try_unlock_door(next_col, next_row, next_tile):
				_die()
			else:
				_set_target_from_dir()
		else:
			_set_target_from_dir()
		direction_changed.emit(current_dir)
		return

	# While moving, queue direction change (applied at next tile boundary)
	if new_dir != current_dir:
		queued_dir = new_dir

## Returns the direction as a Vector2i offset (col_delta, row_delta).
static func dir_to_vec(dir: Dir) -> Vector2i:
	match dir:
		Dir.UP:    return Vector2i(0, -1)
		Dir.DOWN:  return Vector2i(0, 1)
		Dir.LEFT:  return Vector2i(-1, 0)
		Dir.RIGHT: return Vector2i(1, 0)
		_:         return Vector2i(0, 0)

## Initialize grid position (called by game.gd after placement).
func init_grid_pos(col: int, row: int, grid_node: Node2D) -> void:
	grid_col = col
	grid_row = row
	grid_ref = grid_node

func _physics_process(delta: float) -> void:
	if not is_moving or is_dead:
		return

	# Move toward target pixel position
	var move_vec: Vector2 = (target_pixel - position).normalized()
	var step: float = speed * delta
	var dist_remaining: float = position.distance_to(target_pixel)

	if step >= dist_remaining:
		# We've arrived at the target tile
		position = target_pixel
		_on_tile_reached()
	else:
		position += move_vec * step

func _on_tile_reached() -> void:
	# Check if current tile is a key — pick it up
	var tile: int = grid_ref.get_tile(grid_col, grid_row)
	if grid_ref.is_key_tile(tile):
		var color_name: String = grid_ref.tile_color_name(tile)
		inventory.append(color_name)
		grid_ref.set_tile(grid_col, grid_row, grid_ref.Tile.FLOOR)
		key_picked_up.emit(color_name)

	# Re-read tile (may have just changed to floor)
	tile = grid_ref.get_tile(grid_col, grid_row)
	if tile == grid_ref.Tile.EXIT:
		is_moving = false
		reached_exit.emit()
		return

	# Check if current tile is a teleporter — teleport to the paired one
	if grid_ref.is_teleporter_tile(tile):
		var pair_pos: Vector2i = grid_ref.find_teleporter_pair(grid_col, grid_row, tile)
		if pair_pos != Vector2i(-1, -1):
			grid_col = pair_pos.x
			grid_row = pair_pos.y
			position = grid_ref.position + grid_ref.grid_to_pixel(grid_col, grid_row)

	# Apply queued direction change at tile boundary
	if queued_dir != current_dir:
		current_dir = queued_dir
		direction_changed.emit(current_dir)

	# Check next tile before moving — wall / locked door / OOB = death
	var delta_v: Vector2i = dir_to_vec(current_dir)
	var next_col: int = grid_col + delta_v.x
	var next_row: int = grid_row + delta_v.y
	var next_tile: int = grid_ref.get_tile(next_col, next_row)

	if next_tile == grid_ref.Tile.WALL or next_tile == -1:
		if kids_mode:
			is_moving = false  # just stop, don't die
			return
		_die()
		return

	# Door check — unlock or die
	if grid_ref.is_door_tile(next_tile):
		if not _try_unlock_door(next_col, next_row, next_tile):
			if kids_mode:
				is_moving = false  # just stop, don't die
				return
			_die()
			return

	# Kid's Mode — stop after each tile
	if kids_mode:
		is_moving = false
		return

	# Safe to advance
	_set_target_from_dir()

func _die() -> void:
	is_moving = false
	is_dead = true
	died.emit()

## Try to unlock a door. Returns true if successful (key consumed, door becomes floor).
func _try_unlock_door(col: int, row: int, door_tile: int) -> bool:
	var color_name: String = grid_ref.tile_color_name(door_tile)
	var idx: int = inventory.find(color_name)
	if idx == -1:
		return false
	# Consume key and open door
	inventory.remove_at(idx)
	grid_ref.set_tile(col, row, grid_ref.Tile.FLOOR)
	key_used.emit(color_name)
	return true

func _set_target_from_dir() -> void:
	var delta_v: Vector2i = dir_to_vec(current_dir)
	grid_col += delta_v.x
	grid_row += delta_v.y
	target_pixel = grid_ref.position + grid_ref.grid_to_pixel(grid_col, grid_row)

func _draw() -> void:
	var center := Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)

	# --- Drop shadow ---
	draw_circle(center + Vector2(2, 3), BODY_RADIUS * 0.9, Color(0, 0, 0, 0.12))

	# --- Ears (behind body) ---
	var ear_offset_x := 14.0
	var ear_offset_y := -16.0
	var ear_radius_x := 8.0
	var ear_radius_y := 11.0
	_draw_ear(center + Vector2(-ear_offset_x, ear_offset_y), ear_radius_x, ear_radius_y)
	_draw_ear(center + Vector2(ear_offset_x, ear_offset_y), ear_radius_x, ear_radius_y)

	# --- Body (white circle with outline + subtle gradient) ---
	draw_circle(center, BODY_RADIUS + 1.5, COLOR_OUTLINE)
	draw_circle(center, BODY_RADIUS, COLOR_BODY)
	# Body shading — lighter top, darker bottom
	draw_circle(center + Vector2(0, -4), BODY_RADIUS * 0.65, Color(1, 1, 1, 0.25))
	draw_circle(center + Vector2(0, 6), BODY_RADIUS * 0.55, Color(0.9, 0.88, 0.85, 0.3))

	# --- Eyes ---
	var eye_offset_x := 8.0
	var eye_offset_y := -3.0
	var eye_radius := 3.8
	# Left eye
	var le := center + Vector2(-eye_offset_x, eye_offset_y)
	draw_circle(le, eye_radius + 0.5, COLOR_OUTLINE)
	draw_circle(le, eye_radius, COLOR_EYE)
	draw_circle(le + Vector2(1.2, -1.4), 1.5, COLOR_EYE_SHINE)
	draw_circle(le + Vector2(-0.8, 0.8), 0.7, Color(1, 1, 1, 0.4))
	# Right eye
	var re := center + Vector2(eye_offset_x, eye_offset_y)
	draw_circle(re, eye_radius + 0.5, COLOR_OUTLINE)
	draw_circle(re, eye_radius, COLOR_EYE)
	draw_circle(re + Vector2(1.2, -1.4), 1.5, COLOR_EYE_SHINE)
	draw_circle(re + Vector2(-0.8, 0.8), 0.7, Color(1, 1, 1, 0.4))

	# --- Nose ---
	var nose_pos := center + Vector2(0, 5.0)
	_draw_ellipse(nose_pos, 3.2, 2.4, COLOR_NOSE)
	# Nose highlight
	draw_circle(nose_pos + Vector2(-0.8, -0.6), 1.0, Color(1, 0.8, 0.85, 0.5))

	# --- Cheeks (faint blush) ---
	draw_circle(center + Vector2(-13.0, 4.0), 5.5, COLOR_CHEEK)
	draw_circle(center + Vector2(13.0, 4.0), 5.5, COLOR_CHEEK)

	# --- Whiskers ---
	var whisker_color := Color(0.6, 0.6, 0.6, 0.35)
	# Left whiskers
	draw_line(center + Vector2(-10, 4), center + Vector2(-22, 1), whisker_color, 0.8)
	draw_line(center + Vector2(-10, 6), center + Vector2(-22, 7), whisker_color, 0.8)
	# Right whiskers
	draw_line(center + Vector2(10, 4), center + Vector2(22, 1), whisker_color, 0.8)
	draw_line(center + Vector2(10, 6), center + Vector2(22, 7), whisker_color, 0.8)

	# --- Mouth ---
	var mouth_left := center + Vector2(-3.0, 8.0)
	var mouth_right := center + Vector2(3.0, 8.0)
	var mouth_bottom := center + Vector2(0.0, 10.5)
	draw_line(mouth_left, mouth_bottom, COLOR_OUTLINE, 1.0)
	draw_line(mouth_right, mouth_bottom, COLOR_OUTLINE, 1.0)

func _draw_ear(pos: Vector2, rx: float, ry: float) -> void:
	# Outer ear (outline)
	_draw_ellipse(pos, rx + 1.5, ry + 1.5, COLOR_OUTLINE)
	# Outer ear (white)
	_draw_ellipse(pos, rx, ry, COLOR_BODY)
	# Inner ear (pink)
	_draw_ellipse(pos, rx * 0.55, ry * 0.6, COLOR_EAR_INNER)
	# Inner ear highlight
	_draw_ellipse(pos + Vector2(-1, -2), rx * 0.25, ry * 0.25, Color(1, 0.85, 0.9, 0.45))

func _draw_ellipse(pos: Vector2, rx: float, ry: float, color: Color) -> void:
	# Approximate ellipse with a polygon
	var points := PackedVector2Array()
	var segments := 24
	for i in range(segments):
		var angle := i * TAU / segments
		points.append(pos + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
