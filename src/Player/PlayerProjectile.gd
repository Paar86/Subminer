extends Area2D

var _speed := 400.0
var _projectile_explosion_scene := preload("res://src/Player/ProjectileExplosion.tscn")


func _physics_process(delta: float) -> void:
	translate(transform.x * _speed * delta)


func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()


func _create_explosion(global_position: Vector2) -> void:
	var new_explosion = _projectile_explosion_scene.instance()
	new_explosion.global_position = global_position
	get_parent().call_deferred("add_child", new_explosion)
	queue_free()


# For enemies' hurtboxes
func _on_Projectile_area_entered(area: Area2D):
	if area.owner is GameActor:
		area.owner.propagate_effects({Enums.Effects.DAMAGE: 1})
	_create_explosion(global_position)


# For world tiles
func _on_Projectile_body_entered(body):
	_create_explosion(global_position)
