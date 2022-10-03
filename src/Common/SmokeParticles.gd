extends Particles2D

var _smoke_sfx := preload("res://assets/sfx/smoke.wav")


func _ready() -> void:
	emitting = true
	BubbleGenerator.generate_bubbles_to_rect(
		global_position,
		8.0,
		4.0,
		get_parent(),
		rand_range(4.0, 6.9)
	)

	var function: FuncRef = funcref(self, "_destroy")
	YieldHandler.run_with_delay_time(function, lifetime * (2 - explosiveness))

	EventProvider.request_shake(Enums.Events.SHAKE_MEDIUM)
	AudioStreamManager2D.play_sound(_smoke_sfx, self)


func _destroy() -> void:
	queue_free()
