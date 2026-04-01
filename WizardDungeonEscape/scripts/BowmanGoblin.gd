extends GoblinBase

## Bowman Goblin — 1.5x sight range, shoots arrows at the wizard.

var shoot_cooldown: float = 2.0
var arrow_speed: float = 300.0  # 2x wizard speed
var shoot_timer: float = 0.0

func _ready():
	sight_range = 270.0  # 1.5x normal
	chase_speed = 70.0
	super._ready()

func _create_visuals() -> void:
	_draw_body(12, Color(0.3, 0.65, 0.2))
	_draw_ears(Color(0.35, 0.7, 0.25))

	# Bow (brown arc on the right side)
	var bow = Line2D.new()
	bow.width = 2.5
	bow.default_color = Color(0.55, 0.35, 0.15)
	for i in range(9):
		var angle = -PI / 3 + (i / 8.0) * (2 * PI / 3)
		bow.add_point(Vector2(14 + cos(angle) * 10, sin(angle) * 10))
	add_child(bow)
	# Bowstring
	var bowstring = Line2D.new()
	bowstring.width = 1.0
	bowstring.default_color = Color(0.8, 0.8, 0.7)
	bowstring.add_point(Vector2(14 + cos(-PI / 3) * 10, sin(-PI / 3) * 10))
	bowstring.add_point(Vector2(14 + cos(PI / 3) * 10, sin(PI / 3) * 10))
	add_child(bowstring)

	_draw_eyes(Color(1.0, 0.6, 0.1))  # Orange eyes

func _on_see_wizard(delta: float) -> void:
	shoot_timer -= delta
	if shoot_timer <= 0 and is_instance_valid(target_wizard):
		_shoot_arrow()
		shoot_timer = shoot_cooldown

func _chase_behavior(_delta: float) -> void:
	# Keep some distance — stop if close enough to shoot
	var dist = global_position.distance_to(target_wizard.global_position)
	if dist > 120:
		var dir = (target_wizard.global_position - global_position).normalized()
		velocity = dir * chase_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

func _shoot_arrow():
	var arrow_script = load("res://scripts/Arrow.gd")
	var arrow = Area2D.new()
	arrow.set_script(arrow_script)
	arrow.global_position = global_position
	var dir = (target_wizard.global_position - global_position).normalized()
	arrow.direction = dir
	arrow.speed = arrow_speed
	get_tree().current_scene.add_child(arrow)
