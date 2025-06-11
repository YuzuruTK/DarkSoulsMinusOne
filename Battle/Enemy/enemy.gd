extends CharacterBody2D
class_name Enemy

# Constants
const HURT_FLASH_DURATION = 0.1
const HURT_FLASH_COUNT = 3

# Node references
@onready var health_bar = $HealthBar
@onready var name_label = $Name
@onready var sprite = $Sprite
@onready var animation_player = $AnimationPlayer

# Character state
var state: String = ""
var enemy_name: String = ""

# Stats
var max_health: float = 0
var actual_health: float = 0
var attack_damage: float = 0
var initiative: int = 0

# UI
var buttons: Array[Button] = []

#region Initialization
func initialize(enemy_params: Dictionary) -> void:
	_set_stats(enemy_params)

func _set_stats(params: Dictionary) -> void:
	enemy_name = params.get("name", "Unknown Enemy")
	max_health = float(params.get("max_h", 10))
	actual_health = float(params.get("actual_h", max_health))
	attack_damage = float(params.get("atk_dam", 1))
	initiative = params.get("initiative", 0)
#endregion

#region Godot Lifecycle
func _ready() -> void:
	_setup_ui()

func _process(_delta: float) -> void:
	pass
#endregion

#region UI Management
func _setup_ui() -> void:
	_adjust_name_position()
	_update_health_display()

func _update_health_display() -> void:
	if health_bar == null:
		push_warning("Health bar not found for enemy: %s" % enemy_name)
		return
	
	var health_percentage = (actual_health / max_health) * 100
	health_bar.value = health_percentage

func _adjust_name_position() -> void:
	if name_label == null or health_bar == null:
		return
	
	# Position name label above health bar
	name_label.position = Vector2(health_bar.position.x, health_bar.position.y - 50)
	name_label.size = health_bar.size
	name_label.scale = health_bar.scale
	
	var font_size = round(health_bar.size.y / 1.5)
	name_label.text = "[font_size=%d]%s[/font_size]" % [font_size, enemy_name]
#endregion

#region Combat Actions
func got_hurt(damage_points: int) -> void:
	actual_health = max(0, actual_health - damage_points)
	_update_health_display()
	await _play_hurt_animation()

func _play_hurt_animation() -> void:
	if animation_player and animation_player.has_animation("hurt"):
		animation_player.play("hurt")
		await animation_player.animation_finished
	else:
		# Fallback flash animation
		await _play_flash_animation()

func _play_flash_animation() -> void:
	for i in HURT_FLASH_COUNT:
		visible = false
		await get_tree().create_timer(HURT_FLASH_DURATION).timeout
		visible = true
		await get_tree().create_timer(HURT_FLASH_DURATION).timeout

func get_damage() -> int:
	return int(attack_damage)
#endregion

#region Health Checks
func is_alive() -> bool:
	return actual_health > 0

func is_dead() -> bool:
	return actual_health <= 0
#endregion

#region AI Behavior
func choose_action() -> Dictionary:
	# Simple AI: always attack for now
	# This can be expanded with more complex AI logic
	return {
		"type": "attack",
		"damage": get_damage()
	}

func get_available_actions() -> Array[String]:
	var actions = ["attack"]
	# Add more actions based on enemy type or abilities
	return actions
#endregion
