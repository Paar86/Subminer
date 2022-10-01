extends Node
class_name SoundRequest


var sound_path := ""
var sound_owner: Node = null


func _init(sound_path_init: String, sound_owner_init: Node) -> void:
	sound_path = sound_path_init
	sound_owner = sound_owner_init
