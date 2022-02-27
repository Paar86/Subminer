extends Node

signal hitpoints_changed
signal hitpoints_depleted

const STARTING_HITPOINTS := 30

var hitpoints := STARTING_HITPOINTS setget _set_hitpoints


func _ready() -> void:
	pass


func _set_hitpoints(new_value: int) -> void:
	hitpoints = clamp(new_value, 0, STARTING_HITPOINTS)
	emit_signal("hitpoints_changed", hitpoints)
	
	if hitpoints == 0:
		emit_signal("hitpoints_depleted")
