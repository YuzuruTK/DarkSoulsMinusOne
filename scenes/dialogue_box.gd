extends Node2D

var dialogue_data
var current_index = 0
var result_var = ""

signal onresult(string)

@onready var player_image = $DialogueBox/Characters/PlayerImage
@onready var npc_image = $DialogueBox/Characters/NPCImage
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var choices_container = $DialogueBox/ScrollContainer/Choices
@onready var scroll_container = $DialogueBox/ScrollContainer
@onready var speaker_label = $DialogueBox/Speaker
@export var dialog = str(TextLine)
# Animação
var player_frames = []
var npc_frames = []
var player_frame_index = 0
var npc_frame_index = 0
var animation_timer = 0.0
var frame_delay = 0.05 # segundos

func _process(delta):
	animation_timer += delta
	if animation_timer >= frame_delay:
		animation_timer = 0.0

		# Atualiza frame do jogador
		if player_frames.size() > 0:
			player_frame_index = (player_frame_index + 1) % player_frames.size()
			update_texture(player_image, player_frames[player_frame_index])

		# Atualiza frame do NPC
		if npc_frames.size() > 0:
			npc_frame_index = (npc_frame_index + 1) % npc_frames.size()
			update_texture(npc_image, npc_frames[npc_frame_index])
func load_saved_dialogue_path() -> String:
	var file = FileAccess.open("user://current_dialog_path.txt", FileAccess.READ)
	if file:
		var path = file.get_line().strip_edges()
		file.close()
		return path
	else:
		print("Erro ao ler current_dialog_path.txt")
		return ""
func _ready():
	print("DialogBox carregado!")  # Debug

	# Lê o caminho salvo do diálogo
	dialog = load_saved_dialogue_path()
	print("Path do diálogo carregado do txt:", dialog)

	# Ajusta o tamanho do ScrollContainer
	adjust_scroll_container_size()
	
	# Carrega o diálogo e mostra o primeiro índice
	load_dialogue(dialog)
	show_dialogue(0)

func adjust_scroll_container_size():
	# Obtém o tamanho da tela
	var screen_size = get_viewport().get_visible_rect().size
	# Calcula a altura restante do ScrollContainer até o fim da tela
	var remaining_height = screen_size.y - scroll_container.global_position.y
	# Define o tamanho do ScrollContainer
	scroll_container.size.y = remaining_height
	scroll_container.custom_minimum_size.y = remaining_height


func load_dialogue(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json_result = JSON.parse_string(content)
		if json_result:
			dialogue_data = json_result
			print("Diálogo carregado com sucesso.")
		else:
			print("Erro ao parsear JSON.")
	else:
		print("Erro ao abrir arquivo: ", file_path)

func show_dialogue(index):
	if dialogue_data and index < dialogue_data["dialogue"].size():
		current_index = index
		var dialogue = dialogue_data["dialogue"][index]

		if dialogue["speaker"] == "Player":
			player_image.modulate = Color(1, 1, 1, 1)
			npc_image.modulate = Color(1, 1, 1, 0.3)
		else:
			player_image.modulate = Color(1, 1, 1, 0.3)
			npc_image.modulate = Color(1, 1, 1, 1)

		# Carrega as pastas e reseta animação
		player_frames = load_all_images(dialogue["player_folder"])
		npc_frames = load_all_images(dialogue["npc_folder"])
		player_frame_index = 0
		npc_frame_index = 0
		animation_timer = 0.0

		if player_frames.size() > 0:
			update_texture(player_image, player_frames[0])
		else:
			player_image.texture = null

		if npc_frames.size() > 0:
			update_texture(npc_image, npc_frames[0])
		else:
			npc_image.texture = null



		dialogue_text.text = dialogue["text"]
		speaker_label.text = dialogue["speaker"]

		# Limpar escolhas anteriores
		for child in choices_container.get_children():
			child.queue_free()

		# Criar botões de escolha
		for choice in dialogue["choices"]:
			var button = Button.new()
			button.text = choice["text"]
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			button.clip_text = false
			button.custom_minimum_size = Vector2(0, 50)

			# Personalização básica para deixar mais bonito
			button.add_theme_constant_override("outline_size", 2)
			button.add_theme_constant_override("hseparation", 8)
			button.add_theme_constant_override("vseparation", 8)

			button.pressed.connect(on_choice_selected.bind(choice))
			choices_container.add_child(button)

		# Reajusta o ScrollContainer após adicionar novos elementos
		adjust_scroll_container_size()

func load_all_images(folder_path: String) -> Array:
	var frames = []
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".png"):
				var texture = load(folder_path + "/" + file_name)
				frames.append(texture)
			file_name = dir.get_next()

		dir.list_dir_end()

	frames.sort_custom(func(a, b): return a.resource_path < b.resource_path)
	return frames

func update_texture(texture_rect: TextureRect, texture: Texture2D):
	texture_rect.texture = texture

	# Redimensiona a imagem para 120 pixels de altura
	if texture:
		var height = 120.0
		var scale_factor = height / texture.get_height()
		texture_rect.custom_minimum_size = Vector2(texture.get_width() * scale_factor, height)
	else:
		texture_rect.custom_minimum_size = Vector2.ZERO

func on_choice_selected(choice):
	if choice.has("result_var"):
		result_var = choice["result_var"]
		print(result_var)
		onresult.emit(result_var)

	show_dialogue(choice["next"])
