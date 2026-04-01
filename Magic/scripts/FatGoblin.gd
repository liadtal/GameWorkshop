extends GoblinBase

## Fat Goblin — 2 HP, twice the size of a normal goblin.

func _ready():
	hp = 2
	speed = 45.0
	chase_speed = 65.0
	death_particle_count = 10
	death_particle_size = 5.0
	death_spread = 50.0
	death_color = Color(0.25, 0.8, 0.15, 0.8)
	wander_pause_min = 0.5
	wander_pause_max = 1.5
	super._ready()

func _create_visuals() -> void:
	_draw_body(24, Color(0.25, 0.6, 0.15))

	# Belly highlight
	var belly = Polygon2D.new()
	var belly_pts: PackedVector2Array = PackedVector2Array()
	for i in range(12):
		var angle = i * TAU / 12
		belly_pts.append(Vector2(cos(angle) * 14, 4 + sin(angle) * 10))
	belly.polygon = belly_pts
	belly.color = Color(0.35, 0.7, 0.25)
	add_child(belly)

	_draw_ears(Color(0.3, 0.65, 0.2), 2.0)
	_draw_eyes(Color(1.0, 0.2, 0.2), 8.0, -6.0, 4.0)

func _add_alert_indicator() -> void:
	# Bigger & higher alert indicator for the fat goblin
	alert_indicator = Polygon2D.new()
	alert_indicator.polygon = PackedVector2Array([
		Vector2(-3, -34), Vector2(3, -34), Vector2(2, -46), Vector2(-2, -46)
	])
	alert_indicator.color = Color(1.0, 0.3, 0.1)
	alert_indicator.visible = false
	add_child(alert_indicator)
