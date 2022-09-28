extends Area2D

var _splash_damage_extents_max := 48.0
var _default_damage := 10
var _push_strength := 150

onready var CollisionShapeNode := $CollisionShape2D

onready var _big_explosion_scene := preload("res://src/Common/BigExplosion.tscn")

func _ready() -> void:
	var explosion_scene = _big_explosion_scene.instance()
	if !(explosion_scene is AnimatedSprite):
		assert(false)
	
	CollisionShapeNode.shape.radius = _splash_damage_extents_max

	explosion_scene.connect("animation_finished", self, "_on_explosion_animation_finished")
	explosion_scene.global_position = global_position
	get_parent().add_child(explosion_scene)

func _physics_process(delta: float) -> void:
	var overlapping_areas = get_overlapping_areas()
	for overlapping_area in overlapping_areas:
		if overlapping_area.owner is GameActor:
			var explosion_effect = _calculate_explosion_effect(overlapping_area.owner)
			overlapping_area.owner.propagate_effects(explosion_effect)
	
	# We want to propagate explosion damage only in the first frame
	set_physics_process(false)


func _on_explosion_animation_finished():
	queue_free()
	

func _calculate_explosion_effect(target: GameActor) -> Dictionary:
	var distance_vector := (target.global_position - global_position)
	var distance_length := max(distance_vector.length(), 0.01)
	
	var effect_percent := 1 - distance_length / _splash_damage_extents_max
	
	# Minimum damage is 3, minimum push strength is 20
	var damage = max(_default_damage * effect_percent, 3)
	var push = max(_push_strength * effect_percent, 30)
	
	return {Enums.Effects.DAMAGE: damage, Enums.Effects.PUSH: distance_vector.normalized() * push}
