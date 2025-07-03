extends Area2D

@export var battle_scene : PackedScene
@export var dialogue_path : String  # Adicione este export para definir o caminho do diálogo no editor
@export var is_battle : bool
@export var is_insta_load : bool
@export var type_battle : String


signal battle_triggered(trigger)

func _ready():
	add_to_group("battle_triggers")
	connect("body_entered", self.on_body_entered)

func on_body_entered(body):
	if body.name == "Player":
		print("Trigger colidido!")
		emit_signal("battle_triggered", self)

		# Salva o caminho do diálogo em um .txt
		save_dialogue_path(dialogue_path)

func save_dialogue_path(path: String):
	var file = FileAccess.open("user://current_dialog_path.txt", FileAccess.WRITE)
	if file:
		file.store_line(path)
		file.close()
		print("Path salvo:", path)
	else:
		print("Erro ao salvar path.")
