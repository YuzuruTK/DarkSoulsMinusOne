extends CharacterBody2D
class_name Player

# Constants
const HUD_SIZE = Vector2(400, 50)
const HUD_SCALE = Vector2(0.25, 0.4)
const HURT_FLASH_DURATION = 0.1
const HURT_FLASH_COUNT = 3

# Sprite mapping - maps character names to sprite file numbers
const SPRITE_MAPPING = {
	"Snake": "2",
	"Coach": "4",
	"Rick": "1",
	"Joao": "3"
}

# Node references
@onready var mana_bar = $ManaBar
@onready var mana_label = Label.new()
@onready var health_bar = $HealthBar
@onready var health_label = Label.new()
@onready var nametag = $Name
@onready var sprite = $Sprite

# Character state
var state: String = ""
var player_name: String = ""
var sprite_texture: Texture2D
var sprite_id: String

# Base stats (without equipment bonuses)
var base_max_health: float = 0
var actual_health: float = 0
var max_mana: float = 100
var actual_mana: float = 100
var base_attack_damage: float = 0
var initiative: int = 0

# Calculated stats (including equipment)
var max_health: float = 0
var attack_damage: float = 0
var def: int = 0

# Skills and UI
@export var skills: Dictionary[int, Dictionary] = {}
var buttons: Array[Button] = []

# Manager references
var item_manager: ItemManager
var equipment_manager: EquipmentManager

#region Initialization
func initialize(player_params: Dictionary, skill_table: Dictionary) -> void:
	_set_base_stats(player_params)
	_initialize_skills(player_params, skill_table)
	_initialize_managers()
	_load_equipment_from_params(player_params)
	_load_inventory_from_params(player_params)
	_load_sprite_from_params(player_params)
	_recalculate_stats()

func _set_base_stats(params: Dictionary) -> void:
	player_name = params.name
	base_max_health = float(params.max_h)
	actual_health = float(params.actual_h)
	base_attack_damage = float(params.atk_dam)
	initiative = params.initiative
	
	# Set mana from params if available, otherwise use default
	max_mana = float(params.get("max_mana", 100))
	actual_mana = float(params.get("actual_mana", max_mana))

func _initialize_skills(params: Dictionary, skill_table: Dictionary) -> void:
	var skill_ids = params.get("skills_id", [0, 1])
	for skill_id: int in skill_ids:
		if skill_table.has(skill_id):
			skills[skill_id] = skill_table[skill_id]

func _initialize_managers() -> void:
	if not item_manager:
		item_manager = ItemManager.new()
		item_manager._load_items_data()
		item_manager._initialize_inventory()
		add_child(item_manager)
	
	if not equipment_manager:
		equipment_manager = EquipmentManager.new()
		add_child(equipment_manager)
		equipment_manager._load_equipment_data()
		equipment_manager._initialize_equipment()

func _load_equipment_from_params(params: Dictionary) -> void:
	if params.has("equipment") and equipment_manager:
		equipment_manager.import_equipment(params.equipment)

func _load_inventory_from_params(params: Dictionary) -> void:
	if params.has("inventory") and item_manager:
		item_manager.import_inventory(params.inventory)

func _load_sprite_from_params(params: Dictionary) -> void:
	# Check if sprite_id is directly provided in params
	if params.has("sprite_id"):
		sprite_id = str(params.sprite_id)
	# Otherwise, try to map from character name
	elif SPRITE_MAPPING.has(player_name):
		sprite_id = SPRITE_MAPPING[player_name]
	else:
		print("No sprite mapping found for player: ", player_name)
		return

func _load_sprite() -> void:
	var sprite_path = "res://Sprites/characters/" + sprite_id + ".png"
	
	# Check if the sprite file exists
	if ResourceLoader.exists(sprite_path):
		sprite_texture = load(sprite_path)
		if sprite_texture and sprite:
			sprite.texture = sprite_texture
			print("Loaded sprite for ", player_name, ": ", sprite_path)
		else:
			print("Failed to load sprite texture: ", sprite_path)
	else:
		print("Sprite file not found: ", sprite_path)
		# Fallback to placeholder if available
		_load_placeholder_sprite()

func _load_placeholder_sprite() -> void:
	var placeholder_path = "res://Sprites/placeholder.png"
	if ResourceLoader.exists(placeholder_path):
		sprite_texture = load(placeholder_path)
		if sprite_texture and sprite:
			sprite.texture = sprite_texture
			print("Loaded placeholder sprite for ", player_name)

