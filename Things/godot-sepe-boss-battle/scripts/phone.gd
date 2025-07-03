extends Control

# UI Elements
@onready var question_label = $Frame/Screen/QuestionLabel
@onready var answer_input = $Frame/Screen/AnswerInput
# @onready var submit_button = $VBoxContainer/SubmitButton
@onready var feedback_label = $Frame/Screen/FeedbackLabel
# @onready var score_label = $VBoxContainer/ScoreLabel
# @onready var sepe_sprite = $VBoxContainer/SepeSprite

signal bad_answer
signal good_answer

# Game Variables
var current_question = 0
var correct_answers = 0
var total_questions = 5

# Groq API Configuration
var groq_api_key = "API_KEY_HERE"
var groq_url = "https://api.groq.com/openai/v1/chat/completions"

# Questions array
var questions = [
	"What is your name?", # "Hello. What is your name?",
	"Are you here to fight?",
	"Where do you come from?",
	"What do you want here?",
	"Can I trust you?"
]

var http_request: HTTPRequest

func _ready():
	setup_ui()
	setup_http_request()
	start_game()

func setup_ui():
	# submit_button.pressed.connect(_on_submit_pressed)
	answer_input.text_submitted.connect(_on_answer_submitted)

func setup_http_request():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func start_game():
	current_question = 0
	correct_answers = 0
	show_current_question()
	update_score_display()

func show_current_question():
	if current_question < questions.size():
		question_label.text = questions[current_question] # "Sepé asks: \"" + questions[current_question] + "\""
		answer_input.text = ""
		answer_input.editable = true
		# submit_button.disabled = false
		# feedback_label.text = "Type your answer in English..."
	else:
		end_game()

# func _on_submit_pressed():
	# submit_answer()

func _on_answer_submitted(text: String):
	submit_answer()

func submit_answer():
	var player_answer = answer_input.text.strip_edges()
	
	if player_answer.length() == 0:
		feedback_label.text = "Please write an answer!"
		return
	
	# Disable input while processing
	answer_input.editable = false
	# submit_button.disabled = true
	# feedback_label.text = "Sepé is thinking..."
	
	# Send to Groq API
	evaluate_answer_with_groq(player_answer)

func evaluate_answer_with_groq(answer: String):
	var question = questions[current_question]
	
	# Create the prompt for Groq
	var prompt = create_evaluation_prompt(question, answer)
	
	# Prepare the request
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + groq_api_key
	]
	
	var body = {
		"model": "llama3-70b-8192", # "deepseek-r1-distill-llama-70b", # "llama3-8b-8192",
		"messages": [
			{
				"role": "user",
				"content": prompt
			}
		],
		"temperature": 0.3,
		"max_tokens": 100
	}
	
	var json_body = JSON.stringify(body)
	
	# Make the request
	http_request.request(groq_url, headers, HTTPClient.METHOD_POST, json_body)

func create_evaluation_prompt(question: String, answer: String) -> String:
	var context = """You are evaluating if a player's English response would convince Sepé Tiaraju (a Guarani leader) that they are peaceful and trustworthy. Assume Sepé knows English.

Question: "%s"
Player's answer: "%s"

Consider:
1. Is the answer in English?
2. Is the English grammar acceptable for a basic level?
3. Does the answer show peaceful intentions?
4. Is the response appropriate and respectful?

Respond with ONLY one of these formats:
CORRECT: [brief encouraging feedback]
INCORRECT: [brief helpful correction]

Keep feedback under 20 words.""" % [question, answer]
	
	return context

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code != 200:
		feedback_label.text = "Error connecting to Sepé's wisdom... Try again!"
		answer_input.editable = true
		# submit_button.disabled = false
		return
	
	# Parse the response
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		feedback_label.text = "Sepé couldn't understand... Try again!"
		answer_input.editable = true
		# submit_button.disabled = false
		return
	
	var response_data = json.data
	
	if response_data.has("choices") and response_data.choices.size() > 0:
		var ai_response = response_data.choices[0].message.content.strip_edges()
		print(ai_response)
		process_ai_evaluation(ai_response)
	else:
		feedback_label.text = "Sepé is confused... Try again!"
		answer_input.editable = true
		# submit_button.disabled = false

func process_ai_evaluation(ai_response: String):
	var is_correct = ai_response.begins_with("CORRECT:")
	
	if is_correct:
		correct_answers += 1
		feedback_label.text = ai_response.substr(8).strip_edges()
		feedback_label.modulate = Color.GREEN
		good_answer.emit()
	else:
		feedback_label.text = ai_response.substr(10).strip_edges()
		feedback_label.modulate = Color.RED
		bad_answer.emit()
	
	# Wait a moment then continue
	await get_tree().create_timer(3.0).timeout
	next_question()

func _flash_screen():
	var color_rect = $Frame/Screen/ColorRect
	var tween = create_tween()
	tween.tween_property(color_rect, "color", Color.WHITE, 0.25)
	tween.tween_property(color_rect, "color", Color.TRANSPARENT, 0.25)

func next_question():
	_flash_screen()
	current_question += 1
	feedback_label.modulate = Color.WHITE
	update_score_display()
	show_current_question()

func update_score_display():
	print("Score: %d/%d" % [correct_answers, current_question])
	# score_label.text = "Score: %d/%d" % [correct_answers, current_question]

func end_game():
	var success = correct_answers > total_questions / 2
	
	if success:
		question_label.text = "..." # "Sepé nods with respect..."
		feedback_label.text = "\"You may pass in peace. Your words show honor.\""
		feedback_label.modulate = Color.GREEN
	else:
		question_label.text = "..." # "Sepé raises his weapon..."
		feedback_label.text = "\"Your words do not convince Sepé Tiaraju. Leave now!\""
		feedback_label.modulate = Color.RED
	
	# score_label.text = "Final Score: %d/%d" % [correct_answers, total_questions]
	
	# Show restart button
	# submit_button.text = "Play Again"
	# submit_button.disabled = false
	# submit_button.pressed.disconnect(_on_submit_pressed)
	# submit_button.pressed.connect(restart_game)
