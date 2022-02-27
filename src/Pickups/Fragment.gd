extends KinematicBody2D

onready var animation_player := $AnimationPlayer

enum States { IDLE, FOLLOW, TRAVEL }

var _state: int = States.TRAVEL
var _rotation_speed_rad := 2.0
var _velocity := Vector2()
var _damping := 25.0
var _max_speed := 150.0
var _target_body: KinematicBody2D = null


func _physics_process(delta: float) -> void:

	match _state:
		States.IDLE:
			if _velocity != Vector2.ZERO:
				$CollisionShape2D.set_deferred("disabled", false)
				_state = States.TRAVEL
		States.FOLLOW:
			if (!_target_body):
				return

			# Maybe do it with steering behaviour in the future?
			var to_target: Vector2 = _target_body.global_position - global_position
			var distance_to_target: float = to_target.length()
			var direction_to_target: Vector2 = to_target.normalized()
			_velocity = direction_to_target * _max_speed * delta
			move_and_collide(_velocity)

			# Snap to target if too close to avoid shaking.
			if distance_to_target < 5.0:
				global_position = _target_body.global_position
		States.TRAVEL:
			var direction = _velocity.normalized()
			_velocity -= direction * _damping * delta
			
			var collision := move_and_collide(_velocity * delta)
			if collision:
				_velocity = _velocity.bounce(collision.normal)

			if _velocity.length() < _damping * delta:
				_velocity = Vector2.ZERO

			if _velocity == Vector2.ZERO:
				$CollisionShape2D.set_deferred("disabled", true)
				_state = States.IDLE
				return

	rotation += _rotation_speed_rad * delta


func give_impulse(impulse_velocity: Vector2) -> void:
	_velocity = impulse_velocity


func _on_PickupBox_body_entered(body: GameActor) -> void:
	body.propagate_effects( {Enums.Effects.MINERALS: 1} )
	animation_player.play("Pickup")
	$PickupBox.set_deferred("disabled", true)
	yield(animation_player, "animation_finished")
	queue_free()


func _on_AutoPickupDetector_body_entered(body: GameActor) -> void:
	_target_body = body
	$CollisionShape2D.set_deferred("disabled", true)
	_state = States.FOLLOW
