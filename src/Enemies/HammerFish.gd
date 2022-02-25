extends GameActor

export var hitpoints_override := 40
export var damage := 5
export var push_strength := 150.0

enum States { IDLE, FOLLOW, ROAR, CHARGE, REST, DEATH }
var _state = States.IDLE

onready var _sprite: Sprite = $Sprite
onready var _charge_detector_high: RayCast2D = $ChargeDetectorHigh
onready var _charge_detector_low: RayCast2D = $ChargeDetectorLow
onready var _raycast_visibility: RayCast2D = $RayCastVisibility

var _smoke_effect := preload("res://src/Common/SmokeParticles.tscn")
var _velocity := Vector2.ZERO
var _death_acceleration := 30.0
var _max_speed := 40.0
var _charge_speed := _max_speed * 6.0
var _time: float = position.x + position.y
var _direction := Vector2.RIGHT
var _direction_basic: Vector2 setget ,_get_direction_basic

# For IDLE state's sprite waving
var _starting_position: Vector2
var _move_distance: float = 2.0
var _move_frequency: float = 2.0

# For REST state
var _rest_duration := 1.0
var _rested_time := 0.0

# For FOLLOW state
var _mass := 3.0

# For ROAR state
var _shake_duration := 1.0
var _shake_default_position: Vector2
var _shake_default_distance: float = 3.0
var _shake_distance: float = _shake_default_distance
var _shake_frequency: float = 50.0

var _target_body: KinematicBody2D = null


func propagate_effects(effects: Dictionary = {}) -> void:
	.propagate_effects(effects)
	if hitpoints == 0:
		_prepare_death_state()
		yield(get_tree().create_timer(1), "timeout")
		_flash_before_vanish()


func _ready() -> void:
	_shake_default_position =  _sprite.position
	hitpoints = hitpoints_override


func _physics_process(delta: float) -> void:
	match _state:
		States.IDLE:
			_idle_state(delta)
		States.FOLLOW:
			_follow_state(delta)
		States.ROAR:
			_roar_state(delta)
		States.CHARGE:
			_charge_state(delta)
		States.REST:
			_rest_state(delta)
		States.DEATH:
			_death_state(delta)


func _idle_state(delta: float) -> void:
	_time += delta
	_sprite.position.y = _starting_position.y + sin(_time * _move_frequency) * _move_distance
	
	if _is_target_body_visible():
		_sprite.position.y = _starting_position.y
		_time = 0.0
		_state = States.FOLLOW


func _follow_state(delta: float) -> void:
	if !_is_target_body_visible():
		_state = States.IDLE
		return
		
	_check_charge_detectors_colliding()
	
	# Steering behaviour
	var desired_velocity = (_target_body.global_position - global_position).normalized() * _max_speed
	var to_desired_velocity = (desired_velocity - _velocity) / _mass
	_velocity += to_desired_velocity
	
	_direction = _velocity.normalized()
	_set_sprite_orientation(self._direction_basic)
	_velocity = move_and_slide(_velocity)


func _roar_state(delta: float) -> void:
	_time += delta
	_sprite.position.y = _shake_default_position.y + sin(_time * _shake_frequency) * _shake_distance
	_shake_distance -= delta * 5.0
	# Transition to CHARGE state at the end of shake animation
	if _shake_distance <= 0.0:
		_shake_distance = _shake_default_distance
		# TODO: Change sprite
		# TODO: Make a sound
		_direction = self._direction_basic
		_time = 0.0
		_state = States.CHARGE
		return


func _charge_state(delta: float) -> void:
	_velocity = move_and_slide(_direction * _charge_speed)
	var collisions_number = get_slide_count()
	for i in collisions_number:
		var collision = get_slide_collision(i)
		if collision.collider is TileMap:
			var smoke_instance = _smoke_effect.instance()
			smoke_instance.global_position = collision.position
			get_parent().call_deferred("add_child", smoke_instance)
			_state = States.REST
			return
			
	if collisions_number > 0:
		_state = States.IDLE
		return


func _rest_state(delta: float) -> void:
	_rested_time += delta
	if _rested_time >= _rest_duration:
		_direction = self._direction_basic * -1
		_set_sprite_orientation(_direction)
		_rested_time = 0.0
		_state = States.IDLE
		return


func _death_state(delta: float) -> void:
	_velocity += Vector2.DOWN * _death_acceleration * delta
	_velocity.y = clamp(_velocity.y, -_max_speed, _max_speed)
	move_and_collide(_velocity * delta)


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


func _set_sprite_orientation(direction_basic: Vector2) -> void:
	_sprite.flip_h = true if direction_basic.x < 0 else false
	
	var _player_detector_scale := Vector2(direction_basic.x, 0.0)
	_charge_detector_high.set_deferred("scale", _player_detector_scale)
	_charge_detector_low.set_deferred("scale", _player_detector_scale)


func _flash_before_vanish() -> void:
	for i in 5:
		_sprite.hide()
		yield(get_tree().create_timer(0.05), "timeout")
		_sprite.show()
		yield(get_tree().create_timer(0.05), "timeout")

	queue_free()


func _check_charge_detectors_colliding() -> void:
	var high_collider = _charge_detector_high.get_collider()
	var low_collider = _charge_detector_low.get_collider()
	var collider = high_collider if high_collider else low_collider
	if collider:
		var destination = collider.global_position - _raycast_visibility.global_position
		_raycast_visibility.cast_to = destination
		if !_raycast_visibility.is_colliding():
			_state = States.ROAR


func _is_target_body_visible() -> bool:
	if !_target_body:
		return false

	var to_target = _target_body.global_position - _raycast_visibility.global_position
	_raycast_visibility.cast_to = to_target
	if _raycast_visibility.is_colliding():
		return false

	return true
	
	
func _get_direction_basic() -> Vector2:
	var direction_basic = Vector2.LEFT if _direction.x < 0 else Vector2.RIGHT
	return direction_basic


func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		var direction = (area.owner.global_position - global_position).normalized()
		area.owner.propagate_effects({Enums.Effects.DAMAGE: damage, Enums.Effects.PUSH: direction * push_strength })


func _on_PlayerDetector_body_entered(body: KinematicBody2D) -> void:
	_target_body = body


func _on_PlayerDetector_body_exited(body: KinematicBody2D) -> void:
	_target_body = null
