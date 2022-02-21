extends KinematicBody2D

export var gravity_max := 200.0
export var gravity_accel := 100.0

export var thrust_power_max := 300.0
export var thrust_accel := 150.0

export var steering_power_max := 250.0
export var steering_accel := 100.0
export var air_friction := 50.0

export var rate_of_fire := 0.05

var horizontal_direction := 0.0
var thrust_modifier := 0.0
var velocity := Vector2(0.0, 0.0)
var is_firing := false

onready var projectiles_container := $BulletsContainer
onready var left_cannon := $CannonLeftPivot
onready var right_cannon := $CannonRightPivot
onready var left_cannon_point := $CannonLeftPivot/CannonLeft/BulletSpawnPoint
onready var right_cannon_point := $CannonRightPivot/CannonRight/BulletSpawnPoint

var projectile_scene := preload("res://src/Player/Projectile.tscn")


func _process(delta: float) -> void:
	horizontal_direction = Input.get_action_strength("right") - Input.get_action_strength("left")
	thrust_modifier = 1.0 if Input.is_action_pressed("thrust") else 0.0
	
	if Input.is_action_pressed("fire") and !is_firing:
		fire_cannons()


func _physics_process(delta: float) -> void:
	# Calculate vertical velocity
	var gravity_modifier: float = 1.0 if thrust_modifier == 0.0 else 0.0
	var velocity_vert: Vector2 = (Vector2.UP * thrust_accel * delta * thrust_modifier) + (Vector2.DOWN * gravity_modifier * gravity_accel * delta)
	
	# Calculate horizontal velocity
	var velocity_horiz: Vector2 = (Vector2.RIGHT * horizontal_direction * steering_accel * delta)
	# Calculate friction
	if horizontal_direction == 0.0:
		velocity_horiz = Vector2.LEFT * sign(velocity.x) * air_friction * delta
	
	velocity += velocity_vert + velocity_horiz	
	# For situations when applying friction would change a sign of the x axis
	if abs(velocity.x) < air_friction * delta:
		velocity.x = 0.0
		
	clamp(velocity.y, -thrust_power_max, gravity_max)
	clamp(velocity.x, -steering_power_max, steering_power_max)
	
	velocity = move_and_slide(velocity)


func fire_cannons() -> void:
	is_firing = true
	spawn_projectile(left_cannon_point.global_position, left_cannon.rotation)
#	print("left_cannon_fired")
	yield(get_tree().create_timer(rate_of_fire), "timeout")
	spawn_projectile(right_cannon_point.global_position, right_cannon.rotation)
#	print("right_cannon_fired")
	yield(get_tree().create_timer(rate_of_fire), "timeout")
	is_firing = false
	
	
func spawn_projectile(global_position: Vector2, angle_rad: float) -> void:
	var projectile_instance = projectile_scene.instance()
	projectile_instance.global_position = global_position
	projectile_instance.rotation = angle_rad
	projectiles_container.add_child(projectile_instance)
