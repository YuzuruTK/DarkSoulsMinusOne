extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Positions the Button in the middle of UiContainer
	$UiContainer/Act.position = Vector2(0,- $UiContainer/Act.size[1] / 2)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
