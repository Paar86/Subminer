extends Node2D

onready var PositionUp: Position2D = $PositionUp
onready var PositionLeft: Position2D = $PositionLeft
onready var PositionRight: Position2D = $PositionRight
# For big chunks of debris, small ones will be random
onready var _spawn_direction_up: Vector2 = PositionUp.position.normalized()
onready var _spawn_direction_left: Vector2 = PositionLeft.position.normalized()
onready var _spawn_direction_right: Vector2 = PositionRight.position.normalized()
onready var _big_debris_1_resource := preload("res://assets/player_debris/big_debris_1.png")
onready var _big_debris_2_resource := preload("res://assets/player_debris/big_debris_2.png")
onready var _big_debris_3_resource := preload("res://assets/player_debris/big_debris_3.png")

var _debris_fragment_scene := preload("res://src/Player/PlayerDebrisFragment.tscn")

var _debris_resources_array: Array = [
	preload("res://assets/player_debris/small_debris_1.png"),
	preload("res://assets/player_debris/small_debris_2.png"),
	]

var _angle_modifier_rad := deg2rad(25.0)
var _explosion_strength := 50.0
var _small_debris_count := 10.0
var _random_generator := RandomNumberGenerator.new()


func launch_debris() -> void:
	_launch_big_debris()
	_launch_small_debris()


func _ready() -> void:
	_random_generator.randomize()


func _launch_big_debris() -> void:
	var big_debris_up = _debris_fragment_scene.instance()
	var big_debris_left = _debris_fragment_scene.instance()
	var big_debris_right = _debris_fragment_scene.instance()
	big_debris_up.set_sprite(_big_debris_2_resource)
	big_debris_left.set_sprite(_big_debris_1_resource)
	big_debris_right.set_sprite(_big_debris_3_resource)

	var big_debris_array: Array = [big_debris_up, big_debris_left, big_debris_right]
	for big_debris in big_debris_array:
		big_debris.global_position = global_position
		get_parent().get_parent().call_deferred("add_child", big_debris)

	big_debris_up.give_impulse(_explosion_strength * _get_randomized_velocity(_spawn_direction_up))
	big_debris_left.give_impulse(_explosion_strength * _get_randomized_velocity(_spawn_direction_left))
	big_debris_right.give_impulse(_explosion_strength * _get_randomized_velocity(_spawn_direction_right))


func _launch_small_debris() -> void:
	var debris_variations_count: int = _debris_resources_array.size()

	for i in _small_debris_count:
		var direction := Vector2.UP
		direction = direction.rotated(_random_generator.randf_range(0.0, TAU))
		var debris_variation = _debris_resources_array[_random_generator.randi_range(0, debris_variations_count - 1)]

		var small_debris = _debris_fragment_scene.instance()
		small_debris.global_position = global_position
		small_debris.set_sprite(debris_variation)
		get_parent().get_parent().call_deferred("add_child", small_debris)
		small_debris.give_impulse(_random_generator.randf_range(_explosion_strength - 5.0, _explosion_strength + 5.0)
																* direction)


func _get_randomized_velocity(velocity: Vector2) -> Vector2:
	return velocity.rotated(_random_generator.randf_range(deg2rad(-_angle_modifier_rad), deg2rad(_angle_modifier_rad)))
