extends GameActor

var _hitpoints_override := 20
var _damage := 5
var _push_strength := 150.0

enum States { IDLE, FOLLOW, ROAR, CHARGE, REST, DEATH }
var _state = States.IDLE

onready var SpriteNode: Sprite = $Sprite
onready var ChargeDetectorHigh: RayCast2D = $ChargeDetectorHigh
onready var ChargeDetectorLow: RayCast2D = $ChargeDetectorLow
onready var RaycastVisibility: RayCast2D = $RayCastVisibility
onready var ChargeTimer: Timer = $ChargeCooldown
onready var AnimationPlayerNode = $AnimationPlayer

var _roar_sfx_path := "res://assets/sfx/fishRoar.wav"
var _charge_sfx_path := "res://assets/sfx/fishCharge.wav"

var _smoke_effect := preload("res://src/Common/SmokeParticles.tscn")

var _target_body: KinematicBody2D = null
var _can_charge := true
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


func propagate_effects(effects: Dictionary = {}) -> void:
	.propagate_effects(effects)
	if _hitpoints == 0:
		_prepare_death_state()


func flip_horizontally() -> void:
	self._direction_basic *= -1


func _ready() -> void:
	_shake_default_position =  SpriteNode.position
	_hitpoints = _hitpoints_override
	_set_sprite_orientation(_direction_basic)


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
	SpriteNode.position.y = _starting_position.y + sin(_time * _move_frequency) * _move_distance

	if _is_target_body_visible():
		SpriteNode.position.y = _starting_position.y
		_time = 0.0
		_state = States.FOLLOW


func _follow_state(delta: float) -> void:
	if !_is_target_body_visible():
		_state = States.IDLE
		AnimationPlayerNode.play("IDLE")
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
	SpriteNode.position.y = _shake_default_position.y + sin(_time * _shake_frequency) * _shake_distance
	_shake_distance -= delta * 5.0
	# Transition to CHARGE state at the end of shake animation
	if _shake_distance <= 0.0:
		_shake_distance = _shake_default_distance
		# TODO: Make a sound
		_direction = self._direction_basic
		_time = 0.0
		_state = States.CHARGE
		AnimationPlayerNode.play("CHARGE")
		AudioStreamManager2D.play_sound(_charge_sfx_path, self)
		
		BubbleGenerator.generate_bubbles_in_rect_with_delay(
			self,
			8.0,
			8.0,
			get_parent(),
			10,
			0.03
		)
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
			AnimationPlayerNode.play("IDLE")
			return

	if collisions_number > 0:
		_state = States.IDLE
		AnimationPlayerNode.play("IDLE")
		return


func _rest_state(delta: float) -> void:
	_rested_time += delta
	if _rested_time >= _rest_duration:
		_direction = self._direction_basic * -1
		_set_sprite_orientation(_direction)
		_rested_time = 0.0
		_state = States.IDLE
		AnimationPlayerNode.play("IDLE")
		return


func _death_state(delta: float) -> void:
	queue_free()


func _prepare_death_state() -> void:
	.create_explosion()
	_state = States.DEATH


func _set_sprite_orientation(direction_basic: Vector2) -> void:
	SpriteNode.flip_h = true if direction_basic.x < 0 else false

	var _player_detector_scale := Vector2(direction_basic.x, 0.0)
	ChargeDetectorHigh.set_deferred("scale", _player_detector_scale)
	ChargeDetectorLow.set_deferred("scale", _player_detector_scale)


func _check_charge_detectors_colliding() -> void:
	var high_collider := ChargeDetectorHigh.get_collider() as PhysicsBody2D
	var low_collider := ChargeDetectorLow.get_collider() as PhysicsBody2D

	if !high_collider or !low_collider:
		return

	if high_collider.is_in_group("Player") and low_collider.is_in_group("Player"):
		_can_charge = false
		ChargeTimer.start()
		_state = States.ROAR
		AnimationPlayerNode.play("PREPARE_CHARGE")
		AudioStreamManager2D.play_sound(_roar_sfx_path, self)


func _is_target_body_visible() -> bool:
	if !_target_body:
		return false

	var to_target = _target_body.global_position - RaycastVisibility.global_position
	RaycastVisibility.cast_to = to_target
	if RaycastVisibility.is_colliding():
		return false

	return true


func _get_direction_basic() -> Vector2:
	var direction_basic = Vector2.LEFT if _direction.x < 0 else Vector2.RIGHT
	return direction_basic


func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		var calculated_damage = _damage if _state == States.CHARGE else _damage / 2
		var direction = (area.owner.global_position - global_position).normalized()
		area.owner.propagate_effects({Enums.Effects.DAMAGE: calculated_damage, Enums.Effects.PUSH: direction * _push_strength })


func _on_PlayerDetector_body_entered(body: KinematicBody2D) -> void:
	_target_body = body


func _on_PlayerDetector_body_exited(body: KinematicBody2D) -> void:
	_target_body = null


func _on_ChargeCooldown_timeout() -> void:
	_can_charge = true


func _on_VisibilityEnabler2D_screen_exited() -> void:
	_state = States.IDLE
	AnimationPlayerNode.play("IDLE")
