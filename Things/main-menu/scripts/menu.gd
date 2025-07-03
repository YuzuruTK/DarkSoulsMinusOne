extends Control

@onready var label = $Label
@onready var timer = $Timer

func _ready():
	pass

func _input(event):
	# Detecta qualquer tecla pressionada
	if event is InputEventKey and event.pressed:
		_continue_to_game()
	# Ou detecta clique do mouse
	elif event is InputEventMouseButton and event.pressed:
		_continue_to_game()

func _continue_to_game():
	get_tree().change_scene_to_file("res://Things/main-menu/scenes/introduction.tscn")
