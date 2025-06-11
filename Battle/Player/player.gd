extends CharacterBody2D
class_name Player

# Constants
const HUD_SIZE = Vector2(400, 50)
const HUD_SCALE = Vector2(0.25, 0.4)
const HURT_FLASH_DURATION = 0.1
const HURT_FLASH_COUNT = 3

# Node references
@onready var mana_bar = $ManaBar
@onready var health_bar = $HealthBar
@onready var nametag = $Name
@onready var sprite = $Sprite

# Character state
var state: String = ""
var player_name: String = ""

# Stats
var max_health: float = 0
var actual_health: float = 0
var max_mana: float = 100
var actual_mana: float = 20
var attack_damage: float = 0
var initiative: int = 0

# Skills and UI
@export var skills: Dictionary[int, Dictionary] = {}
var buttons: Array[Button] = []

#region Initialization
func initialize(player_params: Dictionary, skill_table: Dictionary) -> void:
	_set_base_stats(player_params)
	_initialize_skills(player_params, skill_table)

func _set_base_stats(params: Dictionary) -> void:
	player_name = params.name
	max_health = float(params.max_h)
	actual_health = float(params.actual_h)
	attack_damage = float(params.atk_dam)
	initiative = params.initiative

func _initialize_skills(params: Dictionary, skill_table: Dictionary) -> void:
	var skill_ids = params.get("skills_id", [0, 1])
	for skill_id: int in skill_ids:
		if skill_table.has(skill_id):
			skills[skill_id] = skill_table[skill_id]
#endregion

#region Data Export
func export() -> Dictionary:
	return {
		"name": player_name,
		"max_h": max_health,
		"actual_h": actual_health,
		"atk_dam": attack_damage,
		"initiative": initiative,
		"skills_id": skills.keys()
	}
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
	var health_percentage = (actual_health / max_health) * 100
	var mana_percentage = (actual_mana / max_mana) * 100
	
	health_bar.value = health_percentage
	mana_bar.value = mana_percentage

func _adjust_hud_layout() -> void:
	_setup_mana_bar()
	_setup_health_bar()
	_setup_nametag()

func _setup_mana_bar() -> void:
	mana_bar.position = Vector2(200, -200)
	mana_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	mana_bar.size = HUD_SIZE
	mana_bar.scale = Vector2(-HUD_SCALE.x, HUD_SCALE.y)

func _setup_health_bar() -> void:
	health_bar.position = Vector2(-200, -250)
	health_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	health_bar.size = HUD_SIZE
	health_bar.scale = HUD_SCALE

func _setup_nametag() -> void:
	nametag.position = Vector2(-200, -300)
	nametag.size = HUD_SIZE
	nametag.bbcode_enabled = true
	
	var font_size = round(HUD_SIZE.y / 1.5)
	nametag.text = "[font_size=%d]%s[/font_size]" % [font_size, player_name]
#endregion

#region Combat Actions
func get_attack_damage(skill_id: int) -> int:
	if not skills.has(skill_id):
		push_warning("Skill ID %d not found for player %s" % [skill_id, player_name])
		return 0
	
	var damage_multiplier = skills[skill_id].get("damage_multiplier", 1.0)
	var damage = attack_damage * damage_multiplier
	return round(damage)

func got_hurt(damage_points: int) -> void:
	actual_health = max(0, actual_health - damage_points)
	_update_hud()
	await _play_hurt_animation()

func _play_hurt_animation() -> void:
	for i in HURT_FLASH_COUNT:
		visible = false
		await get_tree().create_timer(HURT_FLASH_DURATION).timeout
		visible = true
		await get_tree().create_timer(HURT_FLASH_DURATION).timeout

func get_skills() -> Array[Dictionary]:
	var skill_list: Array[Dictionary] = []
	
	for skill_id in skills.keys():
		var skill_data = skills[skill_id]
		skill_list.append({
			"name": skill_data.get("name", "Unknown"),
			"id": skill_id,
			"is_multi_target": skill_data.get("is_multi_target", false)
		})
	
	return skill_list
#endregion

#region Health Checks
func is_alive() -> bool:
	return actual_health > 0

func is_dead() -> bool:
	return actual_health <= 0
#endregion
