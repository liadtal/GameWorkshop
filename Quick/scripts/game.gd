extends Node2D
## Game — root scene. Manages grid, player, overlays, and game state.
## Loads levels from JSON via LevelLoader. Advances on completion.

const LevelLoader := preload("res://scripts/level_loader.gd")

@onready var grid: Node2D = $Grid
@onready var player: Node2D = $Player
@onready var key_inventory: Control = $HUDLayer/KeyInventory
@onready var level_title: Label = $HUDLayer/LevelTitle
@onready var difficulty_label: Label = $HUDLayer/DifficultyLabel

# Overlays
@onready var death_overlay: ColorRect = $OverlayLayer/DeathOverlay
@onready var win_overlay: ColorRect = $OverlayLayer/WinOverlay
@onready var pause_overlay: ColorRect = $OverlayLayer/PauseOverlay

var level_index: int = 1
var level_data: Dictionary = {}
var total_levels: int = 0
var is_paused: bool = false

func _ready() -> void:
	level_index = SaveData.current_level_index
	if SaveData.game_mode == "tutorial":
		total_levels = LevelLoader.count_tutorials()
	else:
		total_levels = LevelLoader.count_levels()
	# Defer to next frame so viewport size is finalized
	call_deferred("_load_and_start_level")

func _load_and_start_level() -> void:
	var path: String
	if SaveData.game_mode == "tutorial":
		path = LevelLoader.tutorial_path(level_index)
	else:
		path = LevelLoader.level_path(level_index)
	level_data = LevelLoader.load_level(path)

	if level_data.is_empty():
		push_error("Game: failed to load level %d" % level_index)
		return

	# Load grid
	grid.load_level_data(level_data)

	# Apply difficulty speed and mode to player
	player.speed = SaveData.get_speed()
	player.kids_mode = SaveData.difficulty == "Kid's Mode"

	# Update HUD
	if SaveData.game_mode == "tutorial":
		level_title.text = "Tutorial: %s" % level_data["name"]
	else:
		level_title.text = level_data["name"]
	difficulty_label.text = SaveData.difficulty
	key_inventory.clear_keys()

	# Hide all overlays
	death_overlay.visible = false
	win_overlay.visible = false
	pause_overlay.visible = false

	# Place Quicky at the Start tile
	var start_pos: Vector2i = grid.find_tile(grid.Tile.START)
	player.position = grid.position + grid.grid_to_pixel(start_pos.x, start_pos.y)
	player.init_grid_pos(start_pos.x, start_pos.y, grid)

	# Connect signals (safe — skip if already connected)
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if not player.reached_exit.is_connected(_on_player_reached_exit):
		player.reached_exit.connect(_on_player_reached_exit)
	if not player.key_picked_up.is_connected(_on_key_picked_up):
		player.key_picked_up.connect(_on_key_picked_up)
	if not player.key_used.is_connected(_on_key_used):
		player.key_used.connect(_on_key_used)
	if not player.started_moving.is_connected(_on_player_started):
		player.started_moving.connect(_on_player_started)

	print("Quick — Level %d loaded: %s (%s)" % [level_index, level_data["name"], SaveData.difficulty])

# --- Signal handlers ---

func _on_player_started() -> void:
	pass

func _on_player_died() -> void:
	death_overlay.visible = true
	death_overlay.get_node("VBox/RestartBtn").grab_focus()

func _on_player_reached_exit() -> void:
	# Only track progress for real levels
	if SaveData.game_mode != "tutorial":
		SaveData.complete_level(level_index)
	# Determine if a valid "next level" exists
	var has_next := level_index < total_levels and SaveData.game_mode != "select"
	var next_btn: Button = win_overlay.get_node("VBox/NextLevelBtn")
	next_btn.visible = has_next
	win_overlay.visible = true
	# Focus appropriate button
	if has_next:
		next_btn.grab_focus()
	else:
		win_overlay.get_node("VBox/MenuBtn").grab_focus()

func _on_key_picked_up(color_name: String) -> void:
	key_inventory.add_key(color_name)

func _on_key_used(color_name: String) -> void:
	key_inventory.remove_key(color_name)

# --- Overlay button callbacks (connected via .tscn signals) ---

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_next_level() -> void:
	if level_index < total_levels:
		level_index += 1
		SaveData.current_level_index = level_index
		get_tree().reload_current_scene()

func _on_back_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_resume() -> void:
	_toggle_pause()

# --- Input ---

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return

	# Restart on R (works from death overlay too)
	if Input.is_action_just_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()
		return

	# Pause / unpause on Escape
	if event.keycode == KEY_ESCAPE:
		if death_overlay.visible or win_overlay.visible:
			# From end-state, go to menu
			_on_back_to_menu()
		else:
			_toggle_pause()
		return

	# Next level on Enter after winning
	if event.keycode == KEY_ENTER and win_overlay.visible:
		_on_next_level()

func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_overlay.visible = is_paused
	if is_paused:
		pause_overlay.get_node("VBox/ResumeBtn").grab_focus()
