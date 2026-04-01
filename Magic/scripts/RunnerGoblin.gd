extends GoblinBase

## Runner Goblin — twice as fast as a regular goblin, with a bandana.

func _ready():
	speed = 120.0
	chase_speed = 180.0
	wander_pause_min = 0.2
	wander_pause_max = 0.6
	wander_move_min = 0.8
	wander_move_max = 2.0
	super._ready()

func _create_visuals() -> void:
	_draw_body(12, Color(0.15, 0.8, 0.3))
	_draw_ears(Color(0.2, 0.85, 0.35))

	# Bandana (red band across forehead)
	var bandana = Polygon2D.new()
	bandana.polygon = PackedVector2Array([
		Vector2(-13, -10), Vector2(13, -10), Vector2(13, -6), Vector2(-13, -6)
	])
	bandana.color = Color(0.9, 0.15, 0.15)
	add_child(bandana)
	# Bandana tail (flowing right)
	var tail = Polygon2D.new()
	tail.polygon = PackedVector2Array([
		Vector2(13, -10), Vector2(22, -14), Vector2(20, -8), Vector2(13, -6)
	])
	tail.color = Color(0.85, 0.1, 0.1)
	add_child(tail)

	_draw_eyes(Color(1.0, 0.9, 0.1))  # Yellow fierce eyes

