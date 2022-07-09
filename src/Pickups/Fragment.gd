extends FloatingObject

onready var AnimPlayer := $AnimationPlayer
onready var _pickup_sfx_path := "res://assets/sfx/pickup2.wav"

enum States { IDLE, FOLLOW, TRAVEL }

var _state: int = States.TRAVEL
var _rotation_speed_rad := 2.0
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
			var target_global = _target_body.global_position
			var global = global_position
			var to_target: Vector2 = _target_body.global_position - global_position
			var distance_to_target: float = to_target.length()
			var direction_to_target: Vector2 = to_target.normalized()
			_velocity = direction_to_target * _max_speed * delta
			move_and_collide(_velocity)

			# Snap to target if too close to avoid shaking.
			if distance_to_target < 5.0:
				global_position = _target_body.global_position
		States.TRAVEL:
			._physics_process(delta)

			if _velocity == Vector2.ZERO:
				$CollisionShape2D.set_deferred("disabled", true)
				_state = States.IDLE
				return

	rotation += _rotation_speed_rad * delta


func _on_PickupBox_body_entered(body: GameActor) -> void:
	AudioStreamManager.play_sound(_pickup_sfx_path)
	body.propagate_effects( {Enums.Effects.MINERALS: 1} )
	AnimPlayer.play("Pickup")
	$PickupBox.set_deferred("disabled", true)
	yield(AnimPlayer, "animation_finished")
	queue_free()


func _on_AutoPickupDetector_body_entered(body: GameActor) -> void:
	_target_body = body
	$CollisionShape2D.set_deferred("disabled", true)
	_state = States.FOLLOW
	
	# Follow animation cannot be paused when the tree has been paused
	pause_mode = Node.PAUSE_MODE_PROCESS
