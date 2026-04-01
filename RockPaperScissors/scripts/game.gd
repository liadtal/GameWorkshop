extends Control

enum Choice { ROCK, PAPER, SCISSORS }

var lives: int = 3
var score: int = 0
var round_active: bool = true

@onready var lives_label: Label = $CenterContainer/VBoxContainer/LivesLabel
@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var instruction_label: Label = $CenterContainer/VBoxContainer/InstructionLabel
@onready var rock_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/RockButton
@onready var paper_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/PaperButton
@onready var scissors_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/ScissorsButton
@onready var player_choice_label: Label = $CenterContainer/VBoxContainer/PlayerChoiceLabel
@onready var computer_choice_label: Label = $CenterContainer/VBoxContainer/ComputerChoiceLabel
@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var next_button: Button = $CenterContainer/VBoxContainer/NextButton


func _ready():
	rock_button.pressed.connect(_on_rock_pressed)
	paper_button.pressed.connect(_on_paper_pressed)
	scissors_button.pressed.connect(_on_scissors_pressed)
	next_button.pressed.connect(_on_next_pressed)
	next_button.visible = false
	_clear_result()
	_update_ui()


func _update_ui():
	var hearts := ""
	for i in range(lives):
		hearts += "❤ "
	for i in range(3 - lives):
		hearts += "🖤 "
	lives_label.text = hearts.strip_edges()
	score_label.text = "Score: " + str(score)


func _clear_result():
	player_choice_label.text = ""
	computer_choice_label.text = ""
	result_label.text = ""


func _choice_to_string(choice: Choice) -> String:
	match choice:
		Choice.ROCK:
			return "ROCK"
		Choice.PAPER:
			return "PAPER"
		Choice.SCISSORS:
			return "SCISSORS"
	return ""


func _get_computer_choice() -> Choice:
	return (randi() % 3) as Choice


func _determine_result(player: Choice, computer: Choice) -> String:
	if player == computer:
		return "draw"
	if (player == Choice.ROCK and computer == Choice.SCISSORS) or \
	   (player == Choice.PAPER and computer == Choice.ROCK) or \
	   (player == Choice.SCISSORS and computer == Choice.PAPER):
		return "win"
	return "lose"


func _play_round(choice: Choice):
	if not round_active:
		return

	round_active = false
	var computer_choice := _get_computer_choice()

	player_choice_label.text = "You chose:  " + _choice_to_string(choice)
	computer_choice_label.text = "Computer chose:  " + _choice_to_string(computer_choice)

	var result := _determine_result(choice, computer_choice)

	match result:
		"win":
			result_label.text = "✅  You WIN this round!"
			result_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))
			score += 1
		"lose":
			result_label.text = "💀  You LOSE this round!"
			result_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
			lives -= 1
		"draw":
			result_label.text = "🤝  It's a DRAW!"
			result_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))

	_update_ui()
	_set_buttons_disabled(true)

	if lives <= 0:
		instruction_label.text = "You have fallen..."
		GameState.final_score = score
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
	else:
		next_button.visible = true


func _set_buttons_disabled(disabled: bool):
	rock_button.disabled = disabled
	paper_button.disabled = disabled
	scissors_button.disabled = disabled


func _on_rock_pressed():
	_play_round(Choice.ROCK)


func _on_paper_pressed():
	_play_round(Choice.PAPER)


func _on_scissors_pressed():
	_play_round(Choice.SCISSORS)


func _on_next_pressed():
	round_active = true
	next_button.visible = false
	_clear_result()
	_set_buttons_disabled(false)
	instruction_label.text = "Choose your weapon:"
