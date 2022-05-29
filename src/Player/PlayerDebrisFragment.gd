extends FloatingObject

onready var CollisionShapeNode := $CollisionShape2D
onready var SpriteNode := $Sprite

var _rotation_speed_rad := 3.0
var _rotation_damping := 0.5


func set_sprite(texture_resource: StreamTexture) -> void:
	var sprite_node = get_node("Sprite")
	sprite_node.texture = texture_resource


func _ready() -> void:
	_damping = _damping / 2
	
	var texture_size: Vector2 = SpriteNode.texture.get_size()
	var shape_radius := min(texture_size.x, texture_size.y)
	(CollisionShapeNode.shape as CircleShape2D).set_deferred("radius", shape_radius / 2)


func _physics_process(delta: float) -> void:
	._physics_process(delta)

	if _rotation_speed_rad > 0:
		SpriteNode.rotation += _rotation_speed_rad * delta


func _on_FadeOutTimer_timeout() -> void:
	var tween := $FadeOutTween
	tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 1.0, Tween.TRANS_LINEAR)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()
	
