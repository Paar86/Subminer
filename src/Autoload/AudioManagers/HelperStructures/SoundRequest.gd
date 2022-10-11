extends Node
class_name SoundRequest


var sound_resource: Resource = null
var sound_owner: Node = null
var initial_global_position := Vector2.ZERO


func _init(sound_resource_init: Resource, sound_owner_init: Node2D) -> void:
	sound_resource = sound_resource_init
	sound_owner = sound_owner_init
	
	# We should remember the initial position for the case the sound request
	# gets processed after the sound owner gets removed
	if is_instance_valid(sound_owner):
		initial_global_position = sound_owner.global_position
