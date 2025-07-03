extends TextureProgressBar

@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = 0xff2e50ff
@export var tertiary_color: Color = Color.DIM_GRAY

signal killed

func _ready() -> void:
	tint_over = secondary_color
	tint_progress = tertiary_color
	$OverBar.tint_over = secondary_color
	$OverBar.tint_progress = primary_color

func deal_damage(amount: int):
	$OverBar.value -= amount
	
func commit_damage():
	var tween := create_tween()
	tween.tween_property(self, "value", $OverBar.value, 1).set_delay(0.5)
	return tween.finished
