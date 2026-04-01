extends Node2D

## Main game manager — handles title screen, level loading, game over / win states.

enum GameScreen { TITLE, LEVEL_SELECT, GAMEPLAY, WIN, GAME_OVER }
var current_screen: GameScreen = GameScreen.TITLE

var level_scene: Node2D = null
var overlay: CanvasLayer
var overlay_label: Label
var sub_label: Label

# Level select UI
var level_select_container: VBoxContainer = null

# Level progression
var level_files: Array[String] = []
var level_names: Array[String] = []
var current_level_index: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep receiving input while paused
	_scan_levels()
	_create_overlay()
	_show_title_screen()
	
	GameState.game_over.connect(_on_game_over)
	GameState.level_complete.connect(_on_level_complete)

func _scan_levels():
	# Find all level JSON files in res://levels/ sorted by name
	level_files.clear()
	level_names.clear()
	var dir = DirAccess.open("res://levels")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var path = "res://levels/" + file_name
				level_files.append(path)
				# Read the level name from JSON
				var f = FileAccess.open(path, FileAccess.READ)
				if f:
					var json = JSON.new()
					json.parse(f.get_as_text())
					f.close()
					var data: Dictionary = json.data if json.data else {}
					level_names.append(data.get("name", file_name))
				else:
					level_names.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	level_files.sort()
	level_names.sort()  # Will be re-synced below
	# Re-sync names to sorted files
	level_names.clear()
	for path in level_files:
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var json = JSON.new()
			json.parse(f.get_as_text())
			f.close()
			var data: Dictionary = json.data if json.data else {}
			level_names.append(data.get("name", path.get_file()))
		else:
			level_names.append(path.get_file())
	print("Found levels: ", level_files)

func _create_overlay():
	overlay = CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	
	var panel = ColorRect.new()
	panel.name = "Panel"
	panel.color = Color(0, 0, 0, 0.75)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)
	
	overlay_label = Label.new()
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.add_theme_font_size_override("font_size", 48)
	overlay_label.add_theme_color_override("font_color", Color(0.9, 0.85, 1.0))
	vbox.add_child(overlay_label)
	
	sub_label = Label.new()
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 22)
	sub_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	vbox.add_child(sub_label)
	
	# Level select container (hidden by default)
	level_select_container = VBoxContainer.new()
	level_select_container.alignment = BoxContainer.ALIGNMENT_CENTER
	level_select_container.visible = false
	vbox.add_child(level_select_container)

func _show_title_screen():
	current_screen = GameScreen.TITLE
	overlay.visible = true
	overlay_label.text = "Wizard Dungeon Escape"
	sub_label.text = "\nPress ENTER to Start\nPress L for Level Select"
	level_select_container.visible = false
	
	if level_scene:
		level_scene.queue_free()
		level_scene = null

func _show_level_select():
	current_screen = GameScreen.LEVEL_SELECT
	overlay.visible = true
	overlay_label.text = "Select Level"
	sub_label.text = ""
	level_select_container.visible = true
	
	# Clear and rebuild level buttons
	for child in level_select_container.get_children():
		child.queue_free()
	
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 10)
	level_select_container.add_child(spacer_top)
	
	for i in range(level_files.size()):
		var btn = Button.new()
		btn.text = str(i + 1) + ". " + level_names[i]
		btn.add_theme_font_size_override("font_size", 20)
		btn.custom_minimum_size = Vector2(300, 40)
		btn.pressed.connect(_on_level_button_pressed.bind(i))
		level_select_container.add_child(btn)
	
	var spacer_mid = Control.new()
	spacer_mid.custom_minimum_size = Vector2(0, 10)
	level_select_container.add_child(spacer_mid)
	
	var back_label = Label.new()
	back_label.text = "Press ESC to go back"
	back_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_label.add_theme_font_size_override("font_size", 18)
	back_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	level_select_container.add_child(back_label)

func _on_level_button_pressed(index: int):
	GameState.reset()
	current_level_index = index
	level_select_container.visible = false
	_load_current_level()

func _start_game():
	GameState.reset()
	current_level_index = 0
	_load_current_level()

func _load_current_level():
	GameState.mana = GameState.max_mana
	GameState.mana_changed.emit(GameState.mana)
	current_screen = GameScreen.GAMEPLAY
	overlay.visible = false
	
	if level_scene:
		level_scene.queue_free()
		level_scene = null
	
	# Create level node and use LevelLoader to build it from JSON
	var loader_script = load("res://scripts/LevelLoader.gd")
	level_scene = Node2D.new()
	level_scene.set_script(loader_script)
	add_child(level_scene)
	level_scene.load_level(level_files[current_level_index])
	
	# Connect HUD wizard reference
	var hud = level_scene.get_node_or_null("HUD")
	var wizard = level_scene.get_node_or_null("Wizard")
	if hud and wizard:
		hud.wizard = wizard

func _on_game_over():
	current_screen = GameScreen.GAME_OVER
	overlay.visible = true
	overlay_label.text = "Game Over"
	sub_label.text = "\nPress ENTER to Try Again"
	get_tree().paused = true

func _on_level_complete():
	# Check if there are more levels
	if current_level_index + 1 < level_files.size():
		current_screen = GameScreen.WIN
		overlay.visible = true
		overlay_label.text = "Level Complete!"
		sub_label.text = "\nPress ENTER for Next Level"
	else:
		current_screen = GameScreen.WIN
		overlay.visible = true
		overlay_label.text = "You Win!"
		sub_label.text = "\nAll levels cleared!\nPress ENTER to Play Again"
	get_tree().paused = true

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				match current_screen:
					GameScreen.TITLE:
						_start_game()
					GameScreen.GAME_OVER:
						get_tree().paused = false
						GameState.reset()
						_load_current_level()
					GameScreen.WIN:
						get_tree().paused = false
						if current_level_index + 1 < level_files.size():
							current_level_index += 1
							_load_current_level()
						else:
							if level_scene:
								level_scene.queue_free()
								level_scene = null
							_start_game()
			KEY_L:
				if current_screen == GameScreen.TITLE:
					_show_level_select()
			KEY_ESCAPE:
				if current_screen == GameScreen.LEVEL_SELECT:
					_show_title_screen()
