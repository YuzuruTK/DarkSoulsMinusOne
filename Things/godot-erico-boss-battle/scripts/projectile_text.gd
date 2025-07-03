extends Control

# Treggered when a single character tween ends
signal character_shot(character: Label)

# Triggered when all characters tweens ends
signal characters_shot

@export var text: String:
	set(value):
		text = value
		_on_text_changed()
		
@export var font: Font
@export var font_size: int = 24
@export var font_color: Color = Color.WHITE
@export var outline_size: int = 15

@export var scatter_radius: float = 50.0
		
func _ready():
	_on_text_changed()
		
func _clear_characters():
	for child in $CharacterContainer.get_children():
		$CharacterContainer.remove_child(child)

func _calc_label_size(label: Label) -> Vector2:
	var label_font := label.get_theme_font("font")
	var label_font_size := label.get_theme_font_size("font_size")
	return label_font.get_string_size(
		label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size
	)

var char_properties: Array[Dictionary]
var width

func _on_text_changed():
	_clear_characters()
	char_properties.clear()
	
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
		label.pivot_offset = label_size / 2
		w += label_size.x
		
		# Set properties
		char_properties.append({
			"start_pos": label.position
		})
		
		$CharacterContainer.add_child(label)
	
	width = w

var rng := RandomNumberGenerator.new()

func _shake_position(pos: Vector2, max: int = 2) -> Vector2:
	return Vector2(
		pos.x + rng.randf_range(-1.0, 1.0) * max,
		pos.y + rng.randf_range(-1.0, 1.0) * max,
	)

func _shake_characters():
	var i = 0
	for child in $CharacterContainer.get_children():
		var start_pos = char_properties[i]["start_pos"]
		var new_pos = _shake_position(start_pos)
		(child as Label).position = new_pos
		i += 1

func _rotate_characters(delta):
	const rotation_speed = deg_to_rad(360.0)
	for child in $CharacterContainer.get_children():
		child.rotation += rotation_speed * (delta * 2)

enum CharAnimations {
	None, Shake, Rotate
}

var current_animation = CharAnimations.Shake
var elapsed_time: float = 0.0

func _process(delta):
	if current_animation == CharAnimations.Shake:
		if elapsed_time > 0.05:
			_shake_characters()
			elapsed_time = 0.0
	elif current_animation == CharAnimations.Rotate:
		_rotate_characters(delta)
	
	elapsed_time += delta

func _input(event):
	pass 
	# if event is InputEventMouseButton and event.pressed:
		# if event.button_index == MOUSE_BUTTON_LEFT:
			# current_animation = CharAnimations.Rotate
			# shoot_characters(event.position)

func _scatter_position(position: Vector2, radius := scatter_radius) -> Vector2:
	var angle = randf() * TAU  # TAU = 2 * PI
	var distance = sqrt(randf()) * radius  # sqrt for uniform distribution in circle
	var offset = Vector2(cos(angle), sin(angle)) * distance
	return position + offset

func _shoot_character(char: Label, at: Vector2, delay: float):
	var tween = create_tween()
	tween.tween_property(char, "position", _scatter_position(at - position), 1.0) \
		# .set_delay(i * 0.25) \
		.set_delay(delay) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)
	return tween

var characters_shot_count = 0
func _on_character_shot(character: Label):
	characters_shot_count += 1
	emit_signal("character_shot", character)
	# print(characters_shot_count, " ", character.text)
	if characters_shot_count == text.length():
		characters_shot_count = 0
		emit_signal("characters_shot")

func shoot_characters(at: Vector2, reversed = false):
	current_animation = CharAnimations.Rotate
	
	var children = $CharacterContainer.get_children()
	if reversed: children.reverse()
	
	var tween: Tween
	
	var i = 2 # Start with some delay
	for child in children:
		# add_fire_particles(child as Label)
		tween = _shoot_character(
			child as Label, 
			at,
			i * rng.randf_range(0.1, 0.25)
		)
		tween.finished.connect(func(): _on_character_shot(child as Label))
		i += 1
	
	# if tween:
		# tween.finished.connect(func(): emit_signal("characters_shot"))
