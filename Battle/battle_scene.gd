extends Node2D

@onready var imported_players = [] 
@onready var imported_enemies = [{"name" : "Mocego", "max_h" : 10, "actual_h" : 10, "atk_dam" : 1, "initiative" : randi_range(0, 10)},
								{"name" : "Mocego 2", "max_h" : 12, "actual_h" : 7, "atk_dam" : 2, "initiative" : randi_range(0, 10)}]

var enemies:Array[Enemy]
var party:Array[Player]
@export var turn: int

var player_node = preload("res://Battle/Player/Player.tscn")
var enemy_node = preload("res://Battle/Enemy/Enemy.tscn")
var battle_interface = preload("res://Battle/good_user_interface.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var functions = SaveFunctions.new()
	add_child(functions)
	imported_players = functions.load_characters()
	var skills_table = functions.load_skills()
	
	turn = 0
	# Create the characters
	var temp_party = imported_players
	var temp_enemies = imported_enemies
	# creates the characters objects and set them in the scene
	for index in range(len(temp_party)):
		var player_instance: Player = player_node.instantiate() as Player
		player_instance.initialize(temp_party[index], skills_table)
		player_instance.name = temp_party[index].name
		$PlayerGroup.add_child(player_instance)
		_position_character_in_battle(player_instance, index)
		party.append(player_instance)
		pass
	# Creates the enemies Objects and set them in scene
	for index in range(len(temp_enemies)):
		var enemy_instance: Enemy = enemy_node.instantiate() as Enemy
		enemy_instance.initialize(temp_enemies[index])
		enemy_instance.name = temp_enemies[index].name
		$EnemyGroup.add_child(enemy_instance)
		_position_enemies_in_battle(enemy_instance, index)
		enemies.append(enemy_instance)
	# Set Camera position to origin
	$Camera2D.position = Vector2(0,0)
	# Zoom out Camera
	_camera_zoom($Camera2D, 0.8)
	# while there is enemies and players alive the turns will increase
	while len(enemies) != 0 and len(party) != 0:
		await _turn_things()
		var actors  = []
		actors.append_array(enemies)
		actors.append_array(party)
		for actor in actors:
			if actor.actual_health <= 0:
				if actor is Player:
					party.erase(actor)
				else:
					enemies.erase(actor)
				pass
			pass
		turn += 1	
		pass
	#functions.save_characters(party.map(func(player: Player): return player.export()) as Array[Dictionary])
	pass
	
func _character_action(character: Player) -> Dictionary:
	# Creates a visual interface to battle
	var battle_ui = battle_interface.instantiate() as BattleUi
	character.add_child(battle_ui)
	var enemies_available: Array[Dictionary] = []
	# adds the enemies available in an array with custom object
	for enemy in enemies: 
		enemies_available.append({"name" : enemy.name, "id" : enemies.find(enemy)})
	battle_ui.enemies_available = enemies_available
	var action_choosed: Dictionary = await battle_ui.action_chosen
	# deleting the UI
	character.remove_child(battle_ui)
	return action_choosed
	pass
func _enemy_action(enemy: Enemy, target: Player):
	var possible_actions = ["attack", "attack"]
	var action_choosed = possible_actions[randi_range(0, len(possible_actions) - 1)]
	if action_choosed == "attack":
		target.got_hurt(enemy.attack_damage)
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
	#for actor in action_order:
		#if actor is Player:
			#$Camera2D/Label.text += actor.player_name
		#elif actor is Enemy:
			#$Camera2D/Label.text += actor.enemy_name
		#$Camera2D/Label.text += ", "
	# Doing the actions
	for actor in action_order:
		if len($"EnemyGroup".get_children()) == 0 or len($"PlayerGroup".get_children()) == 0:
			break
		if actor is Player:
			var player_position = Vector2($EnemyGroup.position[0] + $PlayerGroup.position[0], 0)
			var old_player_position = actor.position
			_node_movement_smooth(actor, player_position, true)
			var action_choosed = await _character_action(actor)
			# action choosed
			var attack_id = action_choosed.attack_id
			var atk_damage: int = actor.get_attack_damage(attack_id)
			var enemies_affected = action_choosed.enemies
			for enemy_id in enemies_affected:
				await enemies[enemy_id].got_hurt(atk_damage)
				if enemies[enemy_id].actual_health <= 0:
					$"EnemyGroup".remove_child(enemies[enemy_id])
					action_order.erase(enemies[enemy_id])
			_node_movement_smooth(actor, old_player_position, false)
			pass
	# for in enemies to decide random movements
		elif actor is Enemy:
			if len(party) == 0:
				break
			var attack_selection = randi_range(0, len(party) - 1)
			var characters_affected = await _enemy_action(actor, party[attack_selection])
			if party[attack_selection].actual_health <= 0:
				$"EnemyGroup".remove_child(party[attack_selection])
				action_order.erase(party[attack_selection])
				enemies.erase(party[attack_selection])
			if len($"PlayerGroup".get_children()) == 0:
				break
			pass
	# decide the order of attacks based on initiative
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

func _node_movement_smooth(node: Node2D, position: Vector2, global_position: bool) -> void:
	var tween = create_tween()
	if global_position:
		tween.tween_property(node, "global_position", position, 1.0)
	else:
		tween.tween_property(node, "position", position, 1.0)
	pass

func _position_action_character(character: Player) -> void:
	var tween = character.get_tree().create_tween()
	var middle_of_battlefield = Vector2(-400,300)
	tween.tween_property(character, "position", middle_of_battlefield, 1.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	pass
