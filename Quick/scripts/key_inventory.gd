extends Control
## KeyInventory — HUD panel that displays collected keys as colored icons.
## Drawn procedurally via _draw(); updated when keys are picked up or used.

# Key colors (same palette as grid.gd)
const KEY_COLORS := {
	"red":    Color(0.90, 0.22, 0.20),
	"blue":   Color(0.20, 0.40, 0.90),
	"green":  Color(0.20, 0.78, 0.30),
	"yellow": Color(0.95, 0.85, 0.20),
}
const COLOR_DARK := Color(0.18, 0.12, 0.08)
const COLOR_BG := Color(0, 0, 0, 0.3)

const ICON_SIZE := 32.0      # Each key icon area
const ICON_PAD := 6.0        # Padding between icons
const MARGIN := 10.0         # Margin from screen edge

var keys: Array = []          # Array of color name strings

func _ready() -> void:
	# Anchor to top-right
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func add_key(color_name: String) -> void:
	keys.append(color_name)
	_update_size()
	queue_redraw()

func remove_key(color_name: String) -> void:
	var idx := keys.find(color_name)
	if idx != -1:
		keys.remove_at(idx)
		_update_size()
		queue_redraw()

func clear_keys() -> void:
	keys.clear()
	_update_size()
	queue_redraw()

func _update_size() -> void:
	var count := keys.size()
	if count == 0:
		custom_minimum_size = Vector2.ZERO
		size = Vector2.ZERO
		return
	var w := count * ICON_SIZE + (count - 1) * ICON_PAD + MARGIN * 2
	var h := ICON_SIZE + MARGIN * 2
	custom_minimum_size = Vector2(w, h)
	size = Vector2(w, h)

func _draw() -> void:
	if keys.is_empty():
		return
	# Background panel
	var bg_rect := Rect2(Vector2.ZERO, size)
	draw_rect(bg_rect, COLOR_BG)
	# Draw each key icon
	for i in range(keys.size()):
		var color_name: String = keys[i]
		var tint: Color = KEY_COLORS.get(color_name, Color.WHITE)
		var x_offset := MARGIN + i * (ICON_SIZE + ICON_PAD)
		var y_offset := MARGIN
		_draw_key_icon(Vector2(x_offset, y_offset), ICON_SIZE, tint)

func _draw_key_icon(origin: Vector2, icon_size: float, tint: Color) -> void:
	var cx := origin.x + icon_size / 2.0
	var cy := origin.y + icon_size / 2.0
	# Key head (circle)
	var head_r := icon_size * 0.22
	draw_circle(Vector2(cx, cy - 4), head_r + 1.0, COLOR_DARK)
	draw_circle(Vector2(cx, cy - 4), head_r, tint)
	# Hole in head
	draw_circle(Vector2(cx, cy - 4), head_r * 0.35, COLOR_DARK)
	# Shaft
	var shaft_w := 2.5
	var shaft_top := cy - 4 + head_r - 1
	var shaft_bot := cy + 10
	draw_rect(Rect2(cx - shaft_w / 2.0, shaft_top, shaft_w, shaft_bot - shaft_top), tint)
	# Teeth
	draw_rect(Rect2(cx, shaft_bot - 4, 3, 2), tint)
	draw_rect(Rect2(cx, shaft_bot - 8, 2.5, 2), tint)
