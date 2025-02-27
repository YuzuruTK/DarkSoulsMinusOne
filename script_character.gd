extends CharacterBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity.x = 0;
	if velocity.y > 0: 
		velocity.y - 10;
	if Input.is_action_pressed("ui_right"):
		velocity.x = 100;
	if Input.is_action_pressed("ui_left"):
		velocity.x = -100;
	if Input.is_action_pressed("ui_up"):
		velocity.y = -500;
	move_and_slide()
