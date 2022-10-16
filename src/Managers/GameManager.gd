extends Node

var _levels_dict = {
	"level1": "res://src/Levels/Level1.tscn",
	"level2": "res://src/Levels/Level2.tscn",
	"level3": "res://src/Levels/Level3.tscn",
	"level4": "res://src/Levels/Level4.tscn",
	"level5": "res://src/Levels/Level5.tscn",
	"level6": "res://src/Levels/Level6.tscn",
	"level7": "res://src/Levels/Level7.tscn",
}

var _title_screen_path := "res://src/IntermissionScreens/TitlePage.tscn"
var _dialogue_scene_path := "res://src/IntermissionScreens/DialogueScene.tscn"
var _ending_credits_scene_path := "res://src/IntermissionScreens/EndingCredits/EndingCredits.tscn"

var _current_level_number := 0
var _current_level_id := ""

onready var CurrentScene: Node = $CurrentScene


func _ready() -> void:
	EventProvider.connect("game_restart_requested", self, "_on_restart_game_request")
	_show_title_screen()


func _clear_current_scene() -> void:
	for scene in CurrentScene.get_children():
		scene.call_deferred("free")


# We'll first show dialogue scene
func _show_dialogue_scene(level_id: String, is_ending_dialogue: bool = false) -> void:
	_clear_current_scene()
	var dialogue_scene = load(_dialogue_scene_path).instance()
	dialogue_scene.level_id = level_id

	CurrentScene.add_child(dialogue_scene)
	dialogue_scene.show_level_name = !is_ending_dialogue
	dialogue_scene.set_dialogue(level_id + "_dialogue")
	dialogue_scene.start_dialogue()
	dialogue_scene.connect("dialogue_ended", self, "_on_dialogue_ended", [level_id, is_ending_dialogue])


func _load_level(dict_key: String) -> void:
	_clear_current_scene()
	var new_level = load(_levels_dict[dict_key]).instance()
	_current_level_id = dict_key
	new_level.level_id = dict_key
	new_level.connect("level_finished", self, "_on_level_finished")
	new_level.get_node("LevelRestarter").connect("restart_level_request", self, "_on_restart_level_request")

	CurrentScene.call_deferred("add_child", new_level)


func _load_next_level() -> void:
	# To be certain the tree has not gotten paused in some point of the time
	get_tree().paused = false
	
	_current_level_number = _current_level_number + 1
	if _current_level_number > _levels_dict.size():
		_show_dialogue_scene("end", true)
		return
	
	var next_level_id = _levels_dict.keys()[_current_level_number - 1]
	_show_dialogue_scene(next_level_id)


func _reload_level() -> void:
	if !_current_level_id:
		return

	_load_level(_current_level_id)


func _on_level_finished() -> void:
	_load_next_level()


func _show_title_screen() -> void:
	_clear_current_scene()
	MusicManager.stop_music()
	var title_scene = load(_title_screen_path).instance()
	CurrentScene.add_child(title_scene)
	title_scene.connect("new_game_pressed", self, "_on_new_game_pressed")


func _show_ending_screen() -> void:
	_clear_current_scene()
	MusicManager.stop_music()
	var ending_scene = load(_ending_credits_scene_path).instance()
	CurrentScene.add_child(ending_scene)


# Loading the actual level, after a dialogue scene
func _on_dialogue_ended(level_id: String, is_ending_dialogue: bool = false) -> void:
	if is_ending_dialogue:
		_show_ending_screen()
		return
	
	_load_level(level_id)


func _on_new_game_pressed() -> void:
	_load_next_level()


func _on_restart_level_request() -> void:
	_reload_level()


func _on_restart_game_request() -> void:
	_show_title_screen()
