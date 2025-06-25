# WordleGame.gd - Main game controller
extends Control

# Game constants
const WORD_LENGTH = 5
const MAX_ATTEMPTS = 6
const WORDS_FILE_PATH = "res://minigames/termo/words.txt"

# Game words array (will be loaded from file)
var WORDS: Array = []

# Game state
var target_word: String
var current_row: int = 0
var current_col: int = 0
var game_over: bool = false
var won: bool = false

# UI References
@onready var grid_container = $VBoxContainer/GridContainer
@onready var input_label = $VBoxContainer/InputContainer/InputLabel
@onready var message_label = $VBoxContainer/MessageContainer/MessageLabel
@onready var new_game_button = $VBoxContainer/ButtonContainer/NewGameButton
@onready var submit_button = $VBoxContainer/ButtonContainer/SubmitButton

# Grid of letter tiles
var letter_tiles: Array = []

func _ready():
	load_words_from_file()
	setup_ui()
	start_new_game()

func load_words_from_file():
	var file = FileAccess.open(WORDS_FILE_PATH, FileAccess.READ)
	
	if file == null:
		print("Error: Could not open words.txt file at ", WORDS_FILE_PATH)
		print("FileAccess error: ", FileAccess.get_open_error())
		# Fallback to a few default words if file can't be loaded
		WORDS = ["ABOUT", "WORLD", "GREAT", "HEART", "LIGHT"]
		return
	
	WORDS.clear()
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges().to_upper()
		
		# Only add words that match the expected length and contain only letters
		if line.length() == WORD_LENGTH and line.is_valid_identifier():
			WORDS.append(line)
		elif line.length() > 0:  # Skip empty lines but warn about invalid words
			print("Warning: Skipping invalid word: ", line)
	
	file.close()
	
	if WORDS.is_empty():
		print("Error: No valid words found in words.txt")
		# Fallback words
		WORDS = ["ABOUT", "WORLD", "GREAT", "HEART", "LIGHT"]
	else:
		print("Loaded ", WORDS.size(), " words from words.txt")

func setup_ui():
	# Create grid of letter tiles
	grid_container.columns = WORD_LENGTH
	
	for row in MAX_ATTEMPTS:
		var row_tiles = []
		for col in WORD_LENGTH:
			var tile = create_letter_tile()
			grid_container.add_child(tile)
			row_tiles.append(tile)
		letter_tiles.append(row_tiles)
	
	# Connect buttons
	new_game_button.pressed.connect(_on_new_game_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	
	# Set initial message
	message_label.text = "Acerte a Palavra!"

func create_letter_tile() -> Label:
	var tile = Label.new()
	tile.text = ""
	tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.custom_minimum_size = Vector2(60, 60)
	
	# Create StyleBox for the tile
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color.GRAY
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	
	tile.add_theme_stylebox_override("normal", style)
	tile.add_theme_color_override("font_color", Color.BLACK)
	tile.add_theme_font_size_override("font_size", 24)
	
	return tile

func start_new_game():
	# Reset game state
	target_word = WORDS[randi() % WORDS.size()]
	current_row = 0
	current_col = 0
	game_over = false
	won = false
	
	# Clear all tiles
	for row in letter_tiles:
		for tile in row:
			tile.text = ""
			update_tile_style(tile, "empty")
	
	# Reset UI
	input_label.text = ""
	message_label.text = "Acerte a palaaararass"
	submit_button.disabled = false
	
	print("New game started. Target word: ", target_word)  # Debug only

func _input(event):
	if game_over:
		return
		
	if event is InputEventKey and event.pressed:
		var key_char = event.as_text_physical_keycode().to_upper()
		
		if key_char >= "A" and key_char <= "Z" and current_col < WORD_LENGTH and len(key_char) == 1:
			add_letter(key_char)
		elif event.keycode == KEY_BACKSPACE:
			remove_letter()
		elif event.keycode == KEY_ENTER:
			submit_guess()

func add_letter(letter: String):
	if current_col < WORD_LENGTH:
		letter_tiles[current_row][current_col].text = letter
		update_tile_style(letter_tiles[current_row][current_col], "filled")
		current_col += 1
		update_input_display()

func remove_letter():
	if current_col > 0:
		current_col -= 1
		letter_tiles[current_row][current_col].text = ""
		update_tile_style(letter_tiles[current_row][current_col], "empty")
		update_input_display()

func update_input_display():
	var current_word = ""
	for i in current_col:
		current_word += letter_tiles[current_row][i].text
	input_label.text = current_word

func submit_guess():
	if current_col != WORD_LENGTH:
		message_label.text = "Word must be 5 letters long!"
		return
	
	var guess = ""
	for i in WORD_LENGTH:
		guess += letter_tiles[current_row][i].text
	
	# Check if guess is in word list (optional validation)
	if not guess in WORDS:
		message_label.text = "Not a valid word!"
		return
	
	# Check the guess against target word
	check_guess(guess)
	
	# Move to next row or end game
	if guess == target_word:
		won = true
		game_over = true
		message_label.text = "PARABAINS"
		submit_button.disabled = true
	elif current_row >= MAX_ATTEMPTS - 1:
		game_over = true
		message_label.text = "Game over! The word was: " + target_word
		submit_button.disabled = true
	else:
		current_row += 1
		current_col = 0
		input_label.text = ""
		message_label.text = "Guess the 5-letter word!"

func check_guess(guess: String):
	var target_chars = target_word.split("")
	var guess_chars = guess.split("")
	var char_counts = {}
	
	# Count characters in target word
	for char in target_chars:
		char_counts[char] = char_counts.get(char, 0) + 1
	
	# First pass: mark correct positions (green)
	var results = ["none", "none", "none", "none", "none"]
	for i in WORD_LENGTH:
		if guess_chars[i] == target_chars[i]:
			results[i] = "correct"
			char_counts[guess_chars[i]] -= 1
	
	# Second pass: mark wrong positions (yellow)
	for i in WORD_LENGTH:
		if results[i] == "none":
			if char_counts.get(guess_chars[i], 0) > 0:
				results[i] = "wrong_position"
				char_counts[guess_chars[i]] -= 1
			else:
				results[i] = "wrong"
	
	# Update tile colors
	for i in WORD_LENGTH:
		update_tile_style(letter_tiles[current_row][i], results[i])

func update_tile_style(tile: Label, state: String):
	var style = tile.get_theme_stylebox("normal").duplicate()
	
	match state:
		"empty":
			style.bg_color = Color.WHITE
			style.border_color = Color.GRAY
		"filled":
			style.bg_color = Color.LIGHT_GRAY
			style.border_color = Color.DARK_GRAY
		"correct":
			style.bg_color = Color.GREEN
			style.border_color = Color.DARK_GREEN
			tile.add_theme_color_override("font_color", Color.WHITE)
		"wrong_position":
			style.bg_color = Color.YELLOW
			style.border_color = Color.ORANGE
			tile.add_theme_color_override("font_color", Color.BLACK)
		"wrong":
			style.bg_color = Color.DARK_GRAY
			style.border_color = Color.BLACK
			tile.add_theme_color_override("font_color", Color.WHITE)
	
	tile.add_theme_stylebox_override("normal", style)

func _on_new_game_pressed():
	start_new_game()

func _on_submit_pressed():
	submit_guess()
