extends GameActor

enum states { IDLE, MOVE, DRIFT }

export var _hitpoints_override := 50
export var _gravity_max := 30.0
export var _gravity_accel := 10.0
export var _dash_power := 160.0
export var _thrust_power_max := 90.0
export var _thrust_accel := 150.0
export var _friction := 90.0
export var _rate_of_fire := 0.08
export var _dash_timeout := 1.5

var dash_enabled := true
var velocity := Vector2(0.0, 0.0)
var is_firing := false
var state: int = states.IDLE
var input_direction = Vector2.ZERO
var _is_invincible := false

onready var _main_sprite := $Sprite
onready var _cannon_left_sprite := $CannonLeftPivot/CannonLeft
onready var _cannon_right_sprite := $CannonRightPivot/CannonRight
onready var projectiles_container := $BulletsContainer
onready var left_cannon := $CannonLeftPivot
onready var right_cannon := $CannonRightPivot
onready var left_cannon_point := $CannonLeftPivot/CannonLeft/BulletSpawnPoint
onready var right_cannon_point := $CannonRightPivot/CannonRight/BulletSpawnPoint

var projectile_scene := preload("res://src/Player/Projectile.tscn")


func _ready() -> void:
	hitpoints = _hitpoints_override


func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("dash") and state == states.MOVE and dash_enabled):
		dash_enabled = false
		velocity = input_direction * _dash_power
		state = states.DRIFT
		yield(get_tree().create_timer(_dash_timeout), "timeout")
		dash_enabled = true


func _physics_process(delta: float) -> void:
	input_direction = _get_direction()

	match state:
		states.IDLE:
			if input_direction != Vector2.ZERO:
				state = states.MOVE

			velocity.y += _gravity_accel * delta
			if velocity.y > _gravity_max:
				velocity.y = _gravity_max

			# Threshold to allow sliding on corners
			if velocity.length() > _gravity_max:
				_apply_friction(true, true, delta)
		states.MOVE:
			velocity += _thrust_accel * input_direction * delta
			if (velocity.length() > _thrust_power_max):
				velocity = velocity.normalized() * _thrust_power_max

			var friction_on_x = true if input_direction.x == 0.0 else false
			var friction_on_y = true if input_direction.y == 0.0 else false
			_apply_friction(friction_on_x, friction_on_y, delta)

			if velocity == Vector2.ZERO:
				state = states.IDLE
		states.DRIFT:
			# We only need to apply friction in this state
			_apply_friction(true, true, delta)
			if (velocity.length() < _thrust_power_max):
				state = states.MOVE

	velocity = move_and_slide(velocity)

	# We should be able to fire anytime
	if Input.is_action_pressed("fire") and !is_firing:
		_fire_cannons()


func _get_direction() -> Vector2:
	var horizontal_direction = Input.get_action_strength("right") - Input.get_action_strength("left")
	var vertical_direction = Input.get_action_strength("down") - Input.get_action_strength("up")
	return Vector2(horizontal_direction, vertical_direction).normalized()


func _apply_friction(x_axis: bool, y_axis: bool, delta: float) -> void:
	# Calculate horizontal friction; both axes need to be calculated separatedly
	if x_axis:
		velocity.x += -1.0 * sign(velocity.x) * _friction * delta
		# For situations when applying friction would change a sign of the x axis
		if abs(velocity.x) < _friction * delta:
			velocity.x = 0.0
	# Calculate vertical friction
	if y_axis:
		velocity.y += -1.0 * sign(velocity.y) * _friction * delta
		if abs(velocity.y) < _friction * delta:
			velocity.y = 0.0


func _fire_cannons() -> void:
	is_firing = true
	_spawn_projectile(left_cannon_point.global_position, left_cannon.rotation)
	yield(get_tree().create_timer(_rate_of_fire), "timeout")
	_spawn_projectile(right_cannon_point.global_position, right_cannon.rotation)
	yield(get_tree().create_timer(_rate_of_fire), "timeout")
	is_firing = false


func _spawn_projectile(global_position: Vector2, angle_rad: float) -> void:
	var projectile_instance = projectile_scene.instance()
	projectile_instance.global_position = global_position
	projectile_instance.rotation = angle_rad
	projectiles_container.add_child(projectile_instance)


func _start_damage_flashing() -> void:
	_is_invincible = true

	for i in range(20):
		_main_sprite.hide()
		_cannon_left_sprite.hide()
		_cannon_right_sprite.hide()
		yield(get_tree().create_timer(0.05), "timeout")
		_main_sprite.show()
		_cannon_left_sprite.show()
		_cannon_right_sprite.show()
		yield(get_tree().create_timer(0.05), "timeout")

	_is_invincible = false


func propagate_effects(effects: Dictionary = {}) -> void:
	if !_is_invincible:
		.propagate_effects(effects)
		_start_damage_flashing()

		if hitpoints == 0:
			queue_free()

		if Enums.Effects.PUSH in effects:
			var value: Vector2 = effects[Enums.Effects.PUSH]
			velocity = value
			state = states.DRIFT
