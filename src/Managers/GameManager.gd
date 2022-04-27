extends Node

var _levels: Array = [
	"res://src/Levels/Level1.tscn",
]

var _dialogue_scene_path := "res://src/Levels/DialogueScene.tscn"

var _current_level := 0

onready var CurrentScene: Node = $CurrentScene
onready var MenuManager := $MenuManager


func _ready() -> void:
	_clear_current_scene()
	_load_next_level()


func _play_level_intro(level_number: int) -> void:
	_clear_current_scene()



func _clear_current_scene() -> void:
	for scene in CurrentScene.get_children():
		CurrentScene.remove_child(scene)


func _load_level(level_number: int) -> void:
	level_number = clamp(level_number, 1, _levels.size())
	var new_level = load(_levels[level_number - 1]).instance()
	var level_id: String = new_level.get_node("LevelBase").level_id
	
	var dialogue_scene = load(_dialogue_scene_path).instance()
	CurrentScene.add_child(dialogue_scene)
	dialogue_scene.set_dialogue(level_id + "_dialogue")
	dialogue_scene.start_dialogue()
	
	yield(dialogue_scene, "dialogue_ended")
	_clear_current_scene()
	
	CurrentScene.call_deferred("add_child", new_level)
	_current_level = level_number
	PlayerStats.reset()


func _load_next_level() -> void:
	_load_level(_current_level + 1)
