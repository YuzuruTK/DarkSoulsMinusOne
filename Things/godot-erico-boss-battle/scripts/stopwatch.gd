extends Control

@export var seconds = 30
@export var running = false
@export var ticks = 4

signal finished

var elapsed = 0.0
@onready var ticks_left = ticks

func reset():
	elapsed = 0.0
	running = false
	ticks_left = ticks

func _process(delta: float) -> void:
	if running: 
		elapsed += delta
		if elapsed > seconds:
			# reset()
			running = false
			$Timeout.play()
			finished.emit()
		else:
			var steps = seconds / 10
			var should_tick = elapsed > (seconds - steps * ticks_left)
			if should_tick:
				$Timetick.play()
				ticks_left -= 1
	
	$Background/Pointer.rotation_degrees = 45.0 + elapsed / seconds * 360.0
	# $Background/Pointer.rotation += delta * 2
	
	$Background/Progress.queue_redraw()

func get_rotation_pct():
	return absf($Background/Pointer.rotation_degrees - 45.0) / 360.0
