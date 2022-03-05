extends Control
class_name HUD

# Nodes
onready var _minerals_counter: Label = $VBoxContainer/MineralsBar/Counter
onready var _minerals_goal: Label = $VBoxContainer/MineralsBar/GoalNumber
onready var _power_logo: TextureRect = $VBoxContainer/LifeBar/PowerLogo
onready var _hitpoints_holder: Control = $VBoxContainer/LifeBar/HitpointsMargin/HitpointsHolder

# Resources
onready var _hitpoint_texture := preload("res://assets/ui/power_unit.png")
onready var _power_texture := preload("res://assets/ui/power_symbol_yellow.png")
onready var _blinking_power_texture := preload("res://src/UI/PowerBlinkingAnimatedTexture.tres")

const POWER_BLINKING_THRESHOLD := 10


func set_minerals_goal(goal_number: int) -> void:
	_minerals_goal.text = str(goal_number)


func _ready() -> void:
	_power_logo.texture = _power_texture

	for i in PlayerStats.STARTING_HITPOINTS:
		var hitpoint = TextureRect.new()
		hitpoint.texture = _hitpoint_texture
		hitpoint.size_flags_horizontal = SIZE_FILL
		_hitpoints_holder.add_child(hitpoint)

	PlayerStats.connect("hitpoints_changed", self, "_on_hitpoints_changed")
	PlayerStats.connect("minerals_changed", self, "_on_minerals_changed")


func _on_hitpoints_changed(hitpoints: int) -> void:
	for i in _hitpoints_holder.get_child_count():
		var child: TextureRect = _hitpoints_holder.get_child(i)
		child.visible = i < hitpoints

	if hitpoints <= POWER_BLINKING_THRESHOLD:
		_start_power_blinking()


func _on_minerals_changed(minerals: int) -> void:
	_minerals_counter.text = str(minerals)


func _start_power_blinking() -> void:
	_power_logo.texture = _blinking_power_texture
