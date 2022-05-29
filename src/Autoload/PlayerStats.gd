extends Node

signal hitpoints_changed
signal minerals_changed
signal hitpoints_depleted
signal weapon_overheated
signal weapon_cooled
signal heat_value_changed

const STARTING_HITPOINTS := 1

var hitpoints := STARTING_HITPOINTS setget _set_hitpoints
var minerals := 0 setget _set_minerals
var heat_value := 0.0 setget _set_heat_value

var _heat_threshold := 100.0

func reset() -> void:
	hitpoints = STARTING_HITPOINTS
	minerals = 0


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


func _set_heat_value(new_value: float) -> void:
	new_value = clamp(new_value, 0.0, _heat_threshold)
	if new_value == _heat_threshold:
		emit_signal("weapon_overheated")
	if new_value == 0.0:
		emit_signal("weapon_cooled")

	heat_value = new_value
	emit_signal("heat_value_changed", new_value)
