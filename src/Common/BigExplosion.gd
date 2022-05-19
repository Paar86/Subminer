extends AnimatedSprite

onready var _explosion_sfx_path := "res://assets/sfx/explosion.wav"


func _ready() -> void:
	playing = true
	AudioStreamManager.play_sound(_explosion_sfx_path)


func _on_AnimatedSprite_animation_finished() -> void:
	queue_free()
