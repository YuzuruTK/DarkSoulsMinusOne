extends Node2D
class_name BattleUi

# Enums for better state management
enum GameState {
	NONE,
	MENU_MAIN,
	SELECT_SKILL,
	SELECT_ENEMY,
	MENU_ITEM,
	END_TURN
}

# Constants
const BUTTON_SPACING_RATIO = 2.0

# State management
var current_state: GameState = GameState.MENU_MAIN
var selected_attack_id: int = -1
var selected_enemies: Array[String] = []
var selected_item_id: String = ""

# UI Components
var active_buttons: Array[Button] = []

# References
@onready var player: Player = get_parent() as Player
@onready var sprite: Sprite2D = player.get_node("Sprite") if player else null

# Data
var enemies_available: Array[Dictionary] = []

# Signals
signal action_chosen(action_data: Dictionary)

#region Godot Lifecycle
func _ready() -> void:
	if not player:
		push_error("BattleUi must be a child of a Player node")
		return
	
	_validate_setup()

func _process(_delta: float) -> void:
	_handle_current_state()

func _validate_setup() -> void:
	if not sprite:
		push_warning("Sprite not found in player node")
#endregion

#region State Management
func _handle_current_state() -> void:
	match current_state:
		GameState.NONE:
			return
		GameState.MENU_MAIN:
			_show_main_menu()
		GameState.SELECT_SKILL:
			_show_skill_menu()
		GameState.SELECT_ENEMY:
			_show_enemy_selection()
		GameState.MENU_ITEM:
			_show_item_menu()
		GameState.END_TURN:
			_end_turn()

func _change_state(new_state: GameState) -> void:
	current_state = new_state

func _show_main_menu() -> void:
	_clear_all_buttons()
	active_buttons = _create_main_menu_buttons()
	_position_buttons_around_sprite(active_buttons)
	_change_state(GameState.NONE)

func _show_skill_menu() -> void:
	_clear_all_buttons()
	active_buttons = _create_skill_buttons()
	_position_buttons_around_sprite(active_buttons)
	_change_state(GameState.NONE)

func _show_enemy_selection() -> void:
	_clear_all_buttons()
	active_buttons = _create_enemy_selection_buttons()
	_position_buttons_around_sprite(active_buttons)
	_change_state(GameState.NONE)

func _show_item_menu() -> void:
	_clear_all_buttons()
	active_buttons = _create_item_buttons()
	_position_buttons_around_sprite(active_buttons)
	_change_state(GameState.NONE)

func _end_turn() -> void:
	_clear_all_buttons()
	_change_state(GameState.NONE)
#endregion

#region Button Management
func _clear_all_buttons() -> void:
	for button in active_buttons:
		if is_instance_valid(button) and button.get_parent() == self:
			remove_child(button)
			button.queue_free()
	active_buttons.clear()

func _create_main_menu_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	
	var button_configs = [
		{
			"text": "Atacar",
			"action": func(): _on_attack_selected()
		},
		{
			"text": "Habilidades",
			"action": func(): _change_state(GameState.SELECT_SKILL)
		},
		{
			"text": "Itens",
			"action": func(): _change_state(GameState.MENU_ITEM)
		}
	]
	
	for config in button_configs:
		var button = _create_button(config.text, config.action)
		buttons.append(button)
	
	return buttons

func _create_skill_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	
	# Back button
	var back_button = _create_button("Voltar", func(): _change_state(GameState.MENU_MAIN))
	buttons.append(back_button)
	
	# Skill buttons
	var player_skills = player.get_skills()
	for skill in player_skills:
		var button = _create_button(skill.name, func(): _on_skill_selected(skill))
		buttons.append(button)
	
	return buttons

func _create_enemy_selection_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	
	# Back button
	var back_button = _create_button("Voltar", func(): _change_state(GameState.MENU_MAIN))
	buttons.append(back_button)
	
	# Enemy buttons
	for enemy in enemies_available:
		var unique_name = get_unique_enemy_name(enemy.name, buttons)
		var button = _create_button(unique_name, func(): _on_enemy_selected(enemy))
		buttons.append(button)
	
	return buttons

