extends Node

signal hitpoints_changed
signal minerals_changed
signal hitpoints_depleted

const STARTING_HITPOINTS := 30

var hitpoints := STARTING_HITPOINTS setget _set_hitpoints
var minerals := 0 setget _set_minerals


func _ready() -> void:
	pass


func _set_hitpoints(new_value: int) -> void:
	hitpoints = clamp(new_value, 0, STARTING_HITPOINTS)
	emit_signal("hitpoints_changed", hitpoints)
	
	if hitpoints == 0:
		emit_signal("hitpoints_depleted")


func _set_minerals(new_value: int) -> void:
	minerals = max(0, new_value)
	emit_signal("minerals_changed", minerals)
