extends CharacterBody2D

@export var speed: float = 150.0

var facing_direction: Vector2 = Vector2.RIGHT
var is_invincible: bool = false
var is_phase_walking: bool = false
var phase_timer: float = 0.0
const PHASE_DURATION: float = 5.0
const INVINCIBILITY_DURATION: float = 1.0
var invincibility_timer: float = 0.0

# Visual nodes — created in _ready
var body_sprite: Polygon2D
var hat_sprite: Polygon2D
var direction_arrow: Polygon2D
var phase_overlay: Polygon2D

func _ready():
	add_to_group("wizard")
	# Build the wizard visually using simple shapes
	_create_visuals()
	
	# Set collision: layer 2 (Player), mask layer 1 (Walls)
	# Enemies detected via Area2D hitbox, Door is Area2D (auto-detects)
	collision_layer = 2  # Player layer (bit 1)
	collision_mask = 1  # Walls only — enemies detected via Area2D hitbox
	
	# Add hitbox Area2D for enemy contact detection
	var hitbox = Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 2
	hitbox.collision_mask = 4  # Enemies
	var hitbox_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 14.0
	hitbox_shape.shape = circle
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)
	hitbox.body_entered.connect(_on_enemy_contact)

func _create_visuals():
	# Body circle (blue robe)
	body_sprite = Polygon2D.new()
	var body_points: PackedVector2Array = PackedVector2Array()
	for i in range(16):
		var angle = i * TAU / 16
		body_points.append(Vector2(cos(angle), sin(angle)) * 14)
	body_sprite.polygon = body_points
	body_sprite.color = Color(0.42, 0.36, 0.9)  # Purple-blue
	add_child(body_sprite)
	
	# Hat (triangle on top)
	hat_sprite = Polygon2D.new()
	hat_sprite.polygon = PackedVector2Array([
		Vector2(-10, -8),
		Vector2(10, -8),
		Vector2(0, -26)
	])
	hat_sprite.color = Color(0.25, 0.2, 0.7)  # Darker blue
	add_child(hat_sprite)
	
	# Direction arrow
	direction_arrow = Polygon2D.new()
	direction_arrow.polygon = PackedVector2Array([
		Vector2(16, 0),
		Vector2(10, -5),
		Vector2(10, 5)
	])
	direction_arrow.color = Color(1, 1, 0.3)  # Yellow
	add_child(direction_arrow)
	
	# Phase walk overlay (semi-transparent)
	phase_overlay = Polygon2D.new()
	var overlay_points: PackedVector2Array = PackedVector2Array()
	for i in range(16):
		var angle = i * TAU / 16
		overlay_points.append(Vector2(cos(angle), sin(angle)) * 18)
	phase_overlay.polygon = overlay_points
	phase_overlay.color = Color(0.5, 0.8, 1.0, 0.3)
	phase_overlay.visible = false
	add_child(phase_overlay)

func _physics_process(delta: float):
	# Handle movement input
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		facing_direction = input_dir
		_update_direction_arrow()
	
	velocity = input_dir * speed
	move_and_slide()
	
	# Handle invincibility timer
	if is_invincible:
		invincibility_timer -= delta
		# Blink effect
		modulate.a = 0.5 if fmod(invincibility_timer, 0.2) < 0.1 else 1.0
		if invincibility_timer <= 0:
			is_invincible = false
			modulate.a = 1.0
	
	# Handle phase walk timer
	if is_phase_walking:
		phase_timer -= delta
		if phase_timer <= 0:
			_end_phase_walk()
	
	# Handle spell inputs
	if Input.is_action_just_pressed("spell_1"):
		_cast_line_blast()
	if Input.is_action_just_pressed("spell_2"):
		_cast_smite()
	if Input.is_action_just_pressed("spell_3"):
		_cast_phase_walk()

func _update_direction_arrow():
	direction_arrow.rotation = facing_direction.angle()

