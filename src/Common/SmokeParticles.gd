extends Particles2D


func _ready() -> void:
	emitting = true
	yield(get_tree().create_timer(lifetime * (2 - explosiveness), false), "timeout")
	queue_free()
