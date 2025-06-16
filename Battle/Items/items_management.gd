# ItemManager.gd - Singleton for managing items
extends Node
class_name ItemManager

# Item definitions
const ITEMS = {
	"chimarrao": {
		"name": "Chimarrão",
		"type": "mana_heal",
		"value": 30,
		"description": "Restaura 30 pontos de mana"
	},
	"churrasco": {
		"name": "Churrasco",
		"type": "health_heal", 
		"value": 25,
		"description": "Restaura 25 pontos de vida"
	}
}

# Default inventory
const DEFAULT_INVENTORY = {
	"chimarrao": 3,
	"churrasco": 2
}

# Current inventory
var inventory: Dictionary = {}

func _ready() -> void:
	_initialize_inventory()

func _initialize_inventory() -> void:
	inventory = DEFAULT_INVENTORY.duplicate()

# Get all items with quantity > 0
func get_available_items() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	
	for item_id in inventory.keys():
		var quantity = inventory[item_id]
		if quantity > 0 and ITEMS.has(item_id):
			var item_data = ITEMS[item_id].duplicate()
			item_data["id"] = item_id
			item_data["quantity"] = quantity
			available.append(item_data)
	
	return available

# Use an item and decrease quantity
func use_item(item_id: String) -> bool:
	if not inventory.has(item_id) or inventory[item_id] <= 0:
		return false
	
	inventory[item_id] -= 1
	return true

# Get item data by ID
func get_item_data(item_id: String) -> Dictionary:
	if ITEMS.has(item_id):
		var data = ITEMS[item_id].duplicate()
		data["id"] = item_id
		data["quantity"] = inventory.get(item_id, 0)
		return data
	return {}

# Add item to inventory
func add_item(item_id: String, quantity: int = 1) -> void:
	if ITEMS.has(item_id):
		inventory[item_id] = inventory.get(item_id, 0) + quantity

# Get inventory for saving
func export_inventory() -> Dictionary:
	return inventory.duplicate()

# Load inventory from save data
func import_inventory(data: Dictionary) -> void:
	inventory = data.duplicate()
	
	# Ensure all default items exist
	for item_id in DEFAULT_INVENTORY.keys():
		if not inventory.has(item_id):
			inventory[item_id] = 0
