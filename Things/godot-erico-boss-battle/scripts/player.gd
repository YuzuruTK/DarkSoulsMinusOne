extends Node2D

var jumpy_text = preload("res://Things/godot-erico-boss-battle/scenes/jumpy_text.tscn")
@onready var EnglishAlphabet = $".."/EnglishAlphabet
var my_turn = true

func _play_squish_animation(amount = 0.05, flip: bool = true):
	var tween = create_tween()
	# tween.set_parallel(true)
	#tween.tween_property(
		#$Erico as Sprite2D, 
		#"skew", 
		#$Erico.skew + amount if flip else $Erico.skew - amount, 
		#1
	#) # .set_delay(0.5)
	tween.tween_property(
		$Sprite2D as Sprite2D, 
		"scale:y", 
		$Sprite2D.scale.y - amount if flip else $Sprite2D.scale.y + amount, 
		1
	) # .set_delay(0.5)
	tween.finished.connect(func(): _play_squish_animation(amount, not flip))

func _ready() -> void:
	# _play_squish_animation()
	$ProjectileTextEdit/LineEdit.text_changed.connect(
		func(new_text): 
			if my_turn: 
				$ProjectileTextEdit/Keystroke.play()
				$Sprite2D.rotation_degrees = randf_range(-5, 5)
	)

var flash_on_hit_tween: Tween
func flash_hit():
	$Sprite2D.modulate = Color.DARK_RED
	if flash_on_hit_tween and flash_on_hit_tween.is_running():
		flash_on_hit_tween.stop()
	flash_on_hit_tween = create_tween()
	flash_on_hit_tween.tween_property($Sprite2D, "modulate", Color.WHITE, 1)

func _on_rarity_label_fade_out():
	$ProjectileTextEdit/ProjectileText.shoot_characters($Target.position - $ProjectileTextEdit.position, true)

func _spawn_rarity_label(rarity, on_fade_out):
	var rarity_jumpy_text = jumpy_text.instantiate()
	rarity_jumpy_text.z_index = 5
	rarity_jumpy_text.text = EnglishAlphabet.rarity_texts[rarity]
	rarity_jumpy_text.font_color = EnglishAlphabet.rarity_colors[rarity]
	# rarity_jumpy_text.position.x /= 2  # TODO: ??????
	# rarity_jumpy_text.position.x -= rarity_jumpy_text.get_width() / 2
	rarity_jumpy_text.faded_out.connect(on_fade_out)
	add_child(rarity_jumpy_text)
	
	# TODO: Omg, I must set position after adding the child...
	rarity_jumpy_text.position = $Rarity.position
	rarity_jumpy_text.position.x -= rarity_jumpy_text.get_width() / 2

var current_word = ""

func _on_projectile_text_edit_text_submitted(new_text: String) -> void:
	new_text = new_text.to_lower()
	var is_correct = new_text and ($"..".used_words.size() == 0 or new_text[0] == $"..".used_words[-1][-1])
	if new_text and EnglishAlphabet.is_word_valid(new_text) and new_text not in $"..".used_words and is_correct:
		$".."/Stopwatch.running = false
		$ProjectileTextEdit.toggle_interactable()
		var rarity = EnglishAlphabet.find_word_rarity(new_text.to_lower())
		_spawn_rarity_label(rarity, _on_rarity_label_fade_out)
		$".."/Figure.play_rarity_sound(rarity)
		current_word = new_text
		# $".."/Bubble.move_down()
	else:
		$ProjectileTextEdit.flash_invalid_text()
		$ProjectileTextEdit/Error.play()
		return
		
func start_turn(last_text: String):
	my_turn = true
	$ProjectileTextEdit.toggle_interactable()
	
	$".."/Stopwatch.reset()
	$".."/Stopwatch.running = true
	
	$".."/Bubble.state = $".."/Bubble.BubbleState.LETTER
	$".."/Bubble.letter = last_text[-1]
	# $".."/Bubble.move_up()
	$".."/Bubble.update_bubble()
	
func end_turn():
	my_turn = false
	$ProjectileTextEdit/LineEdit.clear()
	# $ProjectileTextEdit/ProjectileText.reset()
	var shake = $ProjectileTextEdit/ProjectileText.CharAnimations.Shake
	$ProjectileTextEdit/ProjectileText.current_animation = shake
	# $ProjectileTextEdit.toggle_interactable()
	
func _draw() -> void:
	pass # draw_circle($Target.position, 50.0, Color(1, 0, 0, 0.5))
