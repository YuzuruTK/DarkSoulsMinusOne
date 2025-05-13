extends CharacterBody2D
class_name Player

@onready var mana_bar = $"ManaBar"
@onready var health_bar = $"HealthBar"
@onready var nametag = $"Name"

var state = ""
@export var skills: Array[Dictionary] = [{"name" : "FOGOO", "id" : "1"}, {"name" : "GELOOO", "id" : "2"}]
var buttons: Array[Button]
var player_name: String = ""

# Health Variables
var max_health: float = 0
var actual_health: float = 0
# mana variables
var max_mana: float = 100
var actual_mana: float = 20
# Other Variables
var attack_damage: float = 0
var initiative: int = 0

func initialize(player_params: Dictionary):
	player_name = player_params.name
	max_health = player_params.max_h
	actual_health = player_params.actual_h
	attack_damage = player_params.atk_dam
	initiative = player_params.initiative
	pass
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_hud()
	_adjust_hud()
	pass # Replace with function body.

func _update_hud() -> void:
	health_bar.value = (actual_health / max_health) * 100
	mana_bar.value = (actual_mana / max_mana) * 100
	pass
	
func _adjust_hud() -> void:
	var hud_size = Vector2(400, 50)
	# Mana Node Adjustments 
	mana_bar.position = Vector2(200, -200)
	mana_bar.fill_mode = health_bar.FILL_LEFT_TO_RIGHT
	mana_bar.size = hud_size
	mana_bar.scale = Vector2(-0.25, 0.4)
	# Health Node Adjustments
	health_bar.position = Vector2(-200, -250)
	health_bar.fill_mode = health_bar.FILL_LEFT_TO_RIGHT
	health_bar.size = hud_size
	health_bar.scale = Vector2(0.25, 0.4)
	# Name Node Adjustments
	nametag.position = Vector2(-200, -300)
	nametag.size = hud_size
	nametag.bbcode_enabled = true
	nametag.text = "[font_size=%d]%s[/font_size]" % [round(hud_size[1] / 1.5), player_name]
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
