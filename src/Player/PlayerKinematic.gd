extends GameActor

signal weapon_overheated
signal player_ready

enum States { IDLE, MOVE, DRIFT }

var _gravity_max := 30.0
var _gravity_accel := 10.0
var _dash_power := 160.0
var _thrust_power_max := 90.0
var _thrust_accel := 150.0
var _friction := 90.0
var _rate_of_fire := 0.1
var _dash_timeout := 1.5

var _heat_increment := 2.0
var _heat_cooldown_interval := _rate_of_fire / 1.5
var _heat_timer := 0.0
var _is_overheated := false

var _player_stats := PlayerStats
var _is_invincible: bool setget _set_invincibility, _get_invincibility
var _dash_enabled := true
# Final velocity (primary and secondary combined)
var _velocity := Vector2(0.0, 0.0)
# Primary velocity for player movement based on pressed keys
var _velocity_primary := Vector2(0.0, 0.0)
# Secondary velocity for water currents
var _velocity_secondary := Vector2(0.0, 0.0)
# All constant effects
var _constant_velocity_buffer := []
var _is_firing := false
var _state: int = States.IDLE
var _input_direction = Vector2.ZERO

onready var MainSprite: Sprite = $Sprite
onready var CannonLeftSprite: Sprite = $CannonLeftPivot/CannonLeft
onready var CannonRightSprite: Sprite = $CannonRightPivot/CannonRight
onready var ProjectilesContainer: Node = $BulletsContainer
onready var LeftCannon: Position2D = $CannonLeftPivot
onready var RightCannon: Position2D = $CannonRightPivot
onready var LeftCannonPoint: Position2D = $CannonLeftPivot/CannonLeft/BulletSpawnPoint
onready var RightCannonPoint: Position2D = $CannonRightPivot/CannonRight/BulletSpawnPoint
onready var HurtBox := $Hurtbox
onready var DebrisSpawner := $DebrisSpawner
onready var TeleportEffect := $TeleportEffect

var _big_explosion_scene := preload("res://src/Common/BigExplosion.tscn")
var _projectile_scene := preload("res://src/Player/PlayerProjectile.tscn")
var _shoot_sfx_path := "res://assets/sfx/shoot.wav"


# Properties
func _set_invincibility(value: bool) -> void:
	_is_invincible = value
	var collision_layer_value = 0 if value else 1
	HurtBox.set_deferred("collision_layer", collision_layer_value)


func _get_invincibility() -> bool:
	return _is_invincible


func _get_direction() -> Vector2:
	var horizontal_direction = Input.get_action_strength("right") - Input.get_action_strength("left")
	var vertical_direction = Input.get_action_strength("down") - Input.get_action_strength("up")
	return Vector2(horizontal_direction, vertical_direction).normalized()


# Functions
func show_player() -> void:
	MainSprite.show()
	CannonLeftSprite.show()
	CannonRightSprite.show()


func hide_player() -> void:
	MainSprite.hide()
	CannonLeftSprite.hide()
	CannonRightSprite.hide()


func propagate_effects(effects: Dictionary = {}) -> void:
	if !_is_invincible:
		if Enums.Effects.DAMAGE in effects:
			_start_damage_flashing()
			PlayerStats.hitpoints -= effects[Enums.Effects.DAMAGE]
		if Enums.Effects.PUSH in effects:
			var push_velocity: Vector2 = effects[Enums.Effects.PUSH]
			_velocity_primary = push_velocity
			_state = States.DRIFT

	if Enums.Effects.MINERALS in effects:
		PlayerStats.minerals += effects[Enums.Effects.MINERALS]
	if Enums.Effects.ADD_CONSTANT_PUSH in effects:
		_add_constant_effect(effects[Enums.Effects.ADD_CONSTANT_PUSH])
	if Enums.Effects.REMOVE_CONSTANT_PUSH in effects:
		_remove_constant_effect(effects[Enums.Effects.REMOVE_CONSTANT_PUSH])


func _ready() -> void:
	hide_player()

	TeleportEffect.connect("teleport_in_finished", self, "_on_teleport_in_finished")
	TeleportEffect.connect("teleport_out_finished", self, "_on_teleport_out_finished")

	PlayerStats.connect("weapon_overheated", self, "_on_weapon_overheated")
	PlayerStats.connect("weapon_cooled", self, "_on_weapon_cooled")
	PlayerStats.connect("hitpoints_depleted", self, "_on_hitpoints_depleted")


func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("dash") and _state == States.MOVE and _dash_enabled):
		_dash_enabled = false
		_velocity_primary = _input_direction * _dash_power
		_state = States.DRIFT
		yield(get_tree().create_timer(_dash_timeout), "timeout")
		_dash_enabled = true


