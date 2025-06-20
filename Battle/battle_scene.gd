extends Node2D
class_name BattleScene

# Enums for better state management
enum BattleState {
	SETUP,
	BATTLE_ACTIVE,
	PLAYER_TURN,
	ENEMY_TURN,
	BATTLE_WON,
	BATTLE_LOST
}

#	 Constants
const CAMERA_ZOOM_LEVEL = 0.8
const CAMERA_ZOOM_DURATION = 1.0
const MOVEMENT_DURATION = 1.0
const TURN_DELAY = 0.5

# Node references
@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup
@onready var camera = $Camera2D
@onready var turn_label = $Camera2D/TurnLabel
@onready var actions_show = $Camera2D/ActionsShow

# Preloaded scenes
var player_scene = preload("res://Battle/Player/Player.tscn")
var enemy_scene = preload("res://Battle/Enemy/Enemy.tscn")
var battle_ui_scene = preload("res://Battle/good_user_interface.tscn")

# Battle state
var current_state: BattleState = BattleState.SETUP
var current_turn: int = 0
var action_order: Array = []

# Collections
var party: Array[Player] = []
var enemies: Array[Enemy] = []

# Dependencies
var save_functions: SaveFunctions
var skills_table: Dictionary

#region Initialization
func _ready() -> void:
	await _initialize_battle()

func _initialize_battle() -> void:
	_setup_dependencies()
	await _setup_battle_scene()
	await _start_battle_loop()

func _setup_dependencies() -> void:
	save_functions = SaveFunctions.new()
	add_child(save_functions)
	skills_table = save_functions.load_skills()

func _setup_battle_scene() -> void:
	current_turn = 0
	_setup_camera()
	await _create_characters()
	current_state = BattleState.BATTLE_ACTIVE

func _setup_camera() -> void:
	camera.position = Vector2.ZERO
	_animate_camera_zoom(camera, CAMERA_ZOOM_LEVEL)

func _create_characters() -> void:
	var enemy_generator = EnemyGenerator.new()
	var party_data = save_functions.load_characters()
	var number_of_enemies = randi_range(2, len(party))
	var enemy_data = enemy_generator.generate_scaled_enemies(len(party_data), number_of_enemies)
	_create_party(party_data)
	_create_enemies(enemy_data)

func _create_party(party_data: Array) -> void:
	for index in range(party_data.size()):
		var player_instance = _create_player(party_data[index], index)
		party.append(player_instance)

func _create_enemies(enemy_data: Array) -> void:
	for index in range(enemy_data.size()):
		var enemy_instance = _create_enemy(enemy_data[index], index)
		enemies.append(enemy_instance)

func _create_player(player_data: Dictionary, index: int) -> Player:
	var player_instance: Player = player_scene.instantiate()
	player_instance.initialize(player_data, skills_table)
	player_instance.name = player_data.name
	
	player_group.add_child(player_instance)
	_position_player(player_instance, index)
	
	return player_instance

func _create_enemy(enemy_data: Dictionary, index: int) -> Enemy:
	var enemy_instance: Enemy = enemy_scene.instantiate()
	enemy_instance.initialize(enemy_data)
	enemy_instance.name = enemy_data.name

	enemy_group.add_child(enemy_instance)
	_position_enemy(enemy_instance, index)
	
	return enemy_instance
#endregion

#region Battle Loop
func _start_battle_loop() -> void:
	while _is_battle_active():
		_update_turn_display()
		await _execute_turn()
		_advance_turn()
	
	_end_battle()

func _is_battle_active() -> bool:
	return enemies.size() > 0 and party.size() > 0

func _update_turn_display() -> void:
	var turn_text = "[font_size=72][wave amp=100.0 freq=5.0 connected=0]Turno: %s[/wave][/font_size]" % current_turn
	turn_label.text = turn_text

func _execute_turn() -> void:
	_calculate_action_order()
	_display_action_order()
	await _process_actions()

func _calculate_action_order() -> void:
	action_order.clear()
	action_order.append_array(enemies)
	action_order.append_array(party)
	action_order.sort_custom(func(a, b): return a.initiative > b.initiative)

