extends CharacterBody2D
class_name GoblinBase

## Base class for all goblin enemy types.
## Subclasses override _create_visuals() and optionally _on_chase_behavior() / die().

@export var speed: float = 60.0
@export var chase_speed: float = 90.0
@export var sight_range: float = 180.0
@export var hp: int = 1
@export var death_particle_count: int = 6
@export var death_particle_size: float = 3.0
@export var death_spread: float = 30.0
@export var death_color: Color = Color(0.2, 0.9, 0.2, 0.8)

var move_direction: Vector2 = Vector2.ZERO
var move_timer: float = 0.0
var pause_timer: float = 0.0
var is_paused: bool = false
var is_chasing: bool = false
var target_wizard: CharacterBody2D = null
var alert_indicator: Polygon2D

# Wander pause duration range — can be overridden by subclass
var wander_pause_min: float = 0.3
var wander_pause_max: float = 1.0
var wander_move_min: float = 1.0
var wander_move_max: float = 3.0

func _ready():
	add_to_group("enemies")
	collision_layer = 4   # Layer 3 (Enemies)
	collision_mask = 1 | 2  # Walls + Player
	_create_visuals()
	_add_alert_indicator()
	_pick_new_direction()

# ---- Visuals (override in subclass) ----

func _create_visuals() -> void:
	# Default goblin look — subclasses override this entirely
	_draw_body(12, Color(0.2, 0.75, 0.2))
	_draw_ears(Color(0.25, 0.8, 0.25))
	_draw_eyes(Color(1.0, 0.2, 0.2))

func _draw_body(radius: float, color: Color) -> void:
	var body = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	var segments = 12 if radius <= 14 else 16
	for i in range(segments):
		var angle = i * TAU / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	body.polygon = points
	body.color = color
	add_child(body)

func _draw_ears(color: Color, scale_factor: float = 1.0) -> void:
	var s = scale_factor
	var left_ear = Polygon2D.new()
	left_ear.polygon = PackedVector2Array([
		Vector2(-10 * s, -6 * s), Vector2(-18 * s, -14 * s), Vector2(-6 * s, -10 * s)
	])
	left_ear.color = color
	add_child(left_ear)
	var right_ear = Polygon2D.new()
	right_ear.polygon = PackedVector2Array([
		Vector2(10 * s, -6 * s), Vector2(18 * s, -14 * s), Vector2(6 * s, -10 * s)
	])
	right_ear.color = color
	add_child(right_ear)

func _draw_eyes(color: Color, offset_x: float = 4.0, offset_y: float = -3.0, radius: float = 2.5) -> void:
	for ox in [-offset_x, offset_x]:
		var eye = Polygon2D.new()
		var pts: PackedVector2Array = PackedVector2Array()
		for i in range(8):
			var a = i * TAU / 8
			pts.append(Vector2(ox + cos(a) * radius, offset_y + sin(a) * radius))
		eye.polygon = pts
		eye.color = color
		add_child(eye)

func _add_alert_indicator() -> void:
	alert_indicator = Polygon2D.new()
	alert_indicator.polygon = PackedVector2Array([
		Vector2(-2, -24), Vector2(2, -24), Vector2(1, -32), Vector2(-1, -32)
	])
	alert_indicator.color = Color(1.0, 0.3, 0.1)
	alert_indicator.visible = false
	add_child(alert_indicator)

# ---- AI ----

func _physics_process(delta: float):
	if not is_instance_valid(target_wizard):
		var wizards = get_tree().get_nodes_in_group("wizard")
		if wizards.size() > 0:
			target_wizard = wizards[0]

	var can_see = _can_see_wizard()

	if can_see:
		is_chasing = true
		is_paused = false
		alert_indicator.visible = true
		_on_see_wizard(delta)
	elif is_chasing:
		is_chasing = false
		alert_indicator.visible = false
		_pick_new_direction()

	if is_chasing and is_instance_valid(target_wizard):
		_chase_behavior(delta)
	else:
		_wander_behavior(delta)

## Called every frame while the wizard is visible. Override for shooting, etc.
func _on_see_wizard(_delta: float) -> void:
	pass

## Chase movement. Override to change chase behavior (e.g., keep distance).
func _chase_behavior(_delta: float) -> void:
	var dir = (target_wizard.global_position - global_position).normalized()
	velocity = dir * chase_speed
	move_and_slide()

## Wander movement when not chasing.
func _wander_behavior(delta: float) -> void:
	if is_paused:
		pause_timer -= delta
		if pause_timer <= 0:
			is_paused = false
			_pick_new_direction()
		return

	move_timer -= delta
	if move_timer <= 0:
		is_paused = true
		pause_timer = randf_range(wander_pause_min, wander_pause_max)
		velocity = Vector2.ZERO
		return

	velocity = move_direction * speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		_pick_new_direction()

func _can_see_wizard() -> bool:
	if not is_instance_valid(target_wizard):
		return false
	if global_position.distance_to(target_wizard.global_position) > sight_range:
		return false
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target_wizard.global_position, 1)
	query.exclude = [get_rid()]
	return space_state.intersect_ray(query).is_empty()

func _pick_new_direction():
	var angle = randf() * TAU
	move_direction = Vector2(cos(angle), sin(angle)).normalized()
	move_timer = randf_range(wander_move_min, wander_move_max)

# ---- Death ----

func die():
	hp -= 1
	if hp > 0:
		# Flash red to show damage
		modulate = Color(1, 0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)
		return
	var effect = _create_death_effect()
	get_tree().current_scene.add_child(effect)
	GameState.enemy_killed.emit()
	queue_free()

func _create_death_effect() -> Node2D:
	var effect = Node2D.new()
	effect.global_position = global_position
	effect.z_index = 10
	for i in range(death_particle_count):
		var particle = Polygon2D.new()
		var pts: PackedVector2Array = PackedVector2Array()
		for j in range(6):
			var a = j * TAU / 6
			pts.append(Vector2(cos(a), sin(a)) * death_particle_size)
		particle.polygon = pts
		particle.color = death_color
		particle.position = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		effect.add_child(particle)
		var tween = effect.create_tween()
		tween.tween_property(particle, "position", Vector2(randf_range(-death_spread, death_spread), randf_range(-death_spread, death_spread)), 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
	var cleanup = effect.create_tween()
	cleanup.tween_interval(0.6)
	cleanup.tween_callback(effect.queue_free)
	return effect
