extends KinematicBody2D
class_name FloatingObject

enum MovingStates { MOVING, NOT_MOVING }

var _velocity := Vector2.ZERO
var _damping := 25.0
var _moving_state: int = MovingStates.MOVING


func give_impulse(impulse_velocity: Vector2) -> void:
	_velocity = impulse_velocity


func _physics_process(delta: float) -> void:
	match _moving_state:
		MovingStates.MOVING:
			var direction = _velocity.normalized()
			_velocity -= direction * _damping * delta
			
			var collision := move_and_collide(_velocity * delta)
			if collision:
				_velocity = _velocity.bounce(collision.normal)

			if _velocity.length() < _damping * delta:
				_velocity = Vector2.ZERO
				_moving_state = MovingStates.NOT_MOVING
		MovingStates.NOT_MOVING:
			pass
