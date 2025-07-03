extends Node2D

signal won
signal lost

signal onresult(string)

var used_words: Array[String] = []

func _play_explosion_sound():
	if $Explosion.playing:
		$Explosion.stop()
	$Explosion.play()
	
var particle_scene = preload("res://Things/godot-erico-boss-battle/scenes/explosion_particles.tscn")
func _spawn_explosion_particles(pos: Vector2):
	var particle_instance = particle_scene.instantiate()
	add_child(particle_instance)
	particle_instance.global_position = pos
	
	# Start emitting (usually auto if one_shot is true)
	particle_instance.emitting = true

	# Optional: Queue free after lifetime if needed
	var lifetime = particle_instance.lifetime
	await get_tree().create_timer(lifetime).timeout
	particle_instance.queue_free()

func _on_player_projectile_text_edit_character_shot(character: Label) -> void:
	character.visible = false
	_play_explosion_sound()
	_spawn_explosion_particles(character.global_position)
	$Boss.flash_hit()
	
	var word = $Player.current_word
	var rarity = $EnglishAlphabet.find_word_rarity(word)
	var damage = $EnglishAlphabet.rarity_multipliers[rarity]
	$Boss/HealthBar.deal_damage(damage)

func _on_player_projectile_text_edit_characters_shot() -> void:
	var last_text = $Player/ProjectileTextEdit/LineEdit.text
	last_text = last_text.to_lower()
	used_words.append(last_text)
	
	await $Boss/HealthBar.commit_damage()
	if $Boss/HealthBar/OverBar.value <= 0:
		_on_win()
		return
	
	$Player.end_turn()
	$Boss.start_turn(last_text)

func _on_boss_projectile_text_character_shot(character: Label) -> void:
	character.visible = false
	_play_explosion_sound()
	_spawn_explosion_particles(character.global_position)
	$Player.flash_hit()
	
	var word = $Boss.current_word
	var rarity = $EnglishAlphabet.find_word_rarity(word)
	var damage = $EnglishAlphabet.rarity_multipliers[rarity]
	$Player/HealthBar.deal_damage(damage)

func _on_boss_projectile_text_characters_shot() -> void:
	var last_text = $Boss/ProjectileText.text
	used_words.append(last_text)
	
	var v = $Player/HealthBar.commit_damage() # await $Player/HealthBar.commit_damage()
	if $Player/HealthBar/OverBar.value <= 0:
		await v
		_on_lose()
		return
	
	$Boss.end_turn()
	$Player.start_turn(last_text)

func _on_stopwatch_finished() -> void:
	$Player/ProjectileTextEdit.toggle_interactable()
	$Player.end_turn() # $Player.my_turn = false 
	$Boss.start_turn(used_words[-1])
	
func _on_win():
	# $".".process_mode = Node.PROCESS_MODE_DISABLED
	$ColorRect.move_down(false)
	await get_tree().create_timer(4).timeout
	won.emit()
	onresult.emit("true")
	# print('emit')
	# print('yay!')
	
func _on_lose():
	$ColorRect.move_down(true)
	await get_tree().create_timer(4).timeout
	lost.emit()
	onresult.emit("true")
	# print('emit')

func _ready() -> void:
	pass # pass # $".".process_mode = Node.PROCESS_MODE_DISABLED
	