func _cast_line_blast():
	if not GameState.use_spell(0):
		return
	
	# Create a raycast in the facing direction
	var space_state = get_world_2d().direct_space_state
	var max_distance = 2000.0
	var end_pos = global_position + facing_direction * max_distance
	
	# First find where the ray hits a wall to know the beam endpoint
	var wall_query = PhysicsRayQueryParameters2D.create(global_position, end_pos, 1)  # Walls only
	wall_query.exclude = [get_rid()]
	var wall_result = space_state.intersect_ray(wall_query)
	
	var beam_end = end_pos
	if wall_result:
		beam_end = wall_result.position
	
	# Now find all enemies along this line
	# We'll do multiple raycasts, removing hit enemies each time
	var killed_enemies: Array = []
	var current_start = global_position
	
	for i in range(20):  # Safety limit
		var enemy_query = PhysicsRayQueryParameters2D.create(current_start, beam_end, 4)  # Enemies only (layer 3 = bit 2 = 4)
		enemy_query.exclude = [get_rid()]
		for enemy in killed_enemies:
			if is_instance_valid(enemy):
				enemy_query.exclude.append(enemy.get_rid())
		
		var result = space_state.intersect_ray(enemy_query)
		if result and result.collider.has_method("die"):
			killed_enemies.append(result.collider)
			result.collider.die()
		else:
			break
	
	# Visual beam effect
	_show_beam(global_position, beam_end)

func _show_beam(from: Vector2, to: Vector2):
	var beam = Line2D.new()
	beam.add_point(from)
	beam.add_point(to)
	beam.width = 4.0
	beam.default_color = Color(1, 1, 0.2, 0.9)
	beam.z_index = 10
	get_tree().current_scene.add_child(beam)
	
	# Fade out the beam
	var tween = get_tree().create_tween()
	tween.tween_property(beam, "modulate:a", 0.0, 0.3)
	tween.tween_callback(beam.queue_free)

func _cast_smite():
	var smite_cost = 2
	var smite_range = 180.0  # Same as goblin sight range
	
	if not GameState.use_spell(1, smite_cost):
		return
	
	# Find closest enemy within range
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		# Refund the mana since no valid target
		GameState.refund_spell(smite_cost)
		return
	
	var closest_enemy: Node2D = null
	var closest_dist: float = INF
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < smite_range and dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy
	
	if closest_enemy and closest_enemy.has_method("die"):
		_show_smite_effect(closest_enemy.global_position)
		closest_enemy.die()
	else:
		# No enemy in range — refund
		GameState.refund_spell(smite_cost)

func _show_smite_effect(pos: Vector2):
	# Lightning bolt effect (simple lines)
	var effect = Node2D.new()
	effect.global_position = pos
	effect.z_index = 10
	
	for i in range(4):
		var line = Line2D.new()
		var bolt_start = Vector2(randf_range(-20, 20), -40)
		var bolt_end = Vector2(randf_range(-5, 5), 0)
		line.add_point(bolt_start)
		line.add_point(Vector2(randf_range(-10, 10), -20))
		line.add_point(bolt_end)
		line.width = 2.0
		line.default_color = Color(0.8, 0.8, 1.0)
		effect.add_child(line)
	
	get_tree().current_scene.add_child(effect)
	
	var tween = get_tree().create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.4)
	tween.tween_callback(effect.queue_free)

func _cast_phase_walk():
	if is_phase_walking:
		return
	if not GameState.use_spell(2):
		return
	
	is_phase_walking = true
	GameState.is_phase_walking = true
	phase_timer = PHASE_DURATION
	
	# Disable wall collision (bit 0 = layer 1 = Walls)
	set_collision_mask_value(1, false)
	
	# Visual feedback
	phase_overlay.visible = true
	modulate.a = 0.6

func _end_phase_walk():
	is_phase_walking = false
	GameState.is_phase_walking = false
	phase_overlay.visible = false
	
	# Re-enable wall collision
	set_collision_mask_value(1, true)
	
	# Check if wizard is stuck in a wall
	if _is_in_wall():
		GameState.take_damage(1)
	
	if not is_invincible:
		modulate.a = 1.0

func _is_in_wall() -> bool:
	# Check if overlapping with any wall
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10.0
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1  # Walls only
	var results = space_state.intersect_shape(query)
	return results.size() > 0

func _on_enemy_contact(body: Node2D):
	if is_invincible:
		return
	if body.is_in_group("enemies"):
		GameState.take_damage(1)
		is_invincible = true
		invincibility_timer = INVINCIBILITY_DURATION

func get_phase_time_remaining() -> float:
	if is_phase_walking:
		return phase_timer
	return 0.0
