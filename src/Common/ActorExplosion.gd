extends AnimatedSprite

onready var _explosion_sfx_path := "res://assets/sfx/explosion.wav"


func _ready() -> void:
	playing = true
	AudioStreamManager.play_sound(_explosion_sfx_path)
	BubbleGenerator.generate_bubbles_to_rect(
		global_position,
		8.0,
		4.0,
		get_parent(),
		rand_range(3.0, 4.9)
	)


func _on_AnimatedSprite_animation_finished():
	queue_free()
