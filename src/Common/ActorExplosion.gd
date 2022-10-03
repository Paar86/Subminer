extends AnimatedSprite

var _explosion_sfx := preload("res://assets/sfx/explosion.wav")


func _ready() -> void:
	playing = true
	AudioStreamManager2D.play_sound(_explosion_sfx, self)
	BubbleGenerator.generate_bubbles_to_rect(
		global_position,
		8.0,
		4.0,
		get_parent(),
		rand_range(3.0, 4.9)
	)
	
	EventProvider.request_shake(Enums.Events.SHAKE_SMALL)


func _on_AnimatedSprite_animation_finished():
	queue_free()
