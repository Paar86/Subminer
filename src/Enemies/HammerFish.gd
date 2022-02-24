extends GameActor

export var hitpoints_override := 40

enum Directions { LEFT, RIGHT }
export(Directions) var initial_direction = Directions.RIGHT

enum States { PATROL, FOLLOW, ROAR, CHARGE, REST, DEATH }
var _state = States.PATROL

onready var _sprite: Sprite = $Sprite
onready var _charge_detector_high: RayCast2D = $ChargeDetectorHigh
onready var _charge_detector_low: RayCast2D = $ChargeDetectorLow

var _smoke_effect := preload("res://src/Common/SmokeParticles.tscn")
var _direction := Vector2.RIGHT
var _max_patrol_speed := 40.0
var _patrol_acceleration := 50.0
var _death_acceleration := 30.0
var _velocity := Vector2.ZERO
var _charge_speed := _max_patrol_speed * 6.0
var _rest_duration := 1.0
var _rested_time := 0.0

var _time := 0.0
var _shake_duration := 1.0
var _shake_default_position: Vector2
var _shake_default_distance: float = 3.0
var _shake_distance: float = _shake_default_distance
var _shake_frequency: float = 50.0
var _target_body: KinematicBody2D = null


func _ready() -> void:
	_shake_default_position =  _sprite.position
	hitpoints = hitpoints_override
	if initial_direction == Directions.LEFT:
		_set_sprite_orientation(Vector2.LEFT)


func _physics_process(delta: float) -> void:

	match _state:
		States.PATROL:
			if _target_body:
				_state = States.FOLLOW
				return

			_velocity += _direction * _patrol_acceleration * delta
			_velocity.x = clamp(_velocity.x, -_max_patrol_speed, _max_patrol_speed)

			var collision := move_and_collide(_velocity * delta)
			if collision:
				_velocity = Vector2.ZERO
				_state = States.REST
				return

			_check_charge_collision()
		States.FOLLOW:
			if !_target_body:
				_state = States.REST
				return

			_direction = (_target_body.global_position - global_position).normalized()
			_velocity = _direction * _max_patrol_speed
			move_and_slide(_velocity)
			_check_charge_collision()
			_set_sprite_orientation(_direction)
		States.ROAR:
			# Shake animation
			_time += delta
			_sprite.position.y = _shake_default_position.y + sin(_time * _shake_frequency) * _shake_distance
			_shake_distance -= delta * 5.0
			# Transition to CHARGE state at the end of shake animation
			if _shake_distance <= 0.0:
				_shake_distance = _shake_default_distance
				# Change sprite
				# Make a sound
				_state = States.CHARGE
				return
		States.CHARGE:
			_velocity = _direction * _charge_speed
			var collision := move_and_collide(_velocity * delta)
			if collision:
				if is_collision_with_world(collision):
					var smoke_instance = _smoke_effect.instance()
					smoke_instance.global_position = collision.position
					get_parent().call_deferred("add_child", smoke_instance)
				_velocity = Vector2.ZERO
				_state = States.REST
				return
		States.REST:
			_rested_time += delta
			if _rested_time >= _rest_duration:
				_direction = _get_simplified_direction(_direction)
				var collision = move_and_collide(_direction, true, true, true)
				if is_collision_with_world(collision):
					_direction = _direction * -1
					_set_sprite_orientation(_direction)
				_rested_time = 0.0
				_state = States.PATROL
				return
		States.DEATH:
			_velocity += Vector2.DOWN * _death_acceleration * delta
			_velocity.y = clamp(_velocity.y, -_max_patrol_speed, _max_patrol_speed)
			move_and_collide(_velocity * delta)


func is_collision_with_world(collision: KinematicCollision2D) -> bool:
	if collision and collision.collider is TileMap:
		return true
	return false


func _set_sprite_orientation(direction: Vector2) -> void:
	var sign_value: int = sign(direction.x)
	_sprite.flip_h = true if sign_value < 0 else false

	var _player_detector_scale := Vector2(sign_value, 0.0)
	_charge_detector_high.set_deferred("scale", _player_detector_scale)
	_charge_detector_low.set_deferred("scale", _player_detector_scale)


# To get left or right direction, without verticality
func _get_simplified_direction(direction: Vector2) -> Vector2:
	var sign_value: int = sign(direction.x)
	var direction_x = -1.0 if sign_value < 0 else 1.0
	return Vector2(direction_x, 0.0)


func _prepare_death_state() -> void:
	_sprite.flip_v = true
	_velocity = Vector2.ZERO
	_state = States.DEATH

	$Hurtbox.set_deferred("monitorable", false)
	$Hitbox.set_deferred("monitoring", false)
	_charge_detector_high.set_deferred("enabled", false)
	_charge_detector_low.set_deferred("enabled", false)

	# Disable KinematicBody collision with the player layer
	call_deferred("set_collision_mask_bit", 0, false)


func _flash_before_vanish() -> void:
	for i in range(5):
		_sprite.hide()
		yield(get_tree().create_timer(0.05), "timeout")
		_sprite.show()
		yield(get_tree().create_timer(0.05), "timeout")

	queue_free()


func propagate_effects(effects: Dictionary = {}) -> void:
	.propagate_effects(effects)
	if hitpoints == 0:
		_prepare_death_state()
		yield(get_tree().create_timer(1), "timeout")
		_flash_before_vanish()


func _check_charge_collision() -> void:
	if _charge_detector_high.is_colliding() or _charge_detector_low.is_colliding():
		_direction = _get_simplified_direction(_direction)
		_state = States.ROAR


func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		var direction = (area.owner.global_position - global_position).normalized()
		area.owner.propagate_effects({Enums.Effects.DAMAGE: 5, Enums.Effects.PUSH: direction * 150.0 })


func _on_PlayerDetector_body_entered(body: KinematicBody2D) -> void:
	_target_body = body


func _on_PlayerDetector_body_exited(body: KinematicBody2D) -> void:
	_target_body = null
	_velocity = Vector2.ZERO
