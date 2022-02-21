"""
Base script for all kinds of mineral bodies
"""
extends GameActor

export var hitpoints_override := 60
export var fragment_spawn_direction := Vector2.UP

# These nodes need to be present in the inheriting scene otherwise error will be logged
var _sprite: Sprite
var _smoke_particles_origin: Position2D
var _fragment_spawn_point: Position2D

var _smoke_particles_scene := preload("res://src/Common/SmokeParticles.tscn")
var _fragment_scene := preload("res://src/Pickups/Fragment.tscn")
var _fragment_impulse_force_min := 20.0
var _fragment_impulse_force_max := 60.0

# Next hitpoints value after which there'll be a sprite change
var damage_phase_threshold: int
# How much should the damage phase threshold be lowered when neccessary
var damage_threshold_modifier: int

func _ready() -> void:
	_sprite = $Sprite
	_smoke_particles_origin = $SmokeParticlesOrigin
	_fragment_spawn_point = $FragmentSpawnOrigin

	hitpoints = hitpoints_override
	damage_threshold_modifier = ceil(hitpoints / 3.0)
	update_damage_threshold()


func propagate_effects(effects: Dictionary = {}) -> void:
	.propagate_effects(effects)

	if hitpoints <= 0:
		# Spit final fragments
		spawn_fragments(4)
		create_smoke_effect()
		queue_free()

	if hitpoints <= damage_phase_threshold:
		# Spit fragments
		update_damage_threshold()
		if change_sprite_frame():
			spawn_fragments(2)
			create_smoke_effect()


func update_damage_threshold() -> void:
	var new_value = hitpoints - damage_threshold_modifier
	if new_value > 0:
		damage_phase_threshold = new_value


func change_sprite_frame() -> bool:
	if _sprite.frame < _sprite.hframes - 1:
		_sprite.frame = _sprite.frame + 1
		return true

	return false


func create_smoke_effect() -> void:
	var smoke_instance = _smoke_particles_scene.instance()
	smoke_instance.global_position = $SmokeParticlesOrigin.global_position
	get_parent().call_deferred("add_child", smoke_instance)


func spawn_fragments(number_of_fragments: int) -> void:
	for i in number_of_fragments:
		var fragment_instance = _fragment_scene.instance()
		fragment_instance.global_position = _fragment_spawn_point.global_position
		var impulse_direction = fragment_spawn_direction.rotated(rand_range(deg2rad(-45.0), deg2rad(45.0)))
		var impulse_force = rand_range(_fragment_impulse_force_min, _fragment_impulse_force_max)
		fragment_instance.give_impulse(impulse_direction * impulse_force)
		get_parent().call_deferred("add_child", fragment_instance)
