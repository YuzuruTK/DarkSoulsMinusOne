extends CharacterBody2D
class_name Player

@onready var mana_bar = $"ManaBar"
@onready var health_bar = $"HealthBar"
@onready var nametag = $"Name"

var state = ""
@export var skills: Dictionary[int, Dictionary] = {}
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

func initialize(player_params: Dictionary, skill_table: Dictionary):
	player_name = player_params.name
	max_health = int(player_params.max_h)
	actual_health = int(player_params.actual_h)
	attack_damage = int(player_params.atk_dam)
	initiative = player_params.initiative
	
	for skill_id: int in player_params.skills_id if player_params.skills_id else [0,1]:
		skills[skill_id] = skill_table[skill_id]
		pass
	pass
	
func export() -> Dictionary:
	var player = {}
	player["name"] = player_name
	player["max_h"] = max_health
	player["actual_h"] = actual_health
	player["atk_dam"] = attack_damage
	player["initiative"] = initiative
	# Verify if it works
	player["skills_id"] = skills.keys()
	return player
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

func get_attack_damage(id: int) -> int:
	var damage: int = attack_damage * skills[id].damage_multiplier
	return round(damage)

func got_hurt(damage_points: int):
	actual_health -= damage_points
	_update_hud()
	pass
func get_skills() -> Array:
	var id_skills = []
	for key in skills.keys():
		id_skills.append({"name" : skills[key].name, "id": key, "is_multi_target": skills[key].is_multi_target})
	return id_skills
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
