extends Area2D

var _splash_damage_extents_max := 32.0
var _splash_damage_area_growth: float
var _animation_duration: float

onready var CollisionShapeNode := $CollisionShape2D
onready var AnimatedSpriteNode := $AnimatedSprite

onready var _explosion_sfx_path := "res://assets/sfx/explosion.wav"

func _ready() -> void:
	AnimatedSpriteNode.playing = true
	var animation_speed = AnimatedSpriteNode.frames.get_animation_speed("default")
	var animation_frames = AnimatedSpriteNode.frames.get_frame_count("default")
	_animation_duration = animation_frames / animation_speed
	# Grow full radius in half of the animation duration
	_splash_damage_area_growth = _splash_damage_extents_max / _animation_duration * 2
	AudioStreamManager.play_sound(_explosion_sfx_path)
	

func _physics_process(delta: float) -> void:
	if CollisionShapeNode.shape.radius < _splash_damage_extents_max and !CollisionShapeNode.disabled:
		CollisionShapeNode.shape.set_deferred("radius", CollisionShapeNode.shape.radius + _splash_damage_area_growth * delta)
	else:
		CollisionShapeNode.set_deferred("disabled", true)


func _on_AnimatedSprite_animation_finished():
	queue_free()


func _on_MineExplosion_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		var direction = (area.owner.global_position - global_position).normalized()
		area.owner.propagate_effects({Enums.Effects.DAMAGE: 10, Enums.Effects.PUSH: direction * 300.0})
