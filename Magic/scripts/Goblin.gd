extends GoblinBase

## Standard Goblin — default stats, basic green goblin visuals.

func _create_visuals() -> void:
	_draw_body(12, Color(0.2, 0.75, 0.2))
	_draw_ears(Color(0.25, 0.8, 0.25))
	_draw_eyes(Color(1.0, 0.2, 0.2))
