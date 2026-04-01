extends Node2D

## Generic level loader — reads a JSON file and builds the dungeon.

var wizard_scene = preload("res://scenes/Wizard.tscn")
var goblin_scene = preload("res://scenes/Goblin.tscn")
var runner_scene = preload("res://scenes/RunnerGoblin.tscn")
var bowman_scene = preload("res://scenes/BowmanGoblin.tscn")
var fat_scene = preload("res://scenes/FatGoblin.tscn")
var door_scene = preload("res://scenes/Door.tscn")

const WALL_THICKNESS = 8.0
const WALL_COLOR = Color(0.35, 0.35, 0.4)
const FLOOR_COLOR = Color(0.12, 0.1, 0.16)

var level_width: int = 1024
var level_height: int = 600

func load_level(json_path: String) -> void:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("Could not open level file: " + json_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		push_error("JSON parse error in " + json_path + ": " + json.get_error_message())
		return
	
	var data: Dictionary = json.data
	_build_from_data(data)

func _build_from_data(data: Dictionary) -> void:
	level_width = data.get("width", 1024)
	level_height = data.get("height", 600)
	
	_draw_floor()
	_build_boundary_walls()
	
	# Internal walls
	var walls: Array = data.get("walls", [])
	for wall_data in walls:
		var center = Vector2(wall_data["x"], wall_data["y"])
		var size = Vector2(wall_data["w"], wall_data["h"])
		_add_wall(center, size)
	
	# Door
	var door_data: Dictionary = data.get("door", {"x": 920, "y": 500})
	var door = door_scene.instantiate()
	door.name = "Door"
	door.position = Vector2(door_data["x"], door_data["y"])
	add_child(door)
	
	# Wizard
	var wizard_data: Dictionary = data.get("wizard", {"x": 100, "y": 100})
	var wizard = wizard_scene.instantiate()
	wizard.name = "Wizard"
	wizard.position = Vector2(wizard_data["x"], wizard_data["y"])
	add_child(wizard)
	
	# Enemies
	var enemies: Array = data.get("enemies", [])
	for i in range(enemies.size()):
		var enemy_data = enemies[i]
		var enemy_type: String = enemy_data.get("type", "goblin")
		var enemy: CharacterBody2D
		match enemy_type:
			"runner":
				enemy = runner_scene.instantiate()
				enemy.name = "RunnerGoblin" + str(i + 1)
			"bowman":
				enemy = bowman_scene.instantiate()
				enemy.name = "BowmanGoblin" + str(i + 1)
			"fat":
				enemy = fat_scene.instantiate()
				enemy.name = "FatGoblin" + str(i + 1)
			_:
				enemy = goblin_scene.instantiate()
				enemy.name = "Goblin" + str(i + 1)
		enemy.position = Vector2(enemy_data["x"], enemy_data["y"])
		add_child(enemy)
	
	# HUD
	var hud_script = load("res://scripts/HUD.gd")
	var hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(hud_script)
	add_child(hud)

# ---- Floor ----
func _draw_floor():
	var floor_rect = ColorRect.new()
	floor_rect.color = FLOOR_COLOR
	floor_rect.position = Vector2.ZERO
	floor_rect.size = Vector2(level_width, level_height)
	floor_rect.z_index = -10
	add_child(floor_rect)

# ---- Boundary walls ----
func _build_boundary_walls():
	_add_wall(Vector2(level_width / 2, 0), Vector2(level_width, WALL_THICKNESS))                # Top
	_add_wall(Vector2(level_width / 2, level_height), Vector2(level_width, WALL_THICKNESS))      # Bottom
	_add_wall(Vector2(0, level_height / 2), Vector2(WALL_THICKNESS, level_height))               # Left
	_add_wall(Vector2(level_width, level_height / 2), Vector2(WALL_THICKNESS, level_height))     # Right

# ---- Add a single wall ----
func _add_wall(center: Vector2, size: Vector2):
	var wall = StaticBody2D.new()
	wall.position = center
	wall.collision_layer = 1  # Walls layer
	wall.collision_mask = 0
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	
	# Visual representation
	var visual = Polygon2D.new()
	var half = size / 2
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])
	visual.color = WALL_COLOR
	wall.add_child(visual)
	
	add_child(wall)
