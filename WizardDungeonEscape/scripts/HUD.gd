extends CanvasLayer

var hp_label: Label
var mana_label: Label
var spell1_label: Label
var spell2_label: Label
var spell3_label: Label
var phase_bar: ProgressBar
var phase_container: HBoxContainer

@onready var wizard: CharacterBody2D = null

func _ready():
	layer = 10
	_create_hud()
	
	GameState.hp_changed.connect(_on_hp_changed)
	GameState.mana_changed.connect(_on_mana_changed)
	
	# Initial update
	call_deferred("_update_all")

func _create_hud():
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	
	# Top row: HP
	var top_row = HBoxContainer.new()
	vbox.add_child(top_row)
	
	hp_label = Label.new()
	hp_label.text = "HP: ♥♥"
	hp_label.add_theme_font_size_override("font_size", 22)
	hp_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	top_row.add_child(hp_label)
	
	var hp_spacer = Control.new()
	hp_spacer.custom_minimum_size = Vector2(30, 0)
	top_row.add_child(hp_spacer)
	
	mana_label = Label.new()
	mana_label.text = "Mana: 10/10"
	mana_label.add_theme_font_size_override("font_size", 22)
	mana_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
	top_row.add_child(mana_label)
	
	# Spacer to push spells to bottom
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Phase timer bar (shown when phase walking)
	phase_container = HBoxContainer.new()
	phase_container.visible = false
	vbox.add_child(phase_container)
	
	var phase_label = Label.new()
	phase_label.text = "Phase: "
	phase_label.add_theme_font_size_override("font_size", 16)
	phase_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	phase_container.add_child(phase_label)
	
	phase_bar = ProgressBar.new()
	phase_bar.custom_minimum_size = Vector2(200, 20)
	phase_bar.max_value = 5.0
	phase_bar.value = 5.0
	phase_bar.show_percentage = false
	phase_container.add_child(phase_bar)
	
	# Bottom row: Spell charges
	var bottom_row = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 30)
	vbox.add_child(bottom_row)
	
	spell1_label = _create_spell_label("[1] Line Blast", Color(1, 1, 0.3))
	bottom_row.add_child(spell1_label)
	
	spell2_label = _create_spell_label("[2] Smite", Color(0.8, 0.8, 1.0))
	bottom_row.add_child(spell2_label)
	
	spell3_label = _create_spell_label("[3] Phase Walk", Color(0.5, 0.8, 1.0))
	bottom_row.add_child(spell3_label)

func _create_spell_label(text: String, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	return label

func _process(_delta: float):
	# Update phase walk timer display
	if wizard and wizard.is_phase_walking:
		phase_container.visible = true
		phase_bar.value = wizard.get_phase_time_remaining()
	else:
		phase_container.visible = false

func _update_all():
	_on_hp_changed(GameState.hp)
	_on_mana_changed(GameState.mana)

func _on_hp_changed(new_hp: int):
	var hearts = ""
	for i in range(new_hp):
		hearts += "♥"
	for i in range(GameState.max_hp - new_hp):
		hearts += "♡"
	hp_label.text = "HP: " + hearts

func _on_mana_changed(new_mana: int):
	mana_label.text = "Mana: " + str(new_mana) + "/" + str(GameState.max_mana)
	if new_mana == 0:
		mana_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		mana_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