func _display_action_order() -> void:
	_clear_action_display()
	
	for i in range(action_order.size()):
		var actor = action_order[i]
		var label = _create_action_label(actor)
		actions_show.add_element(i, label)
	
	_position_action_display()

func _clear_action_display() -> void:
	for child in actions_show.get_children():
		actions_show.remove_child(child)

func _create_action_label(actor) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.custom_minimum_size = Vector2(actions_show.size.x / 4, actions_show.size.y)
	
	if actor is Player:
		label.text = "[font_size=30][color=BLUE]%s[/color]" % actor.player_name
	elif actor is Enemy:
		label.text = "[font_size=30][color=RED]%s[/color]" % actor.enemy_name
	
	return label

func _position_action_display() -> void:
	actions_show.position = Vector2(-actions_show.size.x / 2, 500)

func _process_actions() -> void:
	for i in range(action_order.size()):
		if not _is_battle_active():
			break
		
		var actor = action_order[i]
		if not _is_actor_valid(actor):
			continue
			
		await _execute_actor_action(actor)
		_cleanup_defeated_actors()
		_remove_action_from_display(i)

func _is_actor_valid(actor) -> bool:
	return actor != null and actor.is_alive()

func _execute_actor_action(actor) -> void:
	if actor is Player:
		await _execute_player_action(actor)
	elif actor is Enemy:
		await _execute_enemy_action(actor)

func _remove_action_from_display(index: int) -> void:
	if actions_show.has_method("delete_element"):
		actions_show.delete_element(index)

func _cleanup_defeated_actors() -> void:
	_remove_defeated_players()
	_remove_defeated_enemies()

func _remove_defeated_players() -> void:
	var defeated_players = party.filter(func(player): return player.is_dead())
	for player in defeated_players:
		party.erase(player)
		player_group.remove_child(player)

func _remove_defeated_enemies() -> void:
	var defeated_enemies = enemies.filter(func(enemy): return enemy.is_dead())
	for enemy in defeated_enemies:
		enemies.erase(enemy)
		enemy_group.remove_child(enemy)

func _advance_turn() -> void:
	current_turn += 1

func _end_battle() -> void:
	_cleanup_ui()
	_save_battle_results()
	_determine_battle_outcome()

func _cleanup_ui() -> void:
	if actions_show and actions_show.get_parent():
		camera.remove_child(actions_show)

func _save_battle_results() -> void:
	var party_data = party.map(func(player: Player): return player.export())
	save_functions.save_characters(party_data)

func _determine_battle_outcome() -> void:
	if enemies.size() == 0:
		current_state = BattleState.BATTLE_WON
		# Add victory logic here
	else:
		current_state = BattleState.BATTLE_LOST
		# Add defeat logic here
#endregion

#region Player Actions
func _execute_player_action(player: Player) -> void:
	print("Processing turn for: %s" % player.player_name)
	
	var original_position = player.position
	var action_position = _calculate_action_position()
	
	await _move_player_to_action_position(player, action_position)
	var action_data = await _get_player_action(player)
	await _process_player_action(player, action_data)
	await _move_player_back(player, original_position)

func _calculate_action_position() -> Vector2:
	return Vector2(enemy_group.position.x + player_group.position.x, 0)

func _move_player_to_action_position(player: Player, position: Vector2) -> void:
	await _animate_node_movement(player, position, true)

func _move_player_back(player: Player, position: Vector2) -> void:
	await _animate_node_movement(player, position, false)

func _get_player_action(player: Player) -> Dictionary:
	var battle_ui = battle_ui_scene.instantiate() as BattleUi
	player.add_child(battle_ui)
	
	var available_enemies = _get_available_enemies()
	battle_ui.enemies_available = available_enemies
	
	var action_data = await battle_ui.action_chosen
	
	player.remove_child(battle_ui)
	battle_ui.queue_free()
	
	return action_data

func _get_available_enemies() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for enemy in enemies.filter(func(e): return e.is_alive()):
		available.append({
			"name": enemy.name,
			"id": enemies.find(enemy)
		})
	return available

