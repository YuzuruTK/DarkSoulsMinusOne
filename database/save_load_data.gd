extends Node2D

class_name SaveFunctions

func _ready() -> void:
	pass
func delete_save_file(save_path):
	if FileAccess.file_exists(save_path):
		var absolute_path = ProjectSettings.globalize_path(save_path)
		DirAccess.remove_absolute(absolute_path)
		print(save_path, " deleted successfully!")
	else:
		print(save_path," doesn't exist")
		
func save_characters(characters: Array):
	var path = "user://characters.save"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(characters)
		file.store_string(json_string)
		file.close()
		print("Characters saved successfully!")
	else:
		push_error("Failed to save characters to: " + path)

func load_characters() -> Array:
	var firstPath = "res://Characters.json"
	# Delete Save for testing
	delete_save_file("user://characters.save")	
	var path = "user://characters.save"
	if not FileAccess.file_exists(path):
		path = firstPath
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var result = JSON.parse_string(content)
		file.close()
		if result is Array:
			return result
	return []

func load_skills() -> Dictionary:
	# Try loading from user directory first (downloaded version)
	var user_path = "user://skills.csv"
	delete_save_file("user://skills.csv")
	var fallback_path = "res://database/skills/skills.csv"
	
	var path = user_path if FileAccess.file_exists(user_path) else fallback_path
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Skills file not found at: ", path)
		return {}
		
	var lines = file.get_as_text().split("\n", false)
	file.close()

	if lines.size() <= 1:
		print("Skills file is empty or has no data")
		return {}

	var headers = lines[0].split(",")
	var data: Dictionary = {}

	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue
		var values = line.split(",")
		
		# Ensure we have enough values
		if values.size() < 6:
			print("Skipping incomplete skill line: ", line)
			continue
		
		# Parse all skill properties including mana_cost
		var skill = {
			"name": values[1],
			"damage_multiplier": float(values[2]),
			"description": values[3],
			"is_multi_target": values[4] == "TRUE",
			"mana_cost": int(values[5])
		}
		
		data[int(values[0])] = skill
	
	print("Loaded ", data.size(), " skills")
	return data

func load_equipment() -> Dictionary:
	# Try loading from user directory first (downloaded version)
	var user_path = "user://equipment.csv"
	delete_save_file("user://equipment.csv")
	var fallback_path = "res://database/weapons_armors/something.csv"
	
	var path = user_path if FileAccess.file_exists(user_path) else fallback_path
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Equipment file not found at: ", path)
		return {}
		
	var lines = file.get_as_text().split("\n", false)
	file.close()

	if lines.size() <= 1:
		print("Equipment file is empty or has no data")
		return {}

	var headers = lines[0].split(",")
	var data: Dictionary = {}

	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue
		var values = line.split(",")
		
		# Ensure we have enough values (id, name, type, attack, defense, description)
		if values.size() < 6:
			print("Skipping incomplete equipment line: ", line)
			continue
		
		# Parse equipment properties
		var equipment = {
			"id": values[0],
			"name": values[1],
			"type": values[2],
			"attack_bonus": int(values[3]),
			"defense_bonus": int(values[4]),
			"description": values[5]
		}
		
		data[values[0]] = equipment
	
	print("Loaded ", data.size(), " equipment items")
	return data

func load_items() -> Dictionary:
	# This function loads consumable items (potions, etc.)
	# You can implement this similar to equipment if you have an items CSV
	var user_path = "user://items.csv"
	delete_save_file("user://items.csv")
	var fallback_path = "res://database/items/items.csv"
	
	var path = user_path if FileAccess.file_exists(user_path) else fallback_path
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Items file not found at: ", path)
		return {}
		
	var lines = file.get_as_text().split("\n", false)
	file.close()

	if lines.size() <= 1:
		print("Items file is empty or has no data")
		return {}

	var data: Dictionary = {}

	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue
		var values = line.split(",")
		
		# Assuming format: id,name,type,value,description
		if values.size() < 5:
			print("Skipping incomplete item line: ", line)
			continue
		
		var item = {
			"id": values[0],
			"name": values[1],
			"type": values[2],
			"value": int(values[3]),
			"description": values[4]
		}
		
		data[values[0]] = item
	
	print("Loaded ", data.size(), " items")
	return data

# Utility function to get all game data at once
func load_all_game_data() -> Dictionary:
	return {
		"skills": load_skills(),
		"equipment": load_equipment(),
		"items": load_items(),
		"characters": load_characters()
	}

# Function to validate character data integrity
func validate_character_data(character_data: Dictionary, available_skills: Dictionary, available_equipment: Dictionary) -> bool:
	# Check required fields
	var required_fields = ["name", "max_h", "actual_h", "atk_dam", "initiative"]
	for field in required_fields:
		if not character_data.has(field):
			push_error("Character missing required field: " + field)
			return false
	
	# Validate skills
	if character_data.has("skills_id"):
		for skill_id in character_data["skills_id"]:
			if not available_skills.has(skill_id):
				push_warning("Character has invalid skill ID: " + str(skill_id))
	
	# Validate equipment
	if character_data.has("equipment"):
		var equipment_data = character_data["equipment"]
		for slot_type in equipment_data.keys():
			var item_id = equipment_data[slot_type]
			if item_id != "" and not available_equipment.has(item_id):
				push_warning("Character has invalid equipment ID: " + str(item_id))
	
	return true

# Function to migrate old save data to new format
func migrate_character_data(character_data: Dictionary) -> Dictionary:
	var migrated_data = character_data.duplicate(true)
	
	# Add missing mana fields if they don't exist
	if not migrated_data.has("max_mana"):
		migrated_data["max_mana"] = 100
	if not migrated_data.has("actual_mana"):
		migrated_data["actual_mana"] = migrated_data["max_mana"]
	
	# Add empty equipment if it doesn't exist
	if not migrated_data.has("equipment"):
		migrated_data["equipment"] = {
			"weapon": "",
			"armor": "",
			"accessory": ""
		}
	
	# Add empty inventory if it doesn't exist
	if not migrated_data.has("inventory"):
		migrated_data["inventory"] = {}
	
	return migrated_data
