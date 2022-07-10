extends Area2D

var _ascending_speed := 0.0


func _ready() -> void:
	connect("body_entered", self, "_on_body_entered")
	_ascending_speed = rand_range(15.0, 30.0)
	z_index = -1


func _physics_process(delta: float) -> void:
	translate(-transform.y * _ascending_speed * delta)


func _on_body_entered(body: PhysicsBody2D) -> void:
	queue_free()


func _on_LifeTimer_timeout() -> void:
	queue_free()


func _on_CollisionActivatorTimer_timeout() -> void:
	$CollisionShape2D.set_deferred("disabled", false)
