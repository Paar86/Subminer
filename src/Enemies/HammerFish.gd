extends GameActor

export var hitpoints_override := 40

enum Directions { LEFT, RIGHT }
export(Directions) var initial_direction = Directions.RIGHT

enum States { PATROL, ROAR, CHARGE, REST, DEATH }
var _state = States.PATROL

onready var _sprite: Sprite = $Sprite
onready var _player_detector_high: RayCast2D = $PlayerDetectorHigh
onready var _player_detector_low: RayCast2D = $PlayerDetectorLow

var _smoke_effect := preload("res://src/Common/SmokeParticles.tscn")
var _direction := Vector2.RIGHT
var _max_patrol_speed := 50.0
var _patrol_acceleration := 50.0
var _death_acceleration := 30.0
var _velocity := Vector2.ZERO
var _charge_speed := _max_patrol_speed * 6.0
var _is_resting := false

var _time := 0.0
var _shake_duration := 1.0
var _shake_default_position: Vector2
var _shake_default_distance: float = 3.0
var _shake_distance: float = _shake_default_distance
var _shake_frequency: float = 50.0

func _ready() -> void:
	_shake_default_position =  _sprite.position
	hitpoints = hitpoints_override
	if initial_direction == Directions.LEFT:
			_flip_direction()


func _physics_process(delta: float) -> void:

	match _state:
		States.PATROL:
			_velocity += _direction * _patrol_acceleration * delta
			_velocity.x = clamp(_velocity.x, -_max_patrol_speed, _max_patrol_speed)

			var collision := move_and_collide(_velocity * delta)
			if collision:
				_velocity = Vector2.ZERO
				_state = States.REST
				return

			if _player_detector_high.is_colliding() or _player_detector_low.is_colliding():
				_state = States.ROAR
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
			if !_is_resting:
				_rest()
		States.DEATH:
			_velocity += Vector2.DOWN * _death_acceleration * delta
			_velocity.y = clamp(_velocity.y, -_max_patrol_speed, _max_patrol_speed)
			move_and_collide(_velocity * delta)


func is_collision_with_world(collision: KinematicCollision2D) -> bool:
	if collision and collision.collider is TileMap:
		return true
	return false


func _flip_direction() -> void:
	_direction = _direction * -1
	_sprite.flip_h = !_sprite.flip_h

	var _player_detector_scale := Vector2(_direction.x, 0.0)
	_player_detector_high.set_deferred("scale", _player_detector_scale)
	_player_detector_low.set_deferred("scale", _player_detector_scale)


func _rest() -> void:
	_is_resting = true
	yield(get_tree().create_timer(1), "timeout")
	
	# This is here because we can return to this function after setting DEATH state, because of yielding
	# Maybe there's a better way to handle it?
	if _state == States.DEATH:
		return
		
	var collision = move_and_collide(_direction, true, true, true)
	if is_collision_with_world(collision):
		_flip_direction()
	_state = States.PATROL
	_is_resting = false


func _prepare_death_state() -> void:
	_sprite.flip_v = true
	_velocity = Vector2.ZERO
	_state = States.DEATH

	$Hurtbox.set_deferred("monitorable", false)
	$Hitbox.set_deferred("monitoring", false)
	_player_detector_high.set_deferred("enabled", false)
	_player_detector_low.set_deferred("enabled", false)

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


func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		var direction = (area.owner.global_position - global_position).normalized()
		area.owner.propagate_effects({Enums.Effects.DAMAGE: 5, Enums.Effects.PUSH: direction * 150.0 })