func _create_item_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	
	# Back button
	var back_button = _create_button("Voltar", func(): _change_state(GameState.MENU_MAIN))
	buttons.append(back_button)
	
	# Item buttons - only show items with quantity > 0
	var available_items = player.get_available_items()
	
	if available_items.is_empty():
		# No items available
		var no_items_button = _create_button("Sem itens disponíveis", func(): pass)
		no_items_button.disabled = true
		buttons.append(no_items_button)
	else:
		for item in available_items:
			var button_text = "%s (%d)" % [item.name, item.quantity]
			var button = _create_button(button_text, func(): _on_item_selected(item))
			buttons.append(button)
	
	return buttons
	
func get_unique_enemy_name(base_name: String, buttons) -> String:
	var existing_names = []
	
	# Collect all existing button names
	for button in buttons:
		existing_names.append(button.text)
	
	# If the base name doesn't exist, return it as is
	if base_name not in existing_names:
		return base_name
	
	# Find the next available number
	var counter = 2
	var unique_name = base_name + " " + str(counter)
	
	while unique_name in existing_names:
		counter += 1
		unique_name = base_name + " " + str(counter)
	
	return unique_name

func _create_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.pressed.connect(callback)
	add_child(button)
	return button
#endregion

#region Button Actions
func _on_attack_selected() -> void:
	selected_attack_id = 0 # Basic attack
	_change_state(GameState.SELECT_ENEMY)

func _on_skill_selected(skill: Dictionary) -> void:
	selected_attack_id = skill.id
	
	if skill.is_multi_target:
		# Multi-target skill affects all enemies
		var all_enemy_ids = enemies_available.map(func(enemy): return enemy.id)
		_emit_action_chosen(all_enemy_ids)
	else:
		# Single-target skill requires enemy selection
		_change_state(GameState.SELECT_ENEMY)

func _on_enemy_selected(enemy: Dictionary) -> void:
	_emit_action_chosen([enemy.id])

func _on_item_selected(item: Dictionary) -> void:
	selected_item_id = item.id
	
	# Use the item immediately
	if player.use_item(selected_item_id):
		print("Used item: %s" % item.name)
		# Emit action with item usage
		var action_data = {
			"action_type": "item",
			"item_id": selected_item_id,
			"item_name": item.name
		}
		action_chosen.emit(action_data)
		_change_state(GameState.END_TURN)
	else:
		push_warning("Failed to use item: %s" % item.name)
		# Go back to item menu if item usage failed
		_change_state(GameState.MENU_ITEM)

func _emit_action_chosen(enemy_ids: Array) -> void:
	var action_data = {
		"action_type": "attack",
		"enemies": enemy_ids,
		"attack_id": selected_attack_id
	}
	action_chosen.emit(action_data)
	_change_state(GameState.END_TURN)
#endregion

#region UI Positioning
func _position_buttons_around_sprite(buttons: Array[Button]) -> void:
	if not sprite or buttons.is_empty():
		return
	
	var sprite_size = _get_sprite_display_size()
	var button_count = buttons.size()
	
	# Make even number for symmetric positioning
	var positioning_count = button_count if button_count % 2 == 0 else button_count + 1
	
	var button_size = _calculate_button_size(sprite_size, positioning_count)
	var positions = _calculate_button_positions(sprite_size, button_size, button_count)
	
	for i in range(buttons.size()):
		var button = buttons[i]
		button.size = button_size
		button.position = positions[i]

func _get_sprite_display_size() -> Vector2:
	if not sprite or not sprite.texture:
		return Vector2(100, 100) # Fallback size
	
	var texture_size = sprite.texture.get_size()
	return texture_size * sprite.scale

func _calculate_button_size(sprite_size: Vector2, button_count: int) -> Vector2:
	var magic_number = (button_count / 2) + 1
	var vertical_size = sprite_size.y / magic_number
	var horizontal_size = sprite_size.y
	
	return Vector2(horizontal_size, vertical_size)

func _calculate_button_positions(sprite_size: Vector2, button_size: Vector2, button_count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var magic_number = (button_count / 2) + 1 if button_count % 2 == 0 else ((button_count + 1) / 2) + 1
	var vertical_spacing = button_size.y / magic_number
	var current_height = - (sprite_size.y / 2) + vertical_spacing
	
	for i in range(button_count):
		var position: Vector2
		
		if i % 2 != 0: # Right side
			position = Vector2(sprite_size.x / 2, current_height)
			current_height += button_size.y + vertical_spacing
		else: # Left side
			position = Vector2(- ((sprite_size.x / 2) + button_size.x), current_height)
		
		positions.append(position)
	
	return positions
#endregion