func _process_player_action(player: Player, action_data: Dictionary) -> void:
	var action_type = action_data.get("action_type", "attack")
	
	match action_type:
		"attack":
			await _process_attack_action(player, action_data)
		"item":
			await _process_item_action(player, action_data)
		_:
			push_warning("Unknown action type: %s" % action_type)

func _process_attack_action(player: Player, action_data: Dictionary) -> void:
	var attack_id = action_data.get("attack_id", 0)
	var damage = player.get_attack_damage(attack_id)
	var target_enemy_ids = action_data.get("enemies", [])
	
	for enemy_id in target_enemy_ids:
		if enemy_id < enemies.size():
			await _damage_enemy(enemies[enemy_id], damage)

func _process_item_action(player: Player, action_data: Dictionary) -> void:
	var item_name = action_data.get("item_name", "Unknown Item")
	print("%s used item: %s" % [player.player_name, item_name])
	
	# Add visual feedback for item usage
	await _show_item_usage_feedback(player, item_name)
	
	# Item effects are already applied in the UI when the item is used
	# No additional processing needed here since the Player class handles the effects

func _show_item_usage_feedback(player: Player, item_name: String) -> void:
	# Create a temporary label to show item usage
	var feedback_label = RichTextLabel.new()
	feedback_label.bbcode_enabled = true
	feedback_label.text = "[font_size=24][color=GREEN]Used %s![/color][/font_size]" % item_name
	feedback_label.size = Vector2(200, 50)
	feedback_label.position = Vector2(-100, -150)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	player.add_child(feedback_label)
	
	# Animate the feedback
	var tween = create_tween()
	tween.parallel().tween_property(feedback_label, "modulate:a", 0.0, 1.5)
	tween.parallel().tween_property(feedback_label, "position:y", feedback_label.position.y - 50, 1.5)
	
	await tween.finished
	
	# Clean up
	if is_instance_valid(feedback_label):
		player.remove_child(feedback_label)
		feedback_label.queue_free()

func _damage_enemy(enemy: Enemy, damage: int) -> void:
	await enemy.got_hurt(damage)
	if enemy.is_dead():
		_handle_enemy_death(enemy)

func _handle_enemy_death(enemy: Enemy) -> void:
	# Additional death handling logic can be added here
	pass
#endregion

#region Enemy Actions
func _execute_enemy_action(enemy: Enemy) -> void:
	print("Processing turn for: %s" % enemy.enemy_name)
	
	await get_tree().create_timer(TURN_DELAY).timeout
	
	if party.is_empty():
		return
	
	var target = _select_enemy_target()
	await _perform_enemy_attack(enemy, target)

func _select_enemy_target() -> Player:
	return party[randi_range(0, party.size() - 1)]

func _perform_enemy_attack(enemy: Enemy, target: Player) -> void:
	var damage = enemy.get_damage()
	await target.got_hurt(damage)
	
	if target.is_dead():
		_handle_player_death(target)

func _handle_player_death(player: Player) -> void:
	# Additional death handling logic can be added here
	pass
#endregion

#region Positioning
func _position_player(player: Player, index: int) -> void:
	var positions = [
		Vector2(-150, 0),
		Vector2(150, 200),
		Vector2(-150, 400),
		Vector2(150, 600)
	]
	
	if index < positions.size():
		player.position = positions[index]

func _position_enemy(enemy: Enemy, index: int) -> void:
	var positions = [
		Vector2(0, 0),
		Vector2(-300, 200),
		Vector2(0, 400),
		Vector2(-300, 600)
	]
	
	if index < positions.size():
		enemy.position = positions[index]
#endregion

#region Animation Helpers
func _animate_camera_zoom(target_camera: Camera2D, zoom_level: float) -> void:
	var tween = create_tween()
	tween.tween_property(target_camera, "zoom", Vector2(zoom_level, zoom_level), CAMERA_ZOOM_DURATION)

func _animate_node_movement(node: Node2D, target_position: Vector2, use_global: bool) -> void:
	var tween = create_tween()
	var property = "global_position" if use_global else "position"
	tween.tween_property(node, property, target_position, MOVEMENT_DURATION)
	await tween.finished
#endregion
