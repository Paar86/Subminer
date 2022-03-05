extends Node

var _levels: Array = [
	"res://src/Levels/Level1.tscn",
]

var _current_level := 0

onready var CurrentScene: Node = $CurrentScene
onready var CanvasHUD := $UI/HUD


func _ready() -> void:
	_clear_current_scene()
	_load_level(1)


func _clear_current_scene() -> void:
	for scene in CurrentScene.get_children():
		CurrentScene.remove_child(scene)


func _load_level(level_number: int) -> void:
	level_number = clamp(level_number, 1, _levels.size())
	var level = load(_levels[level_number - 1]).instance()
	CurrentScene.call_deferred("add_child", level)
	_current_level = level_number
	PlayerStats.reset()
	
	var minerals_goal: int = level.get_node("LevelBase").minerals_goal
	CanvasHUD.set_minerals_goal(minerals_goal)
	CanvasHUD.show()
	

func _load_next_level() -> void:
	_load_level(_current_level + 1)
