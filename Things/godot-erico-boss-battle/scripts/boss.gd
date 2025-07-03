extends Node2D

# signal on_killed

@onready var EnglishAlphabet = $".."/EnglishAlphabet

var start_text_pos: Vector2

var flash_on_hit_tween: Tween
func flash_hit():
	$"."/Erico.modulate = Color.DARK_RED
	if flash_on_hit_tween and flash_on_hit_tween.is_running():
		flash_on_hit_tween.stop()
	flash_on_hit_tween = create_tween()
	flash_on_hit_tween.tween_property($"."/Erico, "modulate", Color.WHITE, 1)

func _play_squish_animation(amount = 0.05, flip: bool = true):
	var tween = create_tween()
	tween.set_parallel(true)
	#tween.tween_property(
		#$Erico as Sprite2D, 
		#"skew", 
		#$Erico.skew + amount if flip else $Erico.skew - amount, 
		#1
	#) # .set_delay(0.5)
	tween.tween_property(
		$Erico as Sprite2D, 
		"scale:y", 
		$Erico.scale.y - amount if flip else $Erico.scale.y + amount, 
		1
	).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func(): _play_squish_animation(amount, not flip))

func _ready() -> void:
	start_text_pos = $ProjectileText.position
	_play_squish_animation(0.03)
	# flash_on_hit_tween.tween_property($"."/Erico, "modulate", Color.WHITE, 1)

func _spit_last_char():
	var char: Label = $ProjectileText/CharacterContainer.get_children()[-1]
	var char_pos = char.position
	char.position += Vector2(50, -60)
	var tween = create_tween()
	tween.tween_property(char, "position", char_pos, 0.3)
	tween.tween_property(char, "modulate", char.modulate, 0.3)
	char.modulate = char.modulate * Color(1, 1, 1, 0.5)
	# await tween.finished
	return tween

func _play_spit_sound():
	if $Spit.playing:
		$Spit.stop()
	$Spit.play()

func type_slowly(text: String):
	var i = 0
	var start_pos = $ProjectileText.position
	while i < text.length():
		$ProjectileText.text += text[i]
		$ProjectileText.position.x = start_pos.x - $ProjectileText.width / 2
		
		# await _spit_last_char().finished
		_play_spit_sound()
		_spit_last_char()
		await get_tree().create_timer(randf_range(0.1, 0.3)).timeout
		
		i += 1

func _on_rarity_label_fade_out():
	$ProjectileText.shoot_characters($Target.position)

var current_word = ""

func start_turn(last_text: String):
	var my_word = ""
	while true:
		my_word = EnglishAlphabet.random_word(last_text[-1])
		if not my_word:
			my_word = EnglishAlphabet.random_word()
			
		await type_slowly(my_word)
		
		if my_word not in $"..".used_words:
			break
	
	await get_tree().create_timer(0.3).timeout
	
	current_word = my_word
	
	var rarity = EnglishAlphabet.find_word_rarity(my_word)
	$".."/Player._spawn_rarity_label(rarity, _on_rarity_label_fade_out)
	
	$".."/Figure.play_rarity_sound(rarity)
	
func end_turn():
	$ProjectileText.text = "" # $ProjectileText._clear_characters()
	# $ProjectileTextEdit/ProjectileText.reset()
	var shake = $ProjectileText.CharAnimations.Shake
	$ProjectileText.current_animation = shake
	$ProjectileText.position = start_text_pos
	
var elapsed: float
func _process(delta: float) -> void:
	elapsed += delta
