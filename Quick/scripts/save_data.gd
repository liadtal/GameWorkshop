extends Node
## SaveData — autoload singleton that persists level completion and settings.
## Uses Godot's ConfigFile for simple key-value storage.

const SAVE_PATH := "user://save_data.cfg"

# Difficulty presets: name → speed in px/sec
const DIFFICULTY_SPEEDS := {
	"Kid's Mode": 96.0,
	"Easy": 96.0,
	"Medium": 192.0,
	"Hard": 288.0,
}
const DIFFICULTY_NAMES := ["Kid's Mode", "Easy", "Medium", "Hard"]

var _config := ConfigFile.new()

## Highest unlocked real level (1-based). Level 1 is always unlocked.
var highest_unlocked: int = 1

## Which level to play next (set before switching to game scene).
var current_level_index: int = 1

## Game mode: "play", "tutorial", or "select".
var game_mode: String = "play"

## Current difficulty name.
var difficulty: String = "Easy"

func _ready() -> void:
	_load()

func _load() -> void:
	var err := _config.load(SAVE_PATH)
	if err == OK:
		highest_unlocked = _config.get_value("progress", "highest_unlocked", 1)
		difficulty = _config.get_value("settings", "difficulty", "Easy")
	else:
		highest_unlocked = 1
		difficulty = "Easy"

func save() -> void:
	_config.set_value("progress", "highest_unlocked", highest_unlocked)
	_config.set_value("settings", "difficulty", difficulty)
	_config.save(SAVE_PATH)

## Get the speed in px/sec for the current difficulty.
func get_speed() -> float:
	return DIFFICULTY_SPEEDS.get(difficulty, 192.0)

## Mark a level as completed; unlock the next one.
func complete_level(index: int) -> void:
	if index >= highest_unlocked:
		highest_unlocked = index + 1
		save()

## Check if a level is unlocked.
func is_unlocked(index: int) -> bool:
	return index <= highest_unlocked

## Set difficulty and persist.
func set_difficulty(name: String) -> void:
	if name in DIFFICULTY_NAMES:
		difficulty = name
		save()
