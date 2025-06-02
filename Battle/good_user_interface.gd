extends Node2D
class_name  BattleUi

enum GameStates {NONE, MENU_MAIN, END_TURN, SELECT_SKILL, MENU_ITEM, SELECT_ENEMY}
var state = GameStates.MENU_MAIN
var attack_id: int
var enemy_selected: Array[String] = []
var buttons: Array[Button] = []
@onready var player: Player = $".."
@onready var sprite: Sprite2D = $".."/Sprite
@onready var enemies_available: Array[Dictionary] = []
signal action_chosen(action_data)

func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if state == GameStates.NONE:
		pass
	elif state == GameStates.END_TURN:
		delete_all_buttons()
		state = GameStates.NONE
		pass
	elif state == GameStates.MENU_MAIN:
		# remove all other buttons
		delete_all_buttons()
		# get the list of main buttons
		buttons = create_main_buttons()
		# position the buttons
		position_buttons_around_character(buttons, sprite)
		state = GameStates.NONE
		pass
	elif state == GameStates.SELECT_SKILL:
		delete_all_buttons()
		# create the attack buttons
		buttons = create_attack_buttons()
		# position the buttons
		position_buttons_around_character(buttons, sprite)
		state = GameStates.NONE
		pass
	elif state == GameStates.SELECT_ENEMY:
		delete_all_buttons()
		# create the attack buttons
		buttons = create_enemy_selection_buttons()
		# position the buttons
		position_buttons_around_character(buttons, sprite)
		state = GameStates.NONE
	pass
func delete_all_buttons() -> void:
	# remove all other buttons
	for button in buttons:
			$".".remove_child(button)
	pass

# Single Selection
func create_enemy_selection_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	var back_button = Button.new()
	back_button.text = "voltar"
	back_button.connect("pressed", func(): state = GameStates.MENU_MAIN)
	$".".add_child(back_button)
	buttons.append(back_button)
	for enemy in enemies_available:
		var button = Button.new()
		button.text = enemy.name
		button.connect("pressed", func(): emit_signal("action_chosen", {"enemies" : [enemy.id], "attack_id" : attack_id}); state = GameStates.END_TURN)
		$".".add_child(button)
		buttons.append(button)
	return buttons
func create_main_buttons() -> Array[Button]:
	# Create the list of buttons
	var buttons: Array[Button] = []	
	# Preset of buttons 
	var preset_buttons = [{
		"name" : "Atacar",
		"action" : func(): state = GameStates.SELECT_ENEMY; attack_id = 0
	},
	{
		"name" : "Habilidades",
		"action" : func(): state = GameStates.SELECT_SKILL
	},
	{
		"name" : "Itens",
		"action" : func(): state = GameStates.MENU_ITEM
	}
	]
	# Creates the buttons based on preset
	for preset in preset_buttons:
		var button = Button.new()
		button.text = preset["name"]
		# Sets a Lambda Function that changes the state of game
		button.connect("pressed", preset["action"])
		# add the button to player node
		$".".add_child(button)
		# add the button to buttons list to return
		buttons.append(button)
	return buttons

func create_attack_buttons() -> Array[Button]:
	# Create a set of buttons with these names
	var buttons: Array[Button] = []
	# Generate the button using the buttons name
	var skills: Array[Dictionary] = []
	skills.insert(0, {"name": "voltar", "action": func(): state = GameStates.MENU_MAIN})
	skills.append_array(player.get_skills())
	skills.remove_at(1)
	for skill in skills:
		var button = Button.new()
		button.text = skill["name"]
		$".".add_child(button)
		button.connect(
			"pressed", skill["action"]
			if skill.has("action")
			else func(): emit_signal("action_chosen", {"enemies" : enemies_available.map(func(enemy): return enemy.id), "attack_id" : skill.id}); state = GameStates.END_TURN if skill["is_multi_target"] else func(): state = GameStates.SELECT_ENEMY; attack_id = skill.id
		)
		buttons.append(button)
	return buttons

# Function to dinamically place and resize the buttons depending of the size of array
func position_buttons_around_character(buttons: Array[Button], sprite: Sprite2D) -> void:
	# Getting the size of texture
	var sprite_x_size = sprite.texture.get_size()[0] * sprite.scale[0]
	var sprite_y_size = sprite.texture.get_size()[1] * sprite.scale[1]
	var number_of_buttons = len(buttons) if len(buttons) % 2 == 0 else len(buttons) + 1
		# Making the size of the buttons acceptable
	var magic_number = (number_of_buttons/ 2) + 1
	var vertical_size = sprite_y_size / magic_number
	var horizontal_size = sprite_y_size
	var actual_height = -(sprite_y_size/2) + (vertical_size/magic_number)
	for i in range(len(buttons)):
		# Talvez sette a Anchor, não descobri
		#buttons[i].set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		buttons[i].size = Vector2(horizontal_size, vertical_size)
		# Positioning the act button right after the texture
		if (i % 2) != 0:
			buttons[i].position = Vector2(sprite_x_size / 2, actual_height)
			#buttons[i].rotation = -0.25
			actual_height = actual_height + vertical_size + (vertical_size/magic_number)
		else: 
			buttons[i].position = Vector2(-(((sprite_x_size) / 2) + horizontal_size), actual_height)
			#buttons[i].rotation = 0.25
	pass
