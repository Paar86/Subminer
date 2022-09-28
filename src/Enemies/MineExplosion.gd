extends Area2D

var _splash_damage_extents_max := 48.0
var _splash_damage_area_growth: float
var _animation_duration: float
var _default_damage := 10

onready var CollisionShapeNode := $CollisionShape2D

onready var _big_explosion_scene := preload("res://src/Common/BigExplosion.tscn")

func _ready() -> void:
	var explosion_scene = _big_explosion_scene.instance()
	if !(explosion_scene is AnimatedSprite):
		assert(false)

	var animation_speed = explosion_scene.frames.get_animation_speed("default")
	var animation_frames = explosion_scene.frames.get_frame_count("default")
	_animation_duration = animation_frames / animation_speed
	# Grow full radius in half of the animation duration
	_splash_damage_area_growth = _splash_damage_extents_max / _animation_duration * 2

	explosion_scene.connect("animation_finished", self, "_on_explosion_animation_finished")
	explosion_scene.global_position = global_position
	get_parent().add_child(explosion_scene)


func _physics_process(delta: float) -> void:
	if CollisionShapeNode.shape.radius < _splash_damage_extents_max and !CollisionShapeNode.disabled:
		CollisionShapeNode.shape.set_deferred("radius", CollisionShapeNode.shape.radius + _splash_damage_area_growth * delta)
	else:
		CollisionShapeNode.set_deferred("disabled", true)


func _on_explosion_animation_finished():
	queue_free()


func _on_MineExplosion_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		var direction = (area.owner.global_position - global_position).normalized()
		area.owner.propagate_effects({Enums.Effects.DAMAGE: _default_damage, Enums.Effects.PUSH: direction * 150.0})
