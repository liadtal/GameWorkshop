extends Node

# Game State Singleton (Autoload)

signal hp_changed(new_hp: int)
signal mana_changed(new_mana: int)
signal game_over
signal level_complete
signal enemy_killed

var hp: int = 2
var max_hp: int = 2
var mana: int = 10
var max_mana: int = 10
var is_phase_walking: bool = false

func reset():
	hp = max_hp
	mana = max_mana
	is_phase_walking = false

func take_damage(amount: int = 1) -> void:
	hp = max(0, hp - amount)
	hp_changed.emit(hp)
	if hp <= 0:
		game_over.emit()

func use_spell(_index: int, cost: int = 1) -> bool:
	if mana < cost:
		return false
	mana -= cost
	mana_changed.emit(mana)
	return true

func refund_spell(cost: int = 1) -> void:
	mana = min(mana + cost, max_mana)
	mana_changed.emit(mana)
