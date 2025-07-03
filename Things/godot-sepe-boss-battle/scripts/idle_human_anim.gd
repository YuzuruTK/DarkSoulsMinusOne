extends Sprite2D

func _play_squish_animation(amount = 0.05, flip: bool = true):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		self, "scale:y", 
		scale.y - amount if flip else scale.y + amount, 
		1
	).set_trans(Tween.TRANS_SINE)
	tween.finished.connect(func(): _play_squish_animation(amount, not flip))

func _reposition():
	var size = get_rect().size
	offset.y -= size.y / 2
	position.x += (size.x / 2) * (scale.x)
	position.y += (size.y / 2) * (scale.y)
	# print(position.y)
	
func _ready() -> void:
	# _reposition()
	_play_squish_animation(0.01)
