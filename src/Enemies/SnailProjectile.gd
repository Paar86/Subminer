extends Area2D

enum States { WAIT, TRAVEL }

var ready_to_fire := false

var _speed := 80.0
var _projectile_damage := 3
var _projectile_push_strength := 50.0
var _rotation_speed_rad := 8.0
var _state = States.WAIT

var _projectile_explosion := preload("res://src/Player/ProjectileExplosion.tscn")
onready var SpriteNode := $Sprite


func fire() -> void:
	if ready_to_fire:
		_state = States.TRAVEL


func _physics_process(delta: float) -> void:
	if _state == States.TRAVEL:
		translate(transform.x * _speed * delta)
		
	SpriteNode.rotation += _rotation_speed_rad * delta


func _create_explosion(global_position: Vector2) -> void:
	var new_explosion = _projectile_explosion.instance()
	new_explosion.global_position = global_position
	get_parent().call_deferred("add_child", new_explosion)
	queue_free()


# For player's hurtbox
func _on_SnailProjectile_area_entered(area: Area2D):
	if area.owner is GameActor:
		var direction: Vector2 = (area.global_position - global_position).normalized()
		area.owner.propagate_effects({Enums.Effects.DAMAGE: _projectile_damage, Enums.Effects.PUSH: direction * _projectile_push_strength})
		queue_free()


# For world tiles
func _on_SnailProjectile_body_entered(body):
	if body is TileMap:
		queue_free()
