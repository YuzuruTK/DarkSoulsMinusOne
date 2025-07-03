extends Control

signal text_submitted(new_text: String)
signal character_shot(character: Label)
signal characters_shot

@export var target: Vector2

# TODO: Kinda sad having to do it this way...
var start_position

# TODO: This is a hacky solution... Maybe I should just 
#       implement my own input handling...
func _hide_line_edit():
	var style = StyleBoxEmpty.new()
	$LineEdit.add_theme_stylebox_override("normal", style)
	$LineEdit.add_theme_stylebox_override("focus", style)
	$LineEdit.add_theme_stylebox_override("hover", style)
	$LineEdit.modulate.a = 0

func _ready() -> void:
	start_position = position
	_hide_line_edit()
	$LineEdit.grab_focus()
	$LineEdit.text_submitted.connect(func(new_text: String): emit_signal("text_submitted", new_text))
	$ProjectileText.character_shot.connect(func(c): emit_signal("character_shot", c))
	$ProjectileText.characters_shot.connect(func(): emit_signal("characters_shot"))

func _on_line_edit_text_changed(new_text: String) -> void:
	$ProjectileText.text = new_text
	position.x = start_position.x - $ProjectileText.width / 2

func toggle_interactable():
	if $LineEdit.has_focus(): 
		$LineEdit.release_focus() 
	else: 
		$LineEdit.grab_focus()
	$LineEdit.visible = !$LineEdit.visible

# Flashes the text in red to show it is invalid
func flash_invalid_text():
	for child in $ProjectileText/CharacterContainer.get_children():
		var label = child as Label
		
		var start_modulation = label.modulate
		label.modulate = Color.RED
		
		var tween = create_tween()
		tween.tween_property(label, "modulate", start_modulation, 1)

func _on_line_edit_text_submitted(new_text: String) -> void:
	pass
	# Disable LineEdit until everything unfolds
	# $LineEdit.visible = false
	
	# var mouse_pos = get_viewport().get_mouse_position()
	# $ProjectileText.shoot_characters(mouse_pos - position, true)
