extends ColorRect

func move_down(is_lost: bool):
	if is_lost:
		$RichTextLabel.text = "DERROTA"
		$RichTextLabel.add_theme_color_override("default_color", Color.DARK_RED)
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(0, 0), 1)
