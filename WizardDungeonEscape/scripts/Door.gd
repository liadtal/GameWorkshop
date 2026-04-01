extends Area2D

func _ready():
	# Door is on layer 4 (bit 3 = 8), detects Player layer 2 (bit 1 = 2)
	collision_layer = 8  # Layer 4
	collision_mask = 2   # Player
	
	_create_visuals()
	
	body_entered.connect(_on_body_entered)

func _create_visuals():
	# Door frame (brown rectangle)
	var door_frame = Polygon2D.new()
	door_frame.polygon = PackedVector2Array([
		Vector2(-16, -22),
		Vector2(16, -22),
		Vector2(16, 22),
		Vector2(-16, 22)
	])
	door_frame.color = Color(0.45, 0.25, 0.1)  # Dark brown
	add_child(door_frame)
	
	# Door panel (lighter brown)
	var door_panel = Polygon2D.new()
	door_panel.polygon = PackedVector2Array([
		Vector2(-13, -19),
		Vector2(13, -19),
		Vector2(13, 19),
		Vector2(-13, 19)
	])
	door_panel.color = Color(0.6, 0.35, 0.15)  # Medium brown
	add_child(door_panel)
	
	# Door handle (small circle)
	var handle = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(8):
		var angle = i * TAU / 8
		points.append(Vector2(8 + cos(angle) * 3, sin(angle) * 3))
	handle.polygon = points
	handle.color = Color(0.85, 0.7, 0.2)  # Golden
	add_child(handle)

func _on_body_entered(body: Node2D):
	if body.collision_layer & 2:  # Player layer
		GameState.level_complete.emit()
