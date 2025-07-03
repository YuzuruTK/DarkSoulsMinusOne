extends Control

enum BubbleState {
	START, LETTER
}

var state = BubbleState.START
var letter = ''

func _calc_size() -> Vector2:
	var w = ($Right.position.x + $Right.get_rect().size.x) - $Left.position.x # $BG.get_rect().size.x
	var h = ($Bot.position.y + $Bot.get_rect().size.y) - $Top.position.y
	print(Vector2(w, h))
	return Vector2(w, h)

func _ready() -> void:
	$RichTextLabel.bbcode_enabled = true
	pivot_offset = _calc_size() / 2
	update_bubble(false)

func move_up(distance: float = 150.0, duration: float = 0.5):
	var tween = create_tween()
	var target_pos = $".".position - Vector2(0, distance)
	tween.tween_property($".", "position", target_pos, duration)
	await tween.finished

func move_down(distance: float = 150.0, duration: float = 0.5):
	var tween = create_tween()
	var target_pos = $".".position + Vector2(0, distance)
	tween.tween_property($".", "position", target_pos, duration)
	await tween.finished

func _highlight_bubble():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Flash effect
	tween.tween_property($".", "modulate", Color.RED, 0.2)
	tween.tween_property($".", "modulate", Color.WHITE, 0.2).set_delay(0.2)
	
	# Zoom effect
	tween.tween_property($".", "scale", Vector2(1.1, 1.1), 0.2)
	tween.tween_property($".", "scale", Vector2.ONE, 0.2).set_delay(0.2)

func update_bubble(highlight: bool = true):
	if state == BubbleState.START:
		$RichTextLabel.bbcode_text = "Para começar, escreva qualquer palavra em ingês"
	elif state == BubbleState.LETTER:
		$RichTextLabel.bbcode_text = "Escreva uma palavra em inglês começando com a letra [b][color=gold]%c[/color][/b]" % letter.to_upper()
	
	if highlight:
		_highlight_bubble()