func _physics_process(delta: float) -> void:
	_input_direction = _get_direction()

	match _state:
		States.IDLE:
			# Either players presses a direction key or gets into a water current
			if _input_direction != Vector2.ZERO or _velocity_secondary != Vector2.ZERO:
				_state = States.MOVE

			_velocity_primary.y += _gravity_accel * delta
			if _velocity_primary.y > _gravity_max:
				_velocity_primary.y = _gravity_max

			# Threshold to allow sliding on corners
			if _velocity_primary.length() > _gravity_max:
				_velocity_primary = _apply_friction(_velocity_primary, true, true, delta)
		States.MOVE:
			_velocity_primary += _thrust_accel * _input_direction * delta
			if _velocity_primary.length() > _thrust_power_max:
				_velocity_primary = _velocity_primary.normalized() * _thrust_power_max

			var friction_on_x = true if _input_direction.x == 0.0 else false
			var friction_on_y = true if _input_direction.y == 0.0 else false
			_velocity_primary = _apply_friction(_velocity_primary, friction_on_x, friction_on_y, delta)

			if _velocity == Vector2.ZERO:
				_state = States.IDLE
		States.DRIFT:
			# We only need to apply friction in this state
			_velocity_primary = _apply_friction(_velocity_primary, true, true, delta)
			if (_velocity_primary.length() < _thrust_power_max):
				_state = States.MOVE

	_velocity = move_and_slide(_velocity_primary + _velocity_secondary)

	# To remove stickiness when hitting a wall and not in a current
	if _velocity.x == 0.0 and _constant_velocity_buffer.size() == 0:
		_velocity_primary.x = _velocity.x
		_velocity_secondary.x = _velocity.x
	if _velocity.y == 0.0 and _constant_velocity_buffer.size() == 0:
		_velocity_primary.y = _velocity.y
		_velocity_secondary.y = _velocity.y

	# To leave water currents more smoothly
	if _velocity_secondary != Vector2.ZERO and _constant_velocity_buffer.size() == 0:
		_velocity_secondary = _apply_friction(_velocity_secondary, true, true, delta)

	# We should be able to fire anytime
	if Input.is_action_pressed("fire") and !_is_firing and !_is_overheated:
		_fire_cannons()

	# Weapon cooldown
	if !_is_firing and PlayerStats.heat_value > 0.0:
		_heat_timer += delta
		if _heat_timer >= _heat_cooldown_interval:
			PlayerStats.heat_value -= _heat_increment
			_heat_timer = 0.0


func _apply_friction(velocity: Vector2, x_axis: bool, y_axis: bool, delta: float) -> Vector2:
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

	return velocity


func _fire_cannons() -> void:
	_is_firing = true
	_spawn_projectile(LeftCannonPoint.global_position, LeftCannon.rotation)
	PlayerStats.heat_value += _heat_increment
	yield(get_tree().create_timer(_rate_of_fire), "timeout")
	AudioStreamManager.play_sound(_shoot_sfx_path)
	_spawn_projectile(RightCannonPoint.global_position, RightCannon.rotation)
	PlayerStats.heat_value += _heat_increment
	yield(get_tree().create_timer(_rate_of_fire), "timeout")
	AudioStreamManager.play_sound(_shoot_sfx_path)
	_is_firing = false


func _spawn_projectile(global_position: Vector2, angle_rad: float) -> void:
	var projectile_instance = _projectile_scene.instance()
	projectile_instance.global_position = global_position
	projectile_instance.rotation = angle_rad
	ProjectilesContainer.add_child(projectile_instance)


func _start_damage_flashing() -> void:
	self._is_invincible = true

	for i in 20:
		MainSprite.hide()
		CannonLeftSprite.hide()
		CannonRightSprite.hide()
		yield(get_tree().create_timer(0.05), "timeout")
		MainSprite.show()
		CannonLeftSprite.show()
		CannonRightSprite.show()
		yield(get_tree().create_timer(0.05), "timeout")

	self._is_invincible = false


func _on_hitpoints_depleted() -> void:
	visible = false
	$BodyCollision.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitorable", false)
	set_physics_process(false)

	DebrisSpawner.launch_debris()

	var explosion = _big_explosion_scene.instance()
	explosion.global_position = global_position
	get_parent().add_child(explosion)


func _on_weapon_overheated() -> void:
	_is_overheated = true


func _on_weapon_cooled() -> void:
	_is_overheated = false


func _add_constant_effect(velocity: Vector2) -> void:
	_constant_velocity_buffer.append(velocity)
	_recalculate_velocity_secondary()


func _remove_constant_effect(velocity: Vector2) -> void:
	if _constant_velocity_buffer.has(velocity):
		_constant_velocity_buffer.erase(velocity)
	_recalculate_velocity_secondary()


# If there are duplicate contants effects, we will apply them only once
func _recalculate_velocity_secondary() -> void:
	# We want the remnant of the secondary velocity to by removed by friction for smooth effect
	if _constant_velocity_buffer.size() == 0:
		return

	var constant_velocity_buffer_unique = []

	for value in _constant_velocity_buffer:
		var unique_value_found = false
		# We allow only one unique direction, but will always pick the bigger length
		for unique_value in constant_velocity_buffer_unique:
			if value.normalized() == unique_value.normalized():
				constant_velocity_buffer_unique.erase(unique_value)
				var new_unique_value = unique_value.normalized() * max(value.length(), unique_value.length())
				constant_velocity_buffer_unique.append(new_unique_value)
				unique_value_found = true

		if !unique_value_found:
			constant_velocity_buffer_unique.append(value)

	var new_velocity_secondary = Vector2()
	for value in constant_velocity_buffer_unique:
		new_velocity_secondary += value

	_velocity_secondary = new_velocity_secondary


func _on_teleport_in_finished() -> void:
	emit_signal("player_ready")


func _on_teleport_out_finished() -> void:
	pass
