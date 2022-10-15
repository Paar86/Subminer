extends Node2D
class_name AudioStreamLocal

var stream_player: AudioStreamPlayer2D
var stream_owner: Node2D


func _init(stream_player_init: AudioStreamPlayer2D, stream_owner_init: Node2D = null) -> void:
	stream_player = stream_player_init
	stream_owner = stream_owner_init


func reset() -> void:
	stream_player.global_position = Vector2.ZERO
	stream_player.stream = null
	stream_player.volume_db = 0.0
	stream_owner = null
