extends CharacterBody2D
class_name Enemy

# Constants
const HUD_SIZE = Vector2(400, 50)
const HUD_SCALE = Vector2(0.25, 0.4)
const HURT_FLASH_DURATION = 0.1
const HURT_FLASH_COUNT = 3

# Node references
@onready var health_bar = $HealthBar
@onready var health_label = Label.new()
@onready var name_label = $Name
@onready var sprite = $Sprite
@onready var animation_player = $AnimationPlayer

# Character state
var state: String = ""
var enemy_name: String = ""
var enemy_type: String = ""
var sprite_path: String = ""

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
	enemy_type = params.get("type", "unknown")
	sprite_path = params.get("sprite_path", "res://Sprites/placeholder.png")
	max_health = float(params.get("max_h", 10))
	actual_health = float(params.get("actual_h", max_health))
	attack_damage = float(params.get("atk_dam", 1))
	initiative = params.get("initiative", 0)

func _load_sprite() -> void:
	if sprite == null:
		push_warning("Sprite node not found for enemy: %s" % enemy_name)
		return
	
	# Load the texture from the sprite path
	var texture = load(sprite_path) as Texture2D
	if texture != null:
		sprite.texture = texture
		print("Loaded sprite for %s: %s" % [enemy_name, sprite_path])
	else:
		push_warning("Failed to load sprite for %s at path: %s" % [enemy_name, sprite_path])
		# Fallback to placeholder
		var placeholder = load("res://Sprites/placeholder.png") as Texture2D
		if placeholder != null:
			sprite.texture = placeholder
#endregion

#region Godot Lifecycle
func _ready() -> void:
	$".".add_child(health_label)
	_setup_hud()

func _process(_delta: float) -> void:
	pass
#endregion

#region HUD Management
func _setup_hud() -> void:
	_update_health_display()
	_adjust_hud_layout()

func _update_health_display() -> void:
	if health_bar == null:
		push_warning("Health bar not found for enemy: %s" % enemy_name)
		return
	
	var health_percentage = (actual_health / max_health) * 100
	health_bar.value = health_percentage
	
	# Update health label
	health_label.text = "%d / %d" % [actual_health, max_health]

func _adjust_hud_layout() -> void:
	_setup_health_bar()
	_setup_nametag()

func _setup_health_bar() -> void:
	if health_bar == null:
		return
		
	health_bar.position = Vector2(-200, -150)
	health_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	health_bar.size = HUD_SIZE
	health_bar.scale = HUD_SCALE
	
	# Position health label below the health bar
	health_label.position = Vector2($".".position.x - (health_label.get_combined_minimum_size().x / 2), health_bar.position.y + 26)

func _setup_nametag() -> void:
	if name_label == null:
		return
		
	name_label.position = Vector2(-200, -200)
	name_label.size = HUD_SIZE
	name_label.scale = HUD_SCALE
	name_label.bbcode_enabled = true
	
	var font_size = round(HUD_SIZE.y / 1.5)
	name_label.text = "[font_size=%d]%s[/font_size]" % [font_size, enemy_name]
#endregion

#region Combat Actions
func got_hurt(damage_points: int) -> void:
	actual_health = max(0, actual_health - damage_points)
	_update_health_display()
	await _play_hurt_animation()

func _play_hurt_animation() -> void:
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

#region Sprite Management
func change_sprite(new_sprite_path: String) -> void:
	sprite_path = new_sprite_path
	_load_sprite()

func get_sprite_path() -> String:
	return sprite_path
#endregion
