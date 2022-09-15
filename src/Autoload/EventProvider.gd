extends Node

signal shake_requested
signal level_fade_out_white_requested


func request_shake(shake_type: int) -> void:
	var amplitude := 0.0
	var duration := 0.0
	var priority := 0

	match (shake_type):
		Enums.Events.SHAKE_SMALL:
			amplitude = 1.0
			duration = 0.1
		Enums.Events.SHAKE_MEDIUM:
			amplitude = 2.0
			duration = 0.2
			priority = 1
		Enums.Events.SHAKE_BIG:
			amplitude = 3.0
			duration = 0.3
			priority = 2

	emit_signal("shake_requested", amplitude, duration, priority)


func request_level_fade_out_white() -> void:
	emit_signal("level_fade_out_white_requested")
