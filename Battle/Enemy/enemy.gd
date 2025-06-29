extends CharacterBody2D
class_name Enemy

# Constants
const HUD_SIZE = Vector2(400, 50)
const HUD_SCALE = Vector2(0.25, 0.4)
const HURT_FLASH_DURATION = 0.1
const HURT_FLASH_COUNT = 3

# Node references
@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel
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
	_load_sprite()

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
	_setup_hud()

func _process(_delta: float) -> void:
	pass
#endregion

#region HUD Management
func _setup_hud() -> void:
	_update_hud()
	_adjust_hud_layout()

func _update_hud() -> void:
	if health_bar == null:
		push_warning("Health bar not found for enemy: %s" % enemy_name)
		return
	
	var health_percentage = (actual_health / max_health) * 100
	health_bar.value = health_percentage
	
	# Update health label with proper formatting
	var font_size = round(HUD_SIZE.y * 0.5)
	health_label.text = "[center][color=WHITE][font_size=%d] %d / %d [/font_size]" % [font_size, actual_health, max_health]

func _adjust_hud_layout() -> void:
	_setup_health_bar()
	_setup_nametag()

func _setup_health_bar() -> void:
	if health_bar == null:
		return
	
	# Set proper scaling and fill mode
	health_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	
	# Position health bar above the sprite, centered
	if sprite and sprite.texture:
		var sprite_top = -(sprite.texture.get_size().y * sprite.scale.y) / 2
		var bar_width = health_bar.texture_under.get_size().x * health_bar.scale.x
		
		health_bar.position.x = -bar_width / 2  # Center horizontally
		health_bar.position.y = sprite_top - (health_bar.texture_under.get_size().y * health_bar.scale.y) * 1.1  # 10 pixels above sprite
	else:
		# Fallback positioning if sprite isn't available yet
		health_bar.position = Vector2(-200, -150)
	
	# Setup health label if it exists
	if health_label:
		health_label.position.x = health_bar.position.x
		health_label.position.y = health_bar.position.y
		health_label.size = health_bar.size * health_bar.scale
		health_label.bbcode_enabled = true

func _setup_nametag() -> void:
	if name_label == null:
		return
	
	# Position nametag above health bar, centered
	name_label.position.x = -HUD_SIZE.x / 2  # Center horizontally
	name_label.position.y = health_bar.position.y - HUD_SIZE.y - 5  # 5 pixels above mana bar
	name_label.size = HUD_SIZE
	name_label.bbcode_enabled = true
	
	var font_size = round(HUD_SIZE.y * 0.7)
	name_label.text = "[center][font_size=%d]%s[/font_size][/center]" % [font_size, enemy_name]
#endregion

#region Combat Actions
func got_hurt(damage_points: int) -> void:
	actual_health = max(0, actual_health - damage_points)
	_update_hud()
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
	# Recalculate HUD positions after sprite change
	_adjust_hud_layout()

func get_sprite_path() -> String:
	return sprite_path
#endregion
