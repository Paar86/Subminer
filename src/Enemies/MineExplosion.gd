extends Area2D

export var splash_damage_extents_max := 32.0
export var splash_damage_area_growth: float

var animation_duration: float

onready var CollisionShapeNode := $CollisionShape2D
onready var AnimatedSpriteNode := $AnimatedSprite

func _ready() -> void:
	AnimatedSpriteNode.playing = true
	var animation_speed = AnimatedSpriteNode.frames.get_animation_speed("default")
	var animation_frames = AnimatedSpriteNode.frames.get_frame_count("default")
	animation_duration = animation_frames / animation_speed
	# Grow full radius in half of the animation duration
	splash_damage_area_growth = splash_damage_extents_max / animation_duration * 2
	

func _physics_process(delta: float) -> void:
	if CollisionShapeNode.shape.radius < splash_damage_extents_max and !CollisionShapeNode.disabled:
		CollisionShapeNode.shape.set_deferred("radius", CollisionShapeNode.shape.radius + splash_damage_area_growth * delta)
	else:
		CollisionShapeNode.set_deferred("disabled", true)


func _on_AnimatedSprite_animation_finished():
	queue_free()


func _on_MineExplosion_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		var direction = (area.owner.global_position - global_position).normalized()
		area.owner.propagate_effects({Enums.Effects.DAMAGE: 10, Enums.Effects.PUSH: direction * 300.0})
