extends Area2D

export var oscillation_frequency: float = 35.0
export var oscillation_distance: float = 0.75

onready var SpriteNode = $AnimatedSprite
onready var _time: float = position.x + position.y

var _ascending_speed := 0.0
var _starting_position: Vector2


func _ready() -> void:
	connect("body_entered", self, "_on_body_entered")
	_ascending_speed = rand_range(20.0, 40.0)
	z_index = -1


func _physics_process(delta: float) -> void:
	_time += delta
	SpriteNode.position.x = _starting_position.x + sin(_time * oscillation_frequency) * oscillation_distance
	
	translate(-transform.y * _ascending_speed * delta)


func _on_body_entered(body: PhysicsBody2D) -> void:
	queue_free()


func _on_LifeTimer_timeout() -> void:
	queue_free()


func _on_CollisionActivatorTimer_timeout() -> void:
	$CollisionShape2D.set_deferred("disabled", false)
