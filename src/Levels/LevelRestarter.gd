extends Node

signal restart_level_request

var restart_level_by_any_key := false


func _unhandled_input(event: InputEvent) -> void:
	if restart_level_by_any_key:
		request_restart()
		restart_level_by_any_key = false


func request_restart() -> void:
	emit_signal("restart_level_request")
