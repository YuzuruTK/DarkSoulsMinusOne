extends Sprite2D

@export var pulse_speed := 2.0             # Velocidade da pulsação (brilho)
@export var brightness_min := 0.5          # Opacidade mínima
@export var brightness_max := 1.0          # Opacidade máxima

@export var float_amplitude := 4.0         # Distância para cima/baixo
@export var float_speed := 1.0             # Velocidade do movimento vertical

var base_position: Vector2
var time := 0.0

func _ready():
	base_position = position

func _process(delta):
	time += delta

	# Brilho pulsante (alfa varia suavemente entre brilho_min e brilho_max)
	var alpha := brightness_min + (brightness_max - brightness_min) * 0.5 * (1.0 + sin(time * pulse_speed))
	modulate.a = alpha

	# Movimento vertical suave (senoidal)
	var offset_y := sin(time * float_speed) * float_amplitude
	position.y = base_position.y + offset_y
