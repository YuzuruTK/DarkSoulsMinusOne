extends Control

@export var text: String:
	set(value):
		text = value
		_on_text_changed()
		
@export var font: Font
@export var font_size: int = 24
@export var font_color = Color.WHITE
@export var outline_size: int = 15

signal faded_out

func _fade_out():
	var to_modulate = self.modulate
	to_modulate.a = 0
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", to_modulate, 0.5).set_delay(0.2)
	tween.finished.connect(func(): emit_signal("faded_out"))
	tween.finished.connect(func(): get_parent().remove_child(self))

func _animate_jumping():
	var tween: Tween
	var i = 0
	for child in $CharacterContainer.get_children():
		tween = create_tween()
		var label = child as Label
		var original_position = label.position
		
		# Ignore spaces
		if label.text == ' ':
			continue

		# Move up 10px
		tween.tween_property(label, "position:y", original_position.y - 10, 0.2).set_delay(i * 0.05)
		# Move back down
		tween.tween_property(label, "position:y", original_position.y, 0.2)#.set_delay(0.3)
		
		i += 1
	
	# Connect the last tween to play the fading animation once it finishes 
	# tween.finished.connect(func(): get_parent().remove_child(self))
	tween.finished.connect(func(): _fade_out())

func _ready():
	_on_text_changed()
	_animate_jumping()
		
func _clear_characters():
	for child in $CharacterContainer.get_children():
		$CharacterContainer.remove_child(child)

func _calc_label_size(label: Label) -> Vector2:
	var label_font := label.get_theme_font("font")
	var label_font_size := label.get_theme_font_size("font_size")
	return label_font.get_string_size(
		label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size
	)

var width

func _on_text_changed():
	_clear_characters()
	
	var w = 0
	for c in text:
		var label = Label.new()
		label.text = c
		
		# Set label font
		if font:
			label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", font_size)
		
		label.label_settings = LabelSettings.new()
		label.label_settings.font_size = font_size
		label.label_settings.font_color = font_color
		label.label_settings.outline_size = outline_size
		label.label_settings.outline_color = Color.BLACK
		
		# Position label
		var label_size = _calc_label_size(label)
		label.position.x = position.x + w
		w += label_size.x
		
		$CharacterContainer.add_child(label)
	
	width = w

# var tween: Tween

func get_width():
	return width

func _process(delta: float) -> void:
	pass
