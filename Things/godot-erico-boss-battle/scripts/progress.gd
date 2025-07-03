extends Node2D

var gradient: Gradient = Gradient.new()

func _ready() -> void:
	gradient.colors = [Color.GREEN, Color.RED]

func _process(delta: float) -> void:
	pass

func _draw() -> void:
	# print(_get_rotation_pct())
	var pct = $".."/"..".get_rotation_pct()
	draw_arc(
		$"..".position + Vector2(0, 15), 155, 
		deg_to_rad(-90.0), deg_to_rad(-90.0 + pct * 360.0), 
		50, gradient.sample(pct), 80
	)
