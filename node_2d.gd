extends Node2D
@onready var dialog = $DialogBox
@onready var player = $Player
@onready var canvas_layer = $CanvasLayer
var current_trigger: Node = null
var booleano = "false"
var battle_scene

func _ready():
	call_deferred("_connect_battle_triggers")
	
	$DialogBox/ButtonSim.pressed.connect(on_button_sim_pressed)
	$DialogBox/ButtonNao.pressed.connect(on_button_nao_pressed)
	
func olhasinal():
	var result = await battle_scene.onresult
	battle_scene.visible = false
	battle_scene.queue_free()
	battle_scene = null
	
	# SEMPRE reseta o follow_viewport_enabled para false quando a batalha termina
	canvas_layer.follow_viewport_enabled = false
	
	# Força o uso da câmera do player
	if player.has_node("Camera2D"):
		player.get_node("Camera2D").make_current()
	
	self.show()
	on_button_nao_pressed()
	return result
	
func _connect_battle_triggers():
	var triggers = get_tree().get_nodes_in_group("battle_triggers")
	print("Battle triggers encontrados: ", triggers)
	for trigger in triggers:
		trigger.battle_triggered.connect(on_battle_triggered)

func on_battle_triggered(trigger):
	if (trigger.is_insta_load == true):
		trigger.is_insta_load = false
		battle_scene = trigger.battle_scene.instantiate()
		
		# Configura follow_viewport_enabled para true (se necessário para cartomante)
		canvas_layer.follow_viewport_enabled = true
		canvas_layer.add_child(battle_scene)
		
		trigger.visible = true
		self.hide()
		olhasinal()
		return
	
	print("Trigger recebido: ", trigger.name)
	dialog.visible = true
	player.can_move = false
	current_trigger = trigger

func on_button_sim_pressed():
	if current_trigger:
		battle_scene = current_trigger.battle_scene.instantiate()
		
		# Configura o follow_viewport_enabled baseado no tipo de batalha
		if (current_trigger.is_battle == true):
			canvas_layer.follow_viewport_enabled = true
			battle_scene.battle_type = current_trigger.type_battle
		else:
			canvas_layer.follow_viewport_enabled = false
		
		canvas_layer.add_child(battle_scene)
		battle_scene.visible = true
		self.hide()
		olhasinal()

func on_button_nao_pressed():
	dialog.visible = false
	player.can_move = true
	current_trigger = null
	
	# Garante que a câmera do player está ativa
	if player.has_node("Camera2D"):
		player.get_node("Camera2D").make_current()

func _process(delta):
	if dialog.visible:
		var offset = Vector2(0, -50)
		dialog.global_position = player.global_position + offset
