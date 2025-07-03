extends Control

signal game_completed(success: bool)

const WORDS_FILE_PATH = "res://minigames/termo/words_clear.txt"

# Game variables
var target_word = ""
var displayed_word = ""
var attempts = []
var max_attempts = 3
var current_attempts = 0
var game_over = false
var SHAKE_EFFECT = "[shake rate=20.0 level=5 connected=1]"
var letters_revealed_by_attempt
var available_keys = []
var letters_used = {}
var WORDS_TO_TRY = []

# UI References
@onready var word_display = $VBoxContainer/WordDisplay
@onready var input_field = $VBoxContainer/InputContainer/LineEdit
@onready var submit_button = $VBoxContainer/InputContainer/SubmitButton
@onready var attempts_list = $VBoxContainer/AttemptsList
@onready var message_label = $VBoxContainer/MessageRichTextLabel
@onready var title_label = $VBoxContainer/TitleRichTextLabel
@onready var restart_button = $VBoxContainer/RestartButton
@onready var attempts_counter = $VBoxContainer/AttemptsCounter

# Word bank - you can modify this list
var WORDS = ["GODOT", "GAME", "CODE", "PIXEL", "SCRIPT", "ENGINE", "PLAYER", "LEVEL"]

var auto_close_timer: Timer

func _ready():
	setup_ui()
	load_words_from_file()
	start_new_game()
	#  Create auto-close timer
	auto_close_timer = Timer.new()
	auto_close_timer.wait_time = 3.0 # 3 seconds delay
	auto_close_timer.one_shot = true
	auto_close_timer.timeout.connect(_on_auto_close_timeout)
	add_child(auto_close_timer)

