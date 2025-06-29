# WordleGame.gd - Main game controller
extends Control

const WORDS_FILE_PATH = "res://minigames/termo/words_clear.txt"

# Game variables
var target_word = ""
var displayed_word = ""
var attempts = []
var max_attempts = 4
var current_attempts = 0
var game_over = false

# UI References
@onready var word_display = $VBoxContainer/WordDisplay
@onready var input_field = $VBoxContainer/InputContainer/LineEdit
@onready var submit_button = $VBoxContainer/InputContainer/SubmitButton
@onready var attempts_list = $VBoxContainer/AttemptsList
@onready var message_label = $VBoxContainer/MessageLabel
@onready var restart_button = $VBoxContainer/RestartButton
@onready var attempts_counter = $VBoxContainer/AttemptsCounter

# Word bank - you can modify this list
var WORDS = ["GODOT", "GAME", "CODE", "PIXEL", "SCRIPT", "ENGINE", "PLAYER", "LEVEL"]

func _ready():
	setup_ui()
	load_words_from_file()
	start_new_game()
	
func setup_ui():
	# Connect signals
	submit_button.pressed.connect(_on_submit_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Setup UI elements
	input_field.placeholder_text = "Enter your guess..."
	restart_button.text = "New Game"
	restart_button.visible = false

func load_words_from_file():
	var file = FileAccess.open(WORDS_FILE_PATH, FileAccess.READ)
	
	if file == null:
		print("Error: Could not open words.txt file at ", WORDS_FILE_PATH)
		print("FileAccess error: ", FileAccess.get_open_error())
		# Fallback to a few default words if file can't be loaded
		return
	
	WORDS.clear()
	var words_count = 0
	while not file.eof_reached():
		var line = file.get_line().strip_edges().to_upper()
		WORDS.append(line)
		words_count += 1
	file.close()
	
	if WORDS.is_empty():
		push_error("Error: No valid words found in words.txt")
		# Fallback words
		WORDS = ["ABOUT", "WORLD", "GREAT", "HEART", "LIGHT"]
	else:
		print("Loaded ", WORDS.size(), " words from words.txt")

func start_new_game():
	# Reset game state
	target_word = WORDS[randi() % WORDS.size()]
	displayed_word = ""
	attempts.clear()
	current_attempts = 0
	game_over = false
	
	# Create displayed word with underscores
	for i in range(target_word.length()):
		displayed_word += "_"
	
	# Reset UI
	update_display()
	input_field.editable = true
	submit_button.disabled = false
	restart_button.visible = false
	message_label.text = "Guess the word!"
	message_label.modulate = Color.WHITE
	attempts_list.text = ""
	
	print("New game started! Target word: " + target_word)  # Debug - remove in final version

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
		return
	
	# Check if already guessed
	if guess in attempts:
		message_label.text = "You already tried '" + guess + "'!"
		message_label.modulate = Color.YELLOW
		return
	
	# Add to attempts
	attempts.append(guess)
	update_attempts_list()
	
	# Check if it's the complete word
	if guess == target_word:
		win_game()
		return
	
	# Check if guess is a single letter
	for letter in guess.split(""):
		if target_word.contains(letter):
			reveal_letter(letter)
			message_label.text = "Good guess! '" + guess + "' is in the word!"
			message_label.modulate = Color.GREEN
			
			# Check if word is complete
			if not displayed_word.contains("_"):
				win_game()
				return
	wrong_guess()

func reveal_letter(letter: String):
	var new_displayed = ""
	for i in range(target_word.length()):
		if target_word[i] == letter:
			new_displayed += letter
		else:
			new_displayed += displayed_word[i]
	displayed_word = new_displayed
	update_display()

func wrong_guess():
	current_attempts += 1
	message_label.text = "Wrong guess! " + str(max_attempts - current_attempts) + " attempts left."
	message_label.modulate = Color.RED
	
	if current_attempts >= max_attempts:
		lose_game()
	
	update_display()

func win_game():
	game_over = true
	displayed_word = target_word
	message_label.text = "Congratulations! You won!"
	message_label.modulate = Color.GREEN
	input_field.editable = false
	submit_button.disabled = true
	restart_button.visible = true
	update_display()

func lose_game():
	game_over = true
	displayed_word = target_word
	message_label.text = "Game Over! The word was: " + target_word
	message_label.modulate = Color.RED
	input_field.editable = false
	submit_button.disabled = true
	restart_button.visible = true
	update_display()

func update_display():
	# Update word display with spacing
	var spaced_word = ""
	for i in range(displayed_word.length()):
		spaced_word += displayed_word[i]
		if i < displayed_word.length() - 1:
			spaced_word += " "
	
	word_display.text = spaced_word
	attempts_counter.text = "Attempts: " + str(current_attempts) + "/" + str(max_attempts)

func update_attempts_list():
	var attempts_text = "Previous guesses: "
	for i in range(attempts.size()):
		attempts_text += attempts[i]
		if i < attempts.size() - 1:
			attempts_text += ", "
	attempts_list.text = attempts_text

func _on_restart_pressed():
	start_new_game()
