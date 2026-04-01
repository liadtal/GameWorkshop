extends Control
## MainMenu — title screen with Play, Tutorial, Level Select, Difficulty, and Quit buttons.

const LevelLoader := preload("res://scripts/level_loader.gd")

@onready var difficulty_label: Label = $VBoxContainer/DifficultyRow/DifficultyLabel

func _ready() -> void:
	_update_difficulty_label()
	# Give focus to Play button for keyboard navigation
	$VBoxContainer/PlayButton.grab_focus()

func _on_play_pressed() -> void:
	var total := LevelLoader.count_levels()
	SaveData.current_level_index = mini(SaveData.highest_unlocked, total)
	SaveData.game_mode = "play"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_tutorial_pressed() -> void:
	SaveData.current_level_index = 1
	SaveData.game_mode = "tutorial"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_level_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_difficulty_pressed() -> void:
	# Cycle through difficulties
	var names: Array = SaveData.DIFFICULTY_NAMES
	var idx := names.find(SaveData.difficulty)
	idx = (idx + 1) % names.size()
	SaveData.set_difficulty(names[idx])
	_update_difficulty_label()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _update_difficulty_label() -> void:
	difficulty_label.text = SaveData.difficulty
	# Color based on difficulty
	match SaveData.difficulty:
		"Kid's Mode":
			difficulty_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		"Easy":
			difficulty_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
		"Medium":
			difficulty_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.2))
		"Hard":
			difficulty_label.add_theme_color_override("font_color", Color(0.9, 0.25, 0.2))
