extends Node
class_name EnemyGenerator

# Enemy type definitions with base stats
enum EnemyType {
	SKELETON,
	WOLF,
	BIRD,
	HOG,
	SOLDIER,
	TIGER,
	PHANTASM,
	ALIEN,
}

# Difficulty scaling
enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	NIGHTMARE
}

# Enemy sprite paths for each type
const ENEMY_SPRITES = {
	EnemyType.WOLF: "res://Sprites/enemies/wolf_0.png",
	EnemyType.BIRD: ["res://Sprites/enemies/arara_0.png", "res://Sprites/enemies/tucano_0.png", "res://Sprites/enemies/want_want_0.png", "res://Sprites/enemies/bat_0.png"],
	EnemyType.HOG: "res://Sprites/enemies/hog_0.png",
	EnemyType.SKELETON: "res://Sprites/enemies/skeleton_0.png",
	EnemyType.SOLDIER: "res://Sprites/enemies/soldier_0.png",
	EnemyType.PHANTASM: "res://Sprites/enemies/phantasm_0.png",
	EnemyType.ALIEN: "res://Sprites/enemies/bat_0.png", # Using bat as alien placeholder
	EnemyType.TIGER: "res://Sprites/enemies/tiger_0.png"
}

# Enemy name pools for each type
const ENEMY_NAMES = {
	EnemyType.WOLF: ["Nightfang", "Alpha", "Uivador", "Shadowpelt"],
	EnemyType.BIRD: ["Stormcaller", "Harbinger", "Arara", "Tucano", "Want-Want"],
	EnemyType.HOG: ["Tusker", "Razorback", "Grunter", "Caititu", "Queixada"],
	EnemyType.SKELETON: ["Gravewalker", "Hollow", "Reaper", "Caveira", "Puro-Osso"],
	EnemyType.SOLDIER: ["Ironheart", "Sentinel", "Vanguard", "Brigadeiro", "Sargento", "Jagunço", "Milico", "Jorge"],
	EnemyType.PHANTASM: ["Wraith", "Phantom", "Fantasma", "Aparição", "Sombra", "Specter"],
	EnemyType.ALIEN: ["Vagalume Estelar", "Observador Silencioso", "Código Cósmico", "Estranho do Espaço"],
	EnemyType.TIGER: ["Shadow Stalker", "Night Hunter", "Suçuarana", "Pintada", "Jaguar"]
}

# Base stats for each enemy type
const BASE_STATS = {
	EnemyType.WOLF: {"max_h": 18, "atk_dam": 5, "init_range": [2, 6]}, # Aggressive brute
	EnemyType.BIRD: {"max_h": 10, "atk_dam": 3, "init_range": [3, 9]}, # Fast annoyance
	EnemyType.HOG: {"max_h": 14, "atk_dam": 2, "init_range": [1, 4]}, # Tanky slow beast
	EnemyType.SKELETON: {"max_h": 12, "atk_dam": 4, "init_range": [4, 9]}, # Agile and smart
	EnemyType.SOLDIER: {"max_h": 16, "atk_dam": 4, "init_range": [5, 10]}, # Tactical, average all
	EnemyType.PHANTASM: {"max_h": 13, "atk_dam": 4, "init_range": [5, 10]}, # Magic-like threat
	EnemyType.ALIEN: {"max_h": 18, "atk_dam": 6, "init_range": [3, 7]}, # High damage threat
	EnemyType.TIGER: {"max_h": 11, "atk_dam": 3, "init_range": [6, 12]}, # Ambusher
}

# Difficulty multipliers
const DIFFICULTY_MULTIPLIERS = {
	Difficulty.EASY: {"health": 0.7, "damage": 0.8, "init_bonus": 0},
	Difficulty.NORMAL: {"health": 1.0, "damage": 1.0, "init_bonus": 0},
	Difficulty.HARD: {"health": 1.4, "damage": 1.3, "init_bonus": 2},
	Difficulty.NIGHTMARE: {"health": 2.0, "damage": 1.6, "init_bonus": 4}
}

# Random variation ranges (as percentages)
const STAT_VARIANCE = 0.2 # ±20% variation

#region Public Methods

## Generates a single random enemy
func generate_random_enemy(difficulty: Difficulty = Difficulty.NORMAL) -> Dictionary:
	var enemy_type = _get_random_enemy_type()
	return generate_enemy_of_type(enemy_type, difficulty)

## Generates an enemy of a specific type
func generate_enemy_of_type(enemy_type: EnemyType, difficulty: Difficulty = Difficulty.NORMAL) -> Dictionary:
	var base_stats = BASE_STATS[enemy_type]
	var difficulty_mods = DIFFICULTY_MULTIPLIERS[difficulty]
	
	# Calculate stats with difficulty and random variance
	var max_health = _apply_variance_and_difficulty(base_stats.max_h, difficulty_mods.health)
	var attack_damage = _apply_variance_and_difficulty(base_stats.atk_dam, difficulty_mods.damage)
	var initiative_range = base_stats.init_range
	var initiative = randi_range(initiative_range[0], initiative_range[1]) + difficulty_mods.init_bonus
	
	# Generate name and sprite
	var name = _generate_enemy_name(enemy_type)
	var sprite_path = _get_enemy_sprite_path(enemy_type)
	
	# Build enemy dictionary matching your structure
	var enemy_data = {
		"name": name,
		"type": EnemyType.keys()[enemy_type].to_lower(),
		"max_h": max_health,
		"actual_h": max_health, # Start at full health
		"atk_dam": attack_damage,
		"initiative": initiative,
		"sprite_path": sprite_path, # Add sprite path to enemy data
		"enemy_type": enemy_type # Keep reference to enum for easy access
	}
	
	return enemy_data

