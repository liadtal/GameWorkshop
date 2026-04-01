extends Area2D

## Arrow projectile — shot by Bowman Goblin, damages wizard on contact, destroyed by walls.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var lifetime: float = 4.0

func _ready():
	# Arrow is on enemy layer, detects player and walls
	collision_layer = 4  # Enemies layer
	collision_mask = 1 | 2  # Walls + Player

	var shape = CollisionShape2D.new()
	var capsule = RectangleShape2D.new()
	capsule.size = Vector2(12, 4)
	shape.shape = capsule
	shape.rotation = direction.angle()
	add_child(shape)

	_create_visuals()

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _create_visuals():
	# Arrow shaft
	var shaft = Line2D.new()
	shaft.add_point(Vector2(-8, 0))
	shaft.add_point(Vector2(8, 0))
	shaft.width = 2.0
	shaft.default_color = Color(0.55, 0.35, 0.1)
	shaft.rotation = direction.angle()
	add_child(shaft)

	# Arrow head
	var head = Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(8, 0),
		Vector2(5, -3),
		Vector2(5, 3)
	])
	head.color = Color(0.7, 0.7, 0.7)
	head.rotation = direction.angle()
	add_child(head)

func _physics_process(delta: float):
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

	# Check for wall collision via raycast
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * speed * delta,
		1  # Walls only
	)
	var result = space_state.intersect_ray(query)
	if result:
		queue_free()

func _on_body_entered(body: Node2D):
	if body.is_in_group("wizard"):
		if not body.is_invincible:
			GameState.take_damage(1)
			body.is_invincible = true
			body.invincibility_timer = body.INVINCIBILITY_DURATION
		queue_free()

func _on_area_entered(_area: Area2D):
	pass  # Could handle shield interactions etc.
