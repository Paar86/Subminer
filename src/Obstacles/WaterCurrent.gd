tool
extends Area2D

export var direction := Vector2.RIGHT setget _set_direction

onready var ParticlesNode: Particles2D = $Particles2D
onready var CollisionShapeNode: CollisionShape2D = $CollisionShape2D

# Number of particles is emitter surface (x * y) devided by this modifier (smaller number means more particles)
var _particles_density_modifier := 12.0
var _push_force := 80.0


# Properties
func _set_direction(value: Vector2) -> void:
	value = value.normalized()
	get_node("Particles2D").process_material.direction = Vector3(value.x, value.y, 0.0)
	direction = value


func _process(delta: float) -> void:
	# To set and see the particles in the editor
	if Engine.editor_hint:
		var collision_shape = get_node("CollisionShape2D")
		var collision_extents = collision_shape.shape.extents
		var particles_node = get_node("Particles2D")
		var enemy_blocker_shape = get_node("EnemyBlocker/CollisionShape2D")

#		if particles_node.position != collision_shape.position:
#			particles_node.position = collision_shape.position
#
#		if enemy_blocker.position != position:
#			enemy_blocker.position = position

		var new_box_extents = Vector3(collision_extents.x, collision_extents.y, 0.0)
		if particles_node.process_material.emission_box_extents != new_box_extents:
			particles_node.process_material.emission_box_extents = new_box_extents

		if enemy_blocker_shape.shape.extents != Vector2(new_box_extents.x, new_box_extents.y):
			enemy_blocker_shape.shape.extents = Vector2(new_box_extents.x, new_box_extents.y)

		var number_of_particles = int(collision_extents.x  * collision_extents.y / _particles_density_modifier)
		if particles_node.amount != number_of_particles:
			particles_node.amount = number_of_particles


func _on_WaterCurrent_body_entered(body: Node) -> void:
	if body is GameActor:
		body.propagate_effects({Enums.Effects.ADD_CONSTANT_PUSH: direction * _push_force})


func _on_WaterCurrent_body_exited(body: Node) -> void:
	if body is GameActor:
		body.propagate_effects({Enums.Effects.REMOVE_CONSTANT_PUSH: direction * _push_force})
