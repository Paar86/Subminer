extends AnimatedSprite

onready var _explosion_sfx_path := "res://assets/sfx/explosion.wav"


func _ready() -> void:
	# For optimalization reasons
	var function: FuncRef = funcref(self, "_explode")
	YieldHandler.run_with_delay_frames(function, 1)


func _explode() -> void:
	playing = true
	AudioStreamManager.play_sound(_explosion_sfx_path)
	
	# We generate bubbles only when explosion is visible, for optimalization purposes
	if $VisibilityNotifier2D.is_on_screen():
		BubbleGenerator.generate_bubbles_to_rect(
			global_position,
			12.0,
			12.0,
			get_parent(),
			rand_range(6.0, 8.9)
		)

	EventProvider.request_shake(Enums.Events.SHAKE_BIG)


func _on_AnimatedSprite_animation_finished() -> void:
	queue_free()
