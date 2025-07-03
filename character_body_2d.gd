extends CharacterBody2D

@export var speed = 60

@onready var sprite = $Sprite

var mouse_position = Vector2.ZERO
var can_move := true

var animation_time = 0.0

# Preload your textures
var tex_front = preload("res://textures/player/1/p1l1.png")
var tex_back = preload("res://textures/player/1/p1l2.png")
var tex_side = preload("res://textures/player/1/p1l3.png")

func _ready():
	sprite.texture = tex_front
	sprite.scale = Vector2(0.25, 0.25)
	sprite.rotation = 0

func _physics_process(delta: float) -> void:
	if not can_move:
		return

	velocity = Vector2.ZERO
	mouse_position = get_global_mouse_position()

	if Input.is_action_pressed("forward") and (mouse_position.distance_to(position) > 2):
		var direction = (mouse_position - position).normalized()
		velocity = direction * speed

		# Atualiza sprite e efeitos
		_update_sprite(direction)
		_animate_sprite(delta, direction)
	else:
		# Reseta ao parar
		sprite.scale = Vector2(0.25, 0.25)
		sprite.rotation = 0
		animation_time = 0.0

	move_and_slide()

func _update_sprite(direction: Vector2) -> void:
	var angle = direction.angle()

	if angle > deg_to_rad(45) and angle < deg_to_rad(135):
		sprite.texture = tex_front
		sprite.flip_h = false
	elif angle < deg_to_rad(-45) and angle > deg_to_rad(-135):
		sprite.texture = tex_back
		sprite.flip_h = false
	elif angle >= deg_to_rad(-45) and angle <= deg_to_rad(45):
		sprite.texture = tex_side
		sprite.flip_h = false
	elif angle > deg_to_rad(135) or angle < deg_to_rad(-135):
		sprite.texture = tex_side
		sprite.flip_h = true

func _animate_sprite(delta: float, direction: Vector2) -> void:
	animation_time += delta * 8  # velocidade da animação
	var angle = direction.angle()

	# Andando para cima ou para baixo: squash/stretch senoidal
	if angle > deg_to_rad(45) and angle < deg_to_rad(135):
		var scale_y = 0.25 + sin(animation_time) * 0.02
		var scale_x = 0.25 - sin(animation_time) * 0.01
		sprite.scale = Vector2(scale_x, scale_y)
		sprite.rotation = 0

	elif angle < deg_to_rad(-45) and angle > deg_to_rad(-135):
		var scale_y = 0.25 + sin(animation_time) * 0.02
		var scale_x = 0.25 - sin(animation_time) * 0.01
		sprite.scale = Vector2(scale_x, scale_y)
		sprite.rotation = 0

	# Andando para os lados: rotação senoidal
	elif angle >= deg_to_rad(-45) and angle <= deg_to_rad(45):
		sprite.scale = Vector2(0.25, 0.25)
		sprite.rotation = deg_to_rad(sin(animation_time) * 5)

	elif angle > deg_to_rad(135) or angle < deg_to_rad(-135):
		sprite.scale = Vector2(0.25, 0.25)
		sprite.rotation = deg_to_rad(sin(animation_time) * -5)
