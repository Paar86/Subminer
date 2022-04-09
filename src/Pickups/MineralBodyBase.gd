extends GameActor

var fragment_spawn_direction := Vector2.UP

# These nodes need to be present in the inheriting scene otherwise error will be logged
onready var SpriteNode: Sprite = $Sprite
onready var SmokeParticlesOrigin: Position2D = $SmokeParticlesOrigin
onready var FragmentSpawnPoint: Position2D = $FragmentSpawnOrigin

var _smoke_particles_scene := preload("res://src/Common/SmokeParticles.tscn")
var _fragment_scene := preload("res://src/Pickups/Fragment.tscn")
var _hitpoints_override := 60
var _fragment_impulse_force_min := 20.0
var _fragment_impulse_force_max := 60.0

# Next hitpoints value after which there'll be a sprite change
var _damage_phase_threshold: int
# How much should the damage phase threshold be lowered when neccessary
var _damage_threshold_modifier: int


func flip_vertically() -> void:
	scale.y *= -1
	fragment_spawn_direction.y *= -1
	
	
func flip_horizontally() -> void:
	scale.x *= -1
	fragment_spawn_direction.x *= -1


func _ready() -> void:
	_hitpoints = _hitpoints_override
	_damage_threshold_modifier = ceil(_hitpoints / 3.0)
	update_damage_threshold()


func propagate_effects(effects: Dictionary = {}) -> void:
	.propagate_effects(effects)

	if _hitpoints <= 0:
		# Spit final fragments
		spawn_fragments(4)
		create_smoke_effect()
		queue_free()

	if _hitpoints <= _damage_phase_threshold:
		# Spit fragments
		update_damage_threshold()
		if change_sprite_frame():
			spawn_fragments(2)
			create_smoke_effect()


func update_damage_threshold() -> void:
	var new_value = _hitpoints - _damage_threshold_modifier
	if new_value > 0:
		_damage_phase_threshold = new_value


func change_sprite_frame() -> bool:
	if SpriteNode.frame < SpriteNode.hframes - 1:
		SpriteNode.frame = SpriteNode.frame + 1
		return true

	return false


func create_smoke_effect() -> void:
	var smoke_instance = _smoke_particles_scene.instance()
	smoke_instance.global_position = $SmokeParticlesOrigin.global_position
	get_parent().call_deferred("add_child", smoke_instance)


func spawn_fragments(number_of_fragments: int) -> void:
	for i in number_of_fragments:
		var fragment_instance = _fragment_scene.instance()
		fragment_instance.global_position = FragmentSpawnPoint.global_position
		var impulse_direction = fragment_spawn_direction.rotated(rand_range(deg2rad(-45.0), deg2rad(45.0)))
		var impulse_force = rand_range(_fragment_impulse_force_min, _fragment_impulse_force_max)
		fragment_instance.give_impulse(impulse_direction * impulse_force)
		get_parent().call_deferred("add_child", fragment_instance)
