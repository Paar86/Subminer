extends Node

var _levels_dict = { "level1": "res://src/Levels/Level1.tscn" }

var _dialogue_scene_path := "res://src/Levels/DialogueScene.tscn"

var _current_level_number := 0

onready var CurrentScene: Node = $CurrentScene
onready var MenuManager := $MenuManager


func _ready() -> void:
	_clear_current_scene()
	_load_next_level()


func _play_level_intro(level_number: int) -> void:
	_clear_current_scene()


func _clear_current_scene() -> void:
	for scene in CurrentScene.get_children():
		scene.call_deferred("free")


# We'll first show dialogue scene
func _prepare_level(level_number: int) -> void:
	_clear_current_scene()

	level_number = clamp(level_number, 1, _levels_dict.size())
	_current_level_number = level_number
	var dict_key = "level" + str(level_number)

	var dialogue_scene = load(_dialogue_scene_path).instance()
	CurrentScene.add_child(dialogue_scene)
	dialogue_scene.set_dialogue(dict_key + "_dialogue")
	dialogue_scene.start_dialogue()
	dialogue_scene.connect("dialogue_ended", self, "_on_dialogue_ended", [dict_key])


func _load_next_level() -> void:
	_prepare_level(_current_level_number + 1)


func _on_level_finished() -> void:
	_load_next_level()


# Loading the actual level, after a dialogue scene
func _on_dialogue_ended(dict_key: String) -> void:
	_clear_current_scene()
	var new_level = load(_levels_dict[dict_key]).instance()
	var level_base = new_level.get_node("LevelBase")
	level_base.level_id = dict_key
	level_base.connect("level_finished", self, "_on_level_finished")
	PlayerStats.reset()
	CurrentScene.call_deferred("add_child", new_level)