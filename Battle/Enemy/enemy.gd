extends CharacterBody2D
class_name Enemy

var state = ""
var buttons: Array[Button]
var enemy_name: String = ""
var max_health: float = 0
var actual_health: float = 0
var attack_damage: float = 0
var initiative: int = 0

func initialize(enemy_params: Dictionary):
	enemy_name = enemy_params.name
	max_health = enemy_params.max_h
	actual_health = enemy_params.actual_h
	attack_damage = enemy_params.atk_dam
	initiative = enemy_params.initiative
	pass
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_adjust_name()
	_update_health()
	pass

func _update_health() -> void:
	$HealthBar.value = actual_health/max_health * 100
	pass

func _adjust_name() -> void:
	$Name.position = Vector2($HealthBar.position[0], $HealthBar.position[1] - 50)
	$Name.size = $HealthBar.size
	$Name.scale = $HealthBar.scale
	$Name.text = "[font_size=%d][tornado radius=10.0 freq=5.0 connected=1]%s[/tornado][/font_size]" % [round($HealthBar.size[1] / 1.5), enemy_name]
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
