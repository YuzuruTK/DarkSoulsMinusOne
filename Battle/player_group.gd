extends Node

var state = "menu"
var buttons: Array[Button]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buttons = create_main_buttons()
	position_buttons_around_character(buttons)
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if state == "main":
		for button in buttons:
			$Player.remove_child(button)
		buttons = create_main_buttons()
		position_buttons_around_character(buttons)			
	if state == "attack_selection":
		for button in buttons:
			$Player.remove_child(button)
		buttons = create_attack_buttons()
		position_buttons_around_character(buttons)
		state = "none"
		pass
	pass

func create_main_buttons() -> Array[Button]:
	var buttons: Array[Button] = []	
	var act_button = Button.new()
	act_button.text = "Act"
	act_button.connect("pressed", func(): state = "attack_selection")
	$Player.add_child(act_button)
	buttons.append(act_button)
	return buttons

func create_attack_buttons() -> Array[Button]:
	var buttons_name = ["voltar","1","2","3","4"]
	var buttons: Array[Button] = []
	for button_name in buttons_name:
		var button = Button.new()
		button.text = button_name
		$Player.add_child(button)
		buttons.append(button)
	buttons[0].connect("pressed", func(): state = "main")
	return buttons

func position_buttons_around_character(buttons: Array[Button]) -> void:
	# Getting the size of texture
	var sprite_x_size = $Player/Sprite2D.texture.get_size()[0] * $Player/Sprite2D.scale[0]
	var sprite_y_size = $Player/Sprite2D.texture.get_size()[1] * $Player/Sprite2D.scale[1]
	var number_of_buttons = len(buttons) if len(buttons) % 2 == 0 else len(buttons) + 1
		# Making the size of the buttons acceptable
	var magic_number = (number_of_buttons/ 2) + 1
	var vertical_size = sprite_y_size / ((number_of_buttons / 2) + 1)
	var horizontal_size = sprite_y_size
	var actual_height = -(sprite_y_size/2) + (vertical_size/magic_number)
	for i in range(len(buttons)):
		buttons[i].size = Vector2(horizontal_size, vertical_size)
		# Positioning the act button right after the texture
		if (i % 2) != 0:
			buttons[i].position = Vector2(sprite_x_size / 2, actual_height)
			actual_height = actual_height + vertical_size + (vertical_size/magic_number)
		else: 
			buttons[i].position = Vector2(-(((sprite_x_size) / 2) + horizontal_size), actual_height)
	pass
