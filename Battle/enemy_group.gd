extends Node2D

var enemies : Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Gets Children of node and put into a list
	enemies =  get_children()
	# Iterate through all
	for i in enemies.size():
		# Position each node to 32px below
		enemies[i].position = Vector2(0, i*32)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