# Function to change sprite during runtime
func change_sprite(id: String) -> bool:
	sprite_id = id
	_load_sprite()
	return sprite_texture != null

# Function to get current sprite info
func get_sprite_info() -> Dictionary:
	if SPRITE_MAPPING.has(player_name):
		sprite_id = SPRITE_MAPPING[player_name]
	
	return {
		"sprite_id": sprite_id,
		"sprite_path": "res://Sprites/characters/" + sprite_id + ".png" if sprite_id != "" else "",
		"has_texture": sprite_texture != null
	}

func _recalculate_stats() -> void:
	if not equipment_manager:
		return
	
	# Calculate max health with equipment bonuses
	var defense_bonus = equipment_manager.get_total_defense_bonus()
	max_health = base_max_health + (defense_bonus * 2) # Each defense point adds 2 max health
	def = defense_bonus
	# Calculate attack damage with equipment bonuses
	var attack_bonus = equipment_manager.get_total_attack_bonus()
	attack_damage = base_attack_damage + attack_bonus
	
	# Update HUD to reflect new stats
	#_update_hud()
#endregion

#region Data Export
func export() -> Dictionary:
	var export_data = {
		"name": player_name,
		"max_h": base_max_health, # Export base stats, not calculated ones
		"actual_h": actual_health,
		"max_mana": max_mana,
		"actual_mana": actual_mana,
		"atk_dam": base_attack_damage, # Export base attack, not calculated
		"initiative": initiative,
		"skills_id": skills.keys()
	}
	
	# Include sprite information
	var sprite_info = get_sprite_info()
	if sprite_info.sprite_id != "":
		export_data["sprite_id"] = sprite_info.sprite_id
	
	# Include inventory if item_manager exists
	if item_manager:
		export_data["inventory"] = item_manager.export_inventory()
	
	# Include equipment if equipment_manager exists
	if equipment_manager:
		export_data["equipment"] = equipment_manager.export_equipment()
		
	return export_data
#endregion

#region Godot Lifecycle
func _ready() -> void:
	$".".add_child(health_label)
	$".".add_child(mana_label)
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
	
	mana_label.text = "%d / %d" % [actual_mana, max_mana]
	health_label.text = "%d / %d" % [actual_health, max_health]

func _adjust_hud_layout() -> void:
	_setup_mana_bar()
	_setup_health_bar()
	_setup_nametag()

func _setup_mana_bar() -> void:
	mana_bar.position = Vector2(200, -200)
	mana_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	mana_bar.size = HUD_SIZE
	mana_bar.scale = Vector2(-HUD_SCALE.x, HUD_SCALE.y)
	mana_label.position = Vector2($".".position.x - (mana_label.get_combined_minimum_size().x / 2), mana_bar.position.y + 26)

func _setup_health_bar() -> void:
	health_bar.position = Vector2(-200, -250)
	health_bar.fill_mode = TextureProgressBar.FILL_LEFT_TO_RIGHT
	health_bar.size = HUD_SIZE
	health_bar.scale = HUD_SCALE
	health_label.position = Vector2($".".position.x - (health_label.get_combined_minimum_size().x / 2), health_bar.position.y + 26)

func _setup_nametag() -> void:
	nametag.position = Vector2(-200, -300)
	nametag.size = HUD_SIZE
	nametag.bbcode_enabled = true
	
	var font_size = round(HUD_SIZE.y / 1.5)
	nametag.text = "[font_size=%d]%s[/font_size]" % [font_size, player_name]
#endregion

#region Mana Management
func has_enough_mana(skill_id: int) -> bool:
	if not skills.has(skill_id):
		return false
	
	var mana_cost = skills[skill_id].get("mana_cost", 0)
	return actual_mana >= mana_cost

func consume_mana(skill_id: int) -> bool:
	if not has_enough_mana(skill_id):
		return false
	
	var mana_cost = skills[skill_id].get("mana_cost", 0)
	actual_mana -= mana_cost
	actual_mana = max(0, actual_mana)
	_update_hud()
	
	print("%s used skill and consumed %d mana! Current: %d/%d" % [player_name, mana_cost, actual_mana, max_mana])
	return true

func restore_mana(amount: int) -> void:
	actual_mana = min(max_mana, actual_mana + amount)
	_update_hud()
	print("%s restored %d mana! Current: %d/%d" % [player_name, amount, actual_mana, max_mana])

func get_mana_cost(skill_id: int) -> int:
	if not skills.has(skill_id):
		return 0
	return skills[skill_id].get("mana_cost", 0)
#endregion

#region Combat Actions
func can_use_skill(skill_id: int) -> bool:
	return skills.has(skill_id) and has_enough_mana(skill_id)