func setup_ui():
	# Connect signals
	submit_button.pressed.connect(_on_submit_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Setup UI elements
	input_field.placeholder_text = "Enter your guess..."
	restart_button.text = "New Game"
	restart_button.visible = false
	
	# Setup RichTextLabel
	message_label.bbcode_enabled = true
	message_label.fit_content = true

	title_label.bbcode_enabled = true
	title_label.fit_content = true

func load_words_from_file():
	var file = FileAccess.open(WORDS_FILE_PATH, FileAccess.READ)
	
	if file == null:
		print("Error: Could not open words.txt file at ", WORDS_FILE_PATH)
		print("FileAccess error: ", FileAccess.get_open_error())
		# Fallback to a few default words if file can't be loaded
		return
		
	WORDS.clear()
	WORDS_TO_TRY.clear()
	var words_count = 0
	while not file.eof_reached():
		var line = file.get_line().strip_edges().to_upper()
		WORDS.append(line)
		words_count += 1
		if words_count < 1000:
			WORDS_TO_TRY.append(line)
	file.close()
	
	if WORDS.is_empty():
		push_error("Error: No valid words found in words.txt")
		# Fallback words
		WORDS = ["ABOUT", "WORLD", "GREAT", "HEART", "LIGHT"]
	else:
		print("Loaded ", WORDS.size(), " words from words.txt")

func start_new_game():
	# Reset game state
	target_word = ""
	message_label.text = ""
	while target_word == "":
		target_word = WORDS_TO_TRY[randi() % WORDS_TO_TRY.size()]
		if len(target_word) <= 4:
			target_word = ""
	displayed_word = ""
	attempts.clear()
	current_attempts = 0
	game_over = false

	# Create displayed word with underscores
	for i in range(target_word.length()):
		displayed_word += "_"
	
	letters_used.clear()
	for index in range(len(target_word)):
		letters_used[index] = false
	
	available_keys.clear()
	for key in letters_used.keys():
		if not letters_used[key]:
			available_keys.append(key)
	var number_of_reveal
	if len(target_word) < 6:
		number_of_reveal = 1
	else:
		number_of_reveal = len(target_word) / (max_attempts)
	letters_revealed_by_attempt = floor(number_of_reveal)
	
	show_hint(number_of_reveal)
	
		
	# Reset UI
	update_display()
	input_field.editable = true
	submit_button.disabled = false
	restart_button.visible = false

	title_label.text = "[center]Descubra a palavra secreta em Inglês para obter sucesso na [color=aquamarine] " + SHAKE_EFFECT + "Habilidade![/shake][/color][/center]"
	attempts_list.text = ""
	
	print("New game started! Target word: " + target_word) # Debug - remove in final version

func _on_submit_pressed():
	process_guess()

func _on_text_submitted(text: String):
	process_guess()

func process_guess():
	if game_over:
		return
		
	var guess = input_field.text.strip_edges().to_upper()
	input_field.text = ""
	
	if guess == "" or guess not in WORDS:
		message_label.text = "[color=red]Erro: Palavra Indisponivel para uso do [/color] [color=yellow] " + SHAKE_EFFECT + "JOGADOR [/shake][/color]"
		return
	
	# Check if already guessed
	if guess in attempts:
		message_label.text = "[center]" + guess + "[color=yellow] já foi usado ![/color][/center]"
		return
	
	# Add to attempts
	attempts.append(guess)
	update_attempts_list()
	
	# Check if it's the complete word
	if guess == target_word:
		win_game()
		return
		
	wrong_guess()

func show_hint(quantity):
	if len(target_word) % 2 != 0:
		quantity = floor(quantity)
	else:
		quantity = floor(quantity)
	for i in range(quantity):
		var index = available_keys[randi() % available_keys.size()]
		letters_used[index] = true
		reveal_letter(index)

func reveal_letter(index: int):
	var new_displayed = ""
	for i in range(len(target_word)):
		if i == index:
			new_displayed += target_word[index]
		else:
			new_displayed += displayed_word.split("")[i]
	displayed_word = new_displayed
	update_display()

func wrong_guess():
	current_attempts += 1
	message_label.text = "[center][color=red]Bah vivente, a palavra está errada! tu tens " + str(max_attempts - current_attempts) + " tentativas restantes.[/color][/center]"
	
	available_keys.clear()
	for key in letters_used.keys():
		if not letters_used[key]:
			available_keys.append(key)
			
	if current_attempts >= max_attempts:
		lose_game()
	show_hint(letters_revealed_by_attempt)
	
	update_display()

func win_game():
	game_over = true
	displayed_word = target_word
	message_label.text = "[center][color=green][b]Boa Pia, Palavra correta[/b][/color][/center]"
	input_field.editable = false
	submit_button.disabled = true
	restart_button.visible = true
	update_display()
	
	# Emit success signal and start auto-close timer
	game_completed.emit(true)
	auto_close_timer.start()

func lose_game():
	game_over = true
	displayed_word = target_word
	message_label.text = "[center][color=red][b]CHINELADO![/b]"
	input_field.editable = false
	submit_button.disabled = true
	restart_button.visible = true
	update_display()

	# Emit failure signal and start auto-close timer
	game_completed.emit(false)
	auto_close_timer.start()

# Auto-close timeout handler
func _on_auto_close_timeout():
	# This will be handled by the battle scene
	pass

# Add a method to get the current game state (useful for polling method)
func is_game_won() -> bool:
	return game_over and displayed_word == target_word

func is_game_lost() -> bool:
	return game_over and displayed_word == target_word and current_attempts >= max_attempts

func update_display():
	# Update word display with spacing
	var spaced_word = ""
	for i in range(displayed_word.length()):
		spaced_word += displayed_word[i]
		if i < displayed_word.length() - 1:
			spaced_word += " "
	
	word_display.text = spaced_word
	attempts_counter.text = "Tentativas: " + str(current_attempts) + "/" + str(max_attempts)

func update_attempts_list():
	var attempts_text = "palavras tentadas: "
	for i in range(attempts.size()):
		attempts_text += attempts[i]
		if i < attempts.size() - 1:
			attempts_text += ", "
	attempts_list.text = attempts_text

func _on_restart_pressed():
	start_new_game()
