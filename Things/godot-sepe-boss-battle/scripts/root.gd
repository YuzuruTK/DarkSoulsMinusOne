extends Node2D

signal won
signal lost

signal onresult(string)

@onready var phone = $Phone
@onready var bad_bubble: Sprite2D = $Boss/BadBubble
@onready var good_bubble: Sprite2D = $Boss/GoodBubble

func _ready() -> void:
	bad_bubble.modulate = Color.TRANSPARENT
	good_bubble.modulate = Color.TRANSPARENT
	# $ColorRect.move_down(false)

func _blink_bubble(bubble: Sprite2D):
	var tween = create_tween()
	tween.tween_property(bubble, "modulate", Color.WHITE, 0.5)
	tween.tween_property(bubble, "modulate", Color.TRANSPARENT, 0.5).set_delay(3)

func _on_phone_answer():
	if phone.current_question < 4:
		return
		
	await get_tree().create_timer(7).timeout
	
	if phone.correct_answers >= 3:
		$ColorRect.move_down(false)
		await get_tree().create_timer(4).timeout
		won.emit()
		onresult.emit("true")
	else:
		$ColorRect.move_down(true)
		await get_tree().create_timer(4).timeout
		lost.emit()
		onresult.emit("true")
	
func _on_phone_bad_answer() -> void:
	_blink_bubble(bad_bubble)
	_on_phone_answer()

func _on_phone_good_answer() -> void:
	_blink_bubble(good_bubble)
	_on_phone_answer()
