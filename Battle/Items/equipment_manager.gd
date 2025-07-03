# EquipmentManager.gd - Singleton for managing equipment
extends Node
class_name EquipmentManager

# Equipment definitions - will be loaded from CSV
var EQUIPMENT: Dictionary = {
		"armor_t1": {
			"name": "Trapos velhos",
			"type": "armor",
			"attack_bonus": 0,
			"defense_bonus": 0,
			"description": "Trapos velhos que não servem nem pra limpar chao"
		},
		"armor_t2": {
			"name": "Armadura Improvisada",
			"type": "armor", 
			"attack_bonus": 0,
			"defense_bonus": 3,
			"description": "Entrevero de trapos encontrados em batalha"
		},
		"armor_t3": {
			"name": "Armadura Planejada",
			"type": "armor",
			"attack_bonus": 0,
			"defense_bonus": 6,
			"description": "Feito por um cara bagual"
		},
		"sword_t1": {
			"name": "Tábua de charque",
			"type": "weapon",
			"attack_bonus": 0,
			"defense_bonus": 0,
			"description": "Se pega nas vista machuca"
		},
		"sword_t2": {
			"name": "Faca de lida",
			"type": "weapon",
			"attack_bonus": 3,
			"defense_bonus": 0,
			"description": "No churrasco é estrela"
		},
		"sword_t3": {
			"name": "Peleadora",
			"type": "weapon",
			"attack_bonus": 6,
			"defense_bonus": 0,
			"description": "Mais afiada lingua de sogra"
		}
	}

# Default equipment for new characters
const DEFAULT_EQUIPMENT = {
	"armor": "",  # No armor equipped by default
	"weapon": ""  # No weapon equipped by default
}

# Current equipped items
var equipped: Dictionary = {}

func _ready() -> void:
	pass
	

func _initialize_equipment() -> void:
	equipped = DEFAULT_EQUIPMENT.duplicate()

# Get all available equipment
func get_all_equipment() -> Array[Dictionary]:
	var equipment_list: Array[Dictionary] = []
	
	for item_id in EQUIPMENT.keys():
		var item_data = EQUIPMENT[item_id].duplicate()
		item_data["id"] = item_id
		item_data["is_equipped"] = _is_equipped(item_id)
		equipment_list.append(item_data)
	
	return equipment_list

# Get equipment by type (armor/weapon)
func get_equipment_by_type(equipment_type: String) -> Array[Dictionary]:
	var filtered_equipment: Array[Dictionary] = []
	
	for item_id in EQUIPMENT.keys():
		var item_data = EQUIPMENT[item_id]
		if item_data.type == equipment_type:
			var equipment_info = item_data.duplicate()
			equipment_info["id"] = item_id
			equipment_info["is_equipped"] = _is_equipped(item_id)
			filtered_equipment.append(equipment_info)
	
	return filtered_equipment

# Check if an item is currently equipped
func _is_equipped(item_id: String) -> bool:
	if not EQUIPMENT.has(item_id):
		return false
	
	var item_type = EQUIPMENT[item_id].type
	return equipped.get(item_type, "") == item_id

# Equip an item
func equip_item(item_id: String) -> bool:
	if not EQUIPMENT.has(item_id):
		print("Equipment not found: ", item_id)
		return false
	
	var item_data = EQUIPMENT[item_id]
	var item_type = item_data.type
	
	# Unequip previous item of same type if any
	if equipped.has(item_type) and equipped[item_type] != "":
		var old_item = equipped[item_type]
		print("Unequipped: ", EQUIPMENT[old_item].name)
	
	# Equip new item
	equipped[item_type] = item_id
	print("Equipped: ", item_data.name)
	return true

# Unequip an item by type
func unequip_item(equipment_type: String) -> bool:
	if not equipped.has(equipment_type) or equipped[equipment_type] == "":
		return false
	
	var item_id = equipped[equipment_type]
	equipped[equipment_type] = ""
	print("Unequipped: ", EQUIPMENT[item_id].name)
	return true

# Get currently equipped item by type
func get_equipped_item(equipment_type: String) -> Dictionary:
	if not equipped.has(equipment_type) or equipped[equipment_type] == "":
		return {}
	var item_id = equipped[equipment_type]
	if EQUIPMENT.has(item_id):
		var item_data = EQUIPMENT[item_id].duplicate()
		item_data["id"] = item_id
		return item_data
	
	return {}

# Get total attack bonus from equipped weapons
func get_total_attack_bonus() -> int:
	var weapon = get_equipped_item("weapon")
	if weapon.is_empty():
		return 0
	return weapon.get("attack_bonus", 0)

# Get total defense bonus from equipped armor
func get_total_defense_bonus() -> int:
	var armor = get_equipped_item("armor")
	if armor.is_empty():
		return 0
	return armor.get("defense_bonus", 0)

# Get equipment data by ID
func get_equipment_data(item_id: String) -> Dictionary:
	if EQUIPMENT.has(item_id):
		var data = EQUIPMENT[item_id].duplicate()
		data["id"] = item_id
		data["is_equipped"] = _is_equipped(item_id)
		return data
	return {}

# Get summary of equipped items
func get_equipment_summary() -> Dictionary:
	var summary = {
		"weapon": get_equipped_item("weapon"),
		"armor": get_equipped_item("armor"),
		"total_attack_bonus": get_total_attack_bonus(),
		"total_defense_bonus": get_total_defense_bonus()
	}
	return summary

# Export equipment for saving
func export_equipment() -> Dictionary:
	return equipped.duplicate()

# Import equipment from save data
func import_equipment(data: Dictionary) -> void:
	equipped = data.duplicate()
	
	# Ensure all equipment types exist
	for equipment_type in DEFAULT_EQUIPMENT.keys():
		if not equipped.has(equipment_type):
			equipped[equipment_type] = ""