## Generates a group of random enemies
func generate_enemy_group(group_size: int, difficulty: Difficulty = Difficulty.NORMAL, balance_types: bool = true) -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	
	if balance_types and group_size > 1:
		# Ensure variety in enemy types
		var types_to_use = _select_balanced_types(group_size)
		var enemy_names = {}
		for i in range(group_size):
			var enemy_type = types_to_use[i % types_to_use.size()]
			var enemy = generate_enemy_of_type(enemy_type, difficulty)
			if enemy.name in enemy_names:
				enemy_names[enemy.name] += 1
				enemy.name += " " + str(enemy_names[enemy.name])
			else:
				enemy_names[enemy.name] = 1
			enemies.append(enemy)
	else:
		# Completely random
		for i in range(group_size):
			enemies.append(generate_random_enemy(difficulty))
	
	return enemies

## Generates enemies based on player level/power
func generate_scaled_enemies(player_count: int, average_player_level: int) -> Array[Dictionary]:
	var difficulty = _determine_difficulty_from_level(average_player_level)
	var enemy_count = _calculate_enemy_count(player_count, average_player_level)
	
	return generate_enemy_group(enemy_count, difficulty, true)

## Generates a boss enemy
func generate_boss_enemy(difficulty: Difficulty = Difficulty.HARD) -> Dictionary:
	# Bosses are typically tigers or aliens
	var boss_types = [EnemyType.TIGER, EnemyType.ALIEN]
	var boss_type = boss_types[randi() % boss_types.size()]
	
	var boss = generate_enemy_of_type(boss_type, difficulty)
	
	# Enhance boss stats
	boss.max_h = int(boss.max_h * 1.5)
	boss.actual_h = boss.max_h
	boss.atk_dam = int(boss.atk_dam * 1.3)
	boss.initiative += 3
	
	# Add boss title
	var titles = ["O Destruidor", "O Ancião", "O Terrivel", "O Incrivel", "O Maldito"]
	boss.name += " " + titles[randi() % titles.size()]
	
	return boss

#endregion

#region Private Helper Methods

func _get_random_enemy_type() -> EnemyType:
	var types = EnemyType.values()
	return types[randi() % types.size()]

func _apply_variance_and_difficulty(base_value: float, difficulty_multiplier: float) -> int:
	# Apply difficulty multiplier
	var modified_value = base_value * difficulty_multiplier
	
	# Apply random variance (±20%)
	var variance = modified_value * STAT_VARIANCE
	var min_val = modified_value - variance
	var max_val = modified_value + variance
	
	return int(randf_range(min_val, max_val))

func _generate_enemy_name(enemy_type: EnemyType) -> String:
	var name_pool = ENEMY_NAMES[enemy_type]
	var base_name = name_pool[randi() % name_pool.size()]
	
	return base_name

func _get_enemy_sprite_path(enemy_type: EnemyType) -> String:
	var sprite_data = ENEMY_SPRITES[enemy_type]
	
	# Handle both single sprites and arrays of sprites
	if sprite_data is Array:
		# For types with multiple sprite options (like BIRD), pick randomly
		return sprite_data[randi() % sprite_data.size()]
	else:
		# For types with single sprites, return directly
		return sprite_data

func _select_balanced_types(group_size: int) -> Array[EnemyType]:
	var selected_types: Array[EnemyType] = []
	var available_types = EnemyType.values()
	available_types.shuffle()
	
	# Ensure we have at least 2-3 different types for variety
	var type_count = min(group_size, max(2, group_size / 2))
	
	for i in range(type_count):
		selected_types.append(available_types[i])
	
	return selected_types

func _determine_difficulty_from_level(average_level: int) -> Difficulty:
	if average_level <= 3:
		return Difficulty.EASY
	elif average_level <= 7:
		return Difficulty.NORMAL
	elif average_level <= 12:
		return Difficulty.HARD
	else:
		return Difficulty.NIGHTMARE

func _calculate_enemy_count(player_count: int, average_level: int) -> int:
	# Base enemy count on party size and level
	var base_count = max(1, player_count - 1) # Usually 1 less than party size
	
	# Adjust based on level
	if average_level > 5:
		base_count += 1
	if average_level > 10:
		base_count += 1
	
	return min(base_count, 4) # Cap at 4 enemies for manageable battles

#endregion

#region Utility Methods

## Get a human-readable description of an enemy
func get_enemy_description(enemy_data: Dictionary) -> String:
	var desc = "%s is a %s with %d health and %d attack power." % [
		enemy_data.name,
		enemy_data.get("type", "unknown creature"),
		enemy_data.max_h,
		enemy_data.atk_dam
	]
	
	if enemy_data.initiative > 8:
		desc += " They look very quick!"
	elif enemy_data.initiative < 3:
		desc += " They seem sluggish."
	
	return desc

#endregion
