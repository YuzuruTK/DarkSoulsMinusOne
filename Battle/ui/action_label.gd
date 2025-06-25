extends HFlowContainer

@onready var nodes: Dictionary[int, MarginContainer] = {}
@onready var root = $"."

func _ready() -> void:
	# On your container node:
	root.anchor_right = 1.0
	root.anchor_left = 1.0
	root.offset_right = 0
	root.offset_left = -root.size.x
	#root.size_flags_horizontal = Control.SIZE_SHRINK_END
	root.alignment = ALIGNMENT_END
	pass

func add_element(id: int, label: RichTextLabel) -> void:
	# Configure label
	label.fit_content = false
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_SHRINK_END
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Wrap in a MarginContainer
	var container = MarginContainer.new()
	container.add_child(label)

	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 6)
	container.add_theme_constant_override("margin_bottom", 6)
	
	nodes[id] = container
	root.add_child(container)

func delete_element(id: int) -> void:
	root.remove_child(nodes[id])
	pass
