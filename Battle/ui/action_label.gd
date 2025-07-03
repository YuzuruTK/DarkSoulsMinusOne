extends HBoxContainer

@onready var nodes: Dictionary[int, MarginContainer] = {}
@onready var root = $"."

func _ready() -> void:
	# Configure the container to properly handle dynamic sizing
	root.anchor_right = 1.0
	root.anchor_left = 1.0
	root.offset_right = 0
	root.offset_left = - root.size.x
	root.size_flags_horizontal = Control.SIZE_SHRINK_END
	root.alignment = ALIGNMENT_END
	
	# Allow the container to expand as needed
	root.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func add_element(id: int, label: RichTextLabel) -> void:
	# Configure label for proper auto-sizing
	label.fit_content = true # This is crucial - allows the label to size itself
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_SHRINK_END
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Set a reasonable minimum size but allow expansion
	label.custom_minimum_size = Vector2(50, 30) # Minimum width and height
	
	# Wrap in a MarginContainer
	var container = MarginContainer.new()
	container.size_flags_horizontal = Control.SIZE_SHRINK_END
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	container.add_child(label)

	# Add margins for spacing
	container.add_theme_constant_override("margin_left", 10)
	container.add_theme_constant_override("margin_right", 10)
	container.add_theme_constant_override("margin_top", 6)
	container.add_theme_constant_override("margin_bottom", 6)
	
	nodes[id] = container
	root.add_child(container)
	
	# Force a layout update to ensure proper sizing
	root.queue_sort()

func delete_element(id: int) -> void:
	if nodes.has(id):
		root.remove_child(nodes[id])
		nodes[id].queue_free() # Properly free the node
		nodes.erase(id)
		root.queue_sort() # Update layout after removal
