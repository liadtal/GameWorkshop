extends Control


func _ready():
	$CenterContainer/VBoxContainer/ScoreLabel.text = "Final Score:  " + str(GameState.final_score)
	$CenterContainer/VBoxContainer/PlayAgainButton.pressed.connect(_on_play_again_pressed)
	$CenterContainer/VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _on_play_again_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_quit_pressed():
	get_tree().quit()
