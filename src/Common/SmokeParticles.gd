extends Particles2D


func _ready() -> void:
	emitting = true
	BubbleGenerator.generate_bubbles_to_rect(
		global_position,
		8.0,
		4.0,
		get_parent(),
		rand_range(3.0, 5.9)
	)
	
	var function: FuncRef = funcref(self, "_destroy")
	YieldHandler.run_with_delay_time(function, lifetime * (2 - explosiveness))


func _destroy() -> void:
	queue_free()