func get_attack_damage(skill_id: int) -> int:
	if skill_id == 0:
		return attack_damage
	if not skills.has(skill_id):
		push_warning("Skill ID %d not found for player %s" % [skill_id, player_name])
		return 0
	
	# Basic attack (skill_id 0) doesn't consume mana
	if skill_id != 0 and not has_enough_mana(skill_id):
		push_warning("Not enough mana to use skill %d for player %s" % [skill_id, player_name])
		return 0
	
	var damage_multiplier = skills[skill_id].get("damage_multiplier", 1.0)
	var damage = attack_damage * damage_multiplier # Uses calculated attack_damage (includes equipment)
	return round(damage)

func use_skill(skill_id: int) -> bool:
	# Basic attack (skill_id 0) doesn't require mana
	if skill_id == 0:
		return true
	
	if not can_use_skill(skill_id):
		return false
	
	return consume_mana(skill_id)

func got_hurt(damage_points: int) -> void:
	# Apply defense bonus from equipment
	var actual_damage = max(1, damage_points - def) # Minimum 1 damage
	actual_health = max(0, actual_health - actual_damage)
	
	print("%s took %d damage (reduced from %d by %d defense)" % [player_name, actual_damage, damage_points, def])
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
		var can_use = can_use_skill(skill_id)
		var mana_cost = get_mana_cost(skill_id)
		
		skill_list.append({
			"name": skill_data.get("name", "Unknown"),
			"id": skill_id,
			"is_multi_target": skill_data.get("is_multi_target", false),
			"mana_cost": mana_cost,
			"can_use": can_use,
			"description": skill_data.get("description", "")
		})
	
	return skill_list
#endregion

#region Item Management
func get_available_items() -> Array[Dictionary]:
	if item_manager:
		return item_manager.get_available_items()
	return []

func use_item(item_id: String) -> bool:
	if not item_manager:
		return false
	
	var item_data = item_manager.get_item_data(item_id)
	if item_data.is_empty():
		return false
	
	# Check if we can use the item
	if not item_manager.use_item(item_id):
		return false
	
	# Apply item effects
	_apply_item_effect(item_data)
	return true

func _apply_item_effect(item_data: Dictionary) -> void:
	match item_data.type:
		"health_heal":
			_heal_health(item_data.value)
		"mana_heal":
			_heal_mana(item_data.value)
		"mana_restore":
			restore_mana(item_data.value)

func _heal_health(amount: int) -> void:
	actual_health = min(max_health, actual_health + amount)
	_update_hud()
	print("%s used item and healed %d health! Current: %d/%d" % [player_name, amount, actual_health, max_health])

func _heal_mana(amount: int) -> void:
	restore_mana(amount)
#endregion

#region Equipment Management
func get_available_equipment() -> Array[Dictionary]:
	if equipment_manager:
		return equipment_manager.get_all_equipment()
	return []

func get_equipment_by_type(equipment_type: String) -> Array[Dictionary]:
	if equipment_manager:
		return equipment_manager.get_equipment_by_type(equipment_type)
	return []

func equip_item(item_id: String) -> bool:
	if not equipment_manager:
		return false
	
	var success = equipment_manager.equip_item(item_id)
	if success:
		_recalculate_stats()
	return success

func unequip_item(equipment_type: String) -> bool:
	if not equipment_manager:
		return false
	
	var success = equipment_manager.unequip_item(equipment_type)
	if success:
		_recalculate_stats()
	return success

func get_equipped_item(equipment_type: String) -> Dictionary:
	if equipment_manager:
		return equipment_manager.get_equipped_item(equipment_type)
	return {}

func get_equipment_summary() -> Dictionary:
	if equipment_manager:
		return equipment_manager.get_equipment_summary()
	return {}

# Get current stats (base + equipment bonuses)
func get_current_stats() -> Dictionary:
	return {
		"base_attack": base_attack_damage,
		"current_attack": attack_damage,
		"attack_bonus": attack_damage - base_attack_damage,
		"base_max_health": base_max_health,
		"current_max_health": max_health,
		"defense_bonus": max_health - base_max_health,
		"actual_health": actual_health
	}
#endregion

#region Health Checks
func is_alive() -> bool:
	return actual_health > 0

func is_dead() -> bool:
	return actual_health <= 0

func is_out_of_mana() -> bool:
	return actual_mana <= 0

func has_usable_skills() -> bool:
	for skill_id in skills.keys():
		if can_use_skill(skill_id):
			return true
	return false
#endregion
