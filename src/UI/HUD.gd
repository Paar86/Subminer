extends Control
class_name HUD

# Nodes
onready var MineralsCounter: Label = $VBoxContainer/MineralsBar/Counter
onready var MineralsGoal: Label = $VBoxContainer/MineralsBar/GoalNumber
onready var PowerLogo: TextureRect = $VBoxContainer/LifeBar/PowerLogo
onready var HitpointsHolder: Control = $VBoxContainer/LifeBar/HitpointsMargin/HitpointsHolder
onready var HeatLogo: TextureRect = $VBoxContainer/HeatBar/HeatLogo
onready var HeatCounter: Label = $VBoxContainer/HeatBar/Counter

# Resources
onready var _hitpoint_texture := preload("res://assets/ui/power_unit.png")
onready var _power_texture := preload("res://assets/ui/power_symbol_yellow.png")
onready var _blinking_power_texture := preload("res://assets/ui/PowerBlinkingAnimatedTexture.tres")

onready var _heat_low_texture := preload("res://assets/ui/heat_low_symbol.png")
onready var _heat_med_texture := preload("res://assets/ui/heat_med_symbol.png")
onready var _heat_high_texture := preload("res://assets/ui/heat_high_symbol.png")

const POWER_BLINKING_THRESHOLD := 10


func set_minerals_goal(goal_number: int) -> void:
	MineralsGoal.text = str(goal_number)
	
	
func reset_hitpoints() -> void:
	for i in HitpointsHolder.get_child_count():
		var child: TextureRect = HitpointsHolder.get_child(i)
		child.visible = true


func _ready() -> void:
	PowerLogo.texture = _power_texture

	for i in PlayerStats.STARTING_HITPOINTS:
		var hitpoint = TextureRect.new()
		hitpoint.texture = _hitpoint_texture
		hitpoint.size_flags_horizontal = SIZE_FILL
		HitpointsHolder.add_child(hitpoint)

	PlayerStats.connect("hitpoints_changed", self, "_on_hitpoints_changed")
	PlayerStats.connect("minerals_changed", self, "_on_minerals_changed")
	
	PlayerStats.connect("weapon_overheated", self, "_on_weapon_overheated")
	PlayerStats.connect("weapon_cooled", self, "_on_weapon_cooled")
	PlayerStats.connect("heat_value_changed", self, "_on_heat_value_changed")


func _on_hitpoints_changed(hitpoints: int) -> void:
	for i in HitpointsHolder.get_child_count():
		var child: TextureRect = HitpointsHolder.get_child(i)
		child.visible = i < hitpoints

	if hitpoints <= POWER_BLINKING_THRESHOLD:
		_start_power_blinking()


func _on_minerals_changed(minerals: int) -> void:
	MineralsCounter.text = str(minerals)


func _on_heat_value_changed(value: float) -> void:
	if value < 30:
		HeatLogo.texture = _heat_low_texture
	if value >= 30 and value < 70:
		HeatLogo.texture = _heat_med_texture
	if value >= 80:
		HeatLogo.texture = _heat_high_texture	
	
	HeatCounter.text = str(value)


func _on_weapon_overheated() -> void:
	HeatCounter.modulate = Color.red


func _on_weapon_cooled() -> void:
	HeatCounter.modulate = Color.white


func _start_power_blinking() -> void:
	PowerLogo.texture = _blinking_power_texture
