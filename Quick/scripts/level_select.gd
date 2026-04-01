extends Control
## LevelSelect — grid of buttons showing completed real levels for replay.

const LevelLoader := preload("res://scripts/level_loader.gd")

@onready var grid_container: GridContainer = $VBoxContainer/GridContainer
@onready var title_label: Label = $VBoxContainer/TitleLabel

const BUTTON_SIZE := Vector2(180, 50)

func _ready() -> void:
	var total := LevelLoader.count_levels()
	for i in range(1, total + 1):
		var level_data := LevelLoader.load_level(LevelLoader.level_path(i))
		var level_name: String = level_data.get("name", "Level %d" % i)
		var btn := Button.new()
		btn.custom_minimum_size = BUTTON_SIZE
		var unlocked := SaveData.is_unlocked(i)
		if unlocked:
			btn.text = level_name
			btn.pressed.connect(_on_level_pressed.bind(i))
			btn.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
		else:
			btn.text = "🔒 %s" % level_name
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		grid_container.add_child(btn)

	# Focus the first button for keyboard navigation
	var first_focus: Button = null
	for child in grid_container.get_children():
		if child is Button:
			first_focus = child
			break
	if first_focus:
		first_focus.call_deferred("grab_focus")

func _on_level_pressed(index: int) -> void:
	SaveData.current_level_index = index
	SaveData.game_mode = "select"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
