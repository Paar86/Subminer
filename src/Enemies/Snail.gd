extends GameActor

var hitpoints_override := 15

onready var CliffDetector := $CliffDetector
onready var WallDetector := $WallDetector
onready var ProjectileSpawnPoint1 := $ProjectileSpawnPoint1
onready var ProjectileSpawnPoint2 := $ProjectileSpawnPoint2
onready var ProjectileSpawnPoint3 := $ProjectileSpawnPoint3
onready var ProjectileSpawnPivot := $ProjectileSpawnPivot
onready var ProjectilesTween := $ProjectilesTween
onready var AnimationPlayerScene := $AnimationPlayer
onready var _projectile_spawns_array = [ProjectileSpawnPoint1,
										ProjectileSpawnPoint2,
										ProjectileSpawnPoint3]
onready var _snail_projectile_scene := preload("res://src/Enemies/SnailProjectile.tscn")

var _charging_sfx := preload("res://assets/sfx/snailCharging.wav")
var _shoot_sfx := preload("res://assets/sfx/snailShoot.wav")

var _damage := 3
var _push_strength := 150.0

enum States { REST, PATROL, SHOOT_PREPARE, SHOOT, DEATH }
var _state = States.PATROL
var _rest_duration := 2.0
var _rest_current := 0.0
var _velocity := Vector2()
var _fall_acceleration := 80.0
var _fall_max_speed := 80.0
var _gravity := 50.0
var _patrol_speed := 10.0
var _shoot_interval := 3.0
var _shoot_interval_counter := 0.0
var _projectiles_container_array: Array

var _change_direction := false
var _direction := Vector2.RIGHT

var _loading_projectiles := false
var _tween_buffer: Array


func propagate_effects(effects: Dictionary = {}) -> void:
	.propagate_effects(effects)

	if _hitpoints == 0:
		_state = States.DEATH
		_prepare_death_state()


func transpose() -> void:
	var transform_x: Vector2 = transform.x
	transform.x = transform.y
	transform.y = transform_x


func flip_horizontally() -> void:
#	We must take into a condsideration local transform (when x axis is in fact y)
	if rotation:
		scale.y *= -1.0
		return

	scale.x *= -1.0


func flip_vertically() -> void:
	if rotation:
		scale.x *= -1.0
		return

	scale.y *= -1.0


func _ready() -> void:
	_hitpoints = hitpoints_override
	ProjectilesTween.connect("tween_all_completed", self, "_on_all_tweens_finished")


func _physics_process(delta: float) -> void:
	match _state:
		States.REST:
			_rest_state(delta)
			return
		States.PATROL:
			_patrol_state(delta)
			return
		States.SHOOT_PREPARE:
			_shoot_prepare_state(delta)
			return
		States.SHOOT:
			_shoot_state(delta)
			return
		States.DEATH:
			_death_state(delta)


func _rest_state(delta: float) -> void:
	if _change_direction:
		_change_direction = false
		set_deferred("scale", Vector2(scale.x * -1.0, scale.y))

	_rest_current += delta
	if _rest_current >= _rest_duration:
		_rest_current = 0.0
		_state = States.PATROL
		AnimationPlayerScene.play("MOVE")


func _patrol_state(delta: float) -> void:
	_shoot_interval_counter += delta

	if _shoot_interval_counter >= _shoot_interval:
		_shoot_interval_counter = 0.0
		_state = States.SHOOT_PREPARE
		AnimationPlayerScene.play("SHOOT")
		return

	_velocity = move_and_slide(transform.x * _patrol_speed, Vector2.UP)

	if !CliffDetector.is_colliding() or WallDetector.is_colliding():
		_change_direction = true
		_state = States.REST
		AnimationPlayerScene.play("IDLE")


func _prepare_death_state() -> void:
	_deal_with_projectiles()
	.create_explosion($CollisionShape2D.global_position)
	_state = States.DEATH


func _shoot_prepare_state(delta: float) -> void:
#	AudioStreamManager.play_sound(_charging_sfx_path)

	if !_loading_projectiles:
		_load_projectiles()
		_tween_projectiles()


func _shoot_state(delta: float) -> void:
	AudioStreamManager2D.play_sound(_shoot_sfx, self)

	for projectile in _projectiles_container_array:
		projectile.fire()

	_projectiles_container_array.clear()
	_state = States.REST


func _death_state(delta: float) -> void:
	queue_free()


func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		var target_direction = (area.owner.global_position - global_position).normalized()
		if target_direction == Vector2.ZERO:
			target_direction = Vector2.RIGHT
		(area.owner as GameActor).propagate_effects({
				Enums.Effects.DAMAGE: _damage,
				Enums.Effects.PUSH: target_direction * _push_strength
				})


func _load_projectiles() -> void:
	_projectiles_container_array.clear()
	_loading_projectiles = true
	for i in _projectile_spawns_array.size():
		var projectile_instance = _snail_projectile_scene.instance()
		projectile_instance.global_position = _projectile_spawns_array[i].global_position
		var projectile_direction: Vector2 = (_projectile_spawns_array[i].global_position - ProjectileSpawnPivot.global_position).normalized()
		var angle = Vector2.RIGHT.angle_to(projectile_direction)
		projectile_instance.rotate(angle)
		_projectiles_container_array.append(projectile_instance)
		get_parent().call_deferred("add_child", projectile_instance)


func _tween_projectiles() -> void:
	for projectile in _projectiles_container_array:
		ProjectilesTween.interpolate_property(projectile, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 1.0, Tween.TRANS_LINEAR)

	ProjectilesTween.start()


func _on_all_tweens_finished() -> void:
	_loading_projectiles = false

	for projectile in _projectiles_container_array:
		projectile.ready_to_fire = true

	_state = States.SHOOT
	AnimationPlayerScene.play("IDLE")


func _deal_with_projectiles() -> void:
	for projectile in _projectiles_container_array:
		if projectile.ready_to_fire:
			projectile.fire()
		else:
			projectile.queue_free()

	_projectiles_container_array = []
