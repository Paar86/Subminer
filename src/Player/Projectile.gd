extends Area2D

export var speed := 400.0
var projectile_explosion := preload("res://src/Player/ProjectileExplosion.tscn")


func _physics_process(delta: float) -> void:
	translate(transform.x * speed * delta)


func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()


func create_explosion(global_position: Vector2) -> void:
	var new_explosion = projectile_explosion.instance()
	new_explosion.global_position = global_position
	get_parent().call_deferred("add_child", new_explosion)
	queue_free()


# For enemies' hurtboxes
func _on_Projectile_area_entered(area: Area2D):
	if area.owner is GameActor:
		#area.owner.propagate_damage(1.0)
		area.owner.propagate_effects({Enums.Effects.DAMAGE: 1})
	create_explosion(global_position)


# For world tiles
func _on_Projectile_body_entered(body):
	if body is TileMap:
		create_explosion(global_position)
