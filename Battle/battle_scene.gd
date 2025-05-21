extends Node2D

@export var enemies:Array[Enemy]
@export var party:Array[Player]
@export var turn: int

var player_node = preload("res://Battle/Player/Player.tscn")
var enemy_node = preload("res://Battle/Enemy/Enemy.tscn")
var battle_interface = preload("res://Battle/good_user_interface.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	turn = 0
	# Create the characters
	var temp_party = [{"name" : "aaaa", "max_h" : 10, "actual_h" : 10, "atk_dam" : 3, "initiative" : randi_range(0, 10)}, {"name" : "bbbb", "max_h" : 10, "actual_h" : 10, "atk_dam" : 3, "initiative" : randi_range(0, 10)},{"name" : "cccc", "max_h" : 10, "actual_h" : 5, "atk_dam" : 3, "initiative" : randi_range(0, 10)}, {"name" : "dddd", "max_h" : 10, "actual_h" : 10, "atk_dam" : 3, "initiative" : randi_range(0, 10)}]
	var temp_enemies = [{"name" : "Mocego", "max_h" : 10, "actual_h" : 10, "atk_dam" : 1, "initiative" : randi_range(0, 10)}, {"name" : "Mocego 2", "max_h" : 12, "actual_h" : 7, "atk_dam" : 2, "initiative" : randi_range(0, 10)}]
	# Load Characters and set them in the scene
	for index in range(len(temp_party)):
		var player_instance: Player = player_node.instantiate() as Player
		player_instance.initialize(temp_party[index])
		player_instance.name = temp_party[index].name
		$PlayerGroup.add_child(player_instance)
		_position_character_in_battle(player_instance, index)
		party.append(player_instance)
		pass
	for index in range(len(temp_enemies)):
		var enemy_instance: Enemy = enemy_node.instantiate() as Enemy
		enemy_instance.initialize(temp_enemies[index])
		enemy_instance.name = temp_enemies[index].name
		$EnemyGroup.add_child(enemy_instance)
		_position_enemies_in_battle(enemy_instance, index)
		enemies.append(enemy_instance)
	#party = temp_party
	#enemies = temp_enemies
	# Set Camera position to origin
	$Camera2D.position = Vector2(0,0)
	# Zoom out Camera
	_camera_zoom($Camera2D, 0.5)
	while len(enemies) != 0 and len(party) != 0:
		await _turn_things()
		turn += 1	
		pass
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass
	
func _character_action(character: Player) -> Array:
	var battle_ui = battle_interface.instantiate() as BattleUi
	character.add_child(battle_ui)
	var enemies_available: Array[Dictionary] = []
	for enemy in enemies: 
		enemies_available.append({"name" : enemy.name, "id" : enemies.find(enemy)})
	battle_ui.enemies_available = enemies_available
	var action_choosed: Dictionary = await battle_ui.action_chosen
	var selected_enemies = action_choosed.enemies
	var	attack = action_choosed.attack_id
	for enemy_id in selected_enemies:
		_process_character_damage(character, enemies[enemy_id], attack)
	character.remove_child(battle_ui)
	return selected_enemies
	pass
func _enemy_action(enemy: Enemy, target: Player):
	var possible_actions = ["attack", "attack"]
	var action_choosed = possible_actions[randi_range(0, len(possible_actions) - 1)]
	if action_choosed == "attack":
		_process_enemy_damage(enemy, target, enemy.attack_damage)
		pass
	pass

func _turn_things() -> void:
	$Camera2D/Label.text = ""
	# for in each of characters to decide their actions
	# Camera position calculus
	var enemies_position = Vector2(0,0)
	for enemy in enemies:
		enemies_position -= enemy.position
	enemies_position += $EnemyGroup.position
	# sorting of action orders
	var action_order = []
	action_order.append_array(enemies)
	action_order.append_array(party)
	action_order.sort_custom(func(a,b): return a.initiative < b.initiative)
	# Adjusting Order
	for actor in action_order:
		if actor is Player:
			$Camera2D/Label.text += actor.player_name
		elif actor is Enemy:
			$Camera2D/Label.text += actor.enemy_name
		$Camera2D/Label.text += ", "
	# Doing the actions
	for actor in action_order:
		if actor is Player:
			if len(enemies) == 0:
				break
			var camera_position = Vector2(enemies_position[0], 0) + (actor.position / 5)
			_camera_zoom($Camera2D, 0.8)
			$Camera2D.position = camera_position
			var enemies_affected = await _character_action(actor)
			for enemy_id in enemies_affected:
				if enemies[enemy_id].actual_health <= 0:
					$"EnemyGroup".remove_child(enemies[enemy_id])
					action_order.erase(enemies[enemy_id])
					enemies.erase(enemies[enemy_id])
			pass
		elif actor is Enemy:
			if len(party) == 0:
				break
			var attack_selection = randi_range(0, len(party) - 1)
			var characters_affected = await _enemy_action(actor, party[attack_selection])
			if party[attack_selection].actual_health <= 0:
				$"EnemyGroup".remove_child(party[attack_selection])
				action_order.erase(party[attack_selection])
				enemies.erase(party[attack_selection])
			pass
	# for in enemies to decide random movements
	# decide the order of attacks based on initiative
	pass
func _process_enemy_damage(enemy: Enemy, character: Player, attack_damage: int):
	character.actual_health -= attack_damage
	character._update_hud()
	pass
func _process_character_damage(character: Player, enemy: Enemy, attack: String):
	if attack == "1":
		enemy.actual_health -= character.attack_damage
	enemy._update_health()
	pass
func _position_enemies_in_battle(enemy: Enemy, iterator: int) -> void:
	var x = [0, -300, 0, -300]
	var y = [0, 200, 400, 600]
	enemy.position = Vector2(x[iterator],y[iterator])
	pass
func _position_character_in_battle(character: Player, iterator: int) -> void:
	var x = [-150, 150, -150, 150]
	var y = [0, 200, 400, 600]
	character.position = Vector2(x[iterator],y[iterator])
	pass

func _camera_zoom(camera: Camera2D, proportion: float) -> void:
	var tween = create_tween()
	tween.tween_property(camera, "zoom", Vector2(proportion, proportion), 1.0)
	pass

func _position_action_character(character: Player) -> void:
	var tween = character.get_tree().create_tween()
	var middle_of_battlefield = Vector2(-400,300)
	tween.tween_property(character, "position", middle_of_battlefield, 1.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	pass
