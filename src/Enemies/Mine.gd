extends GameActor

export var move_distance: float = 2.0
export var move_frequency: float = 2.0

# Just for every mine to oscillate a little differently
onready var time: float = position.x + position.y
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var splash_damage_area: Area2D = $SplashDamageArea
onready var explosion_scene: PackedScene = preload("res://src/Enemies/MineExplosion.tscn")

var starting_position: Vector2

func _ready() -> void:
	hitpoints = 10
	starting_position = position


func _physics_process(delta: float) -> void:
	time += delta
	position.y = starting_position.y + sin(time * move_frequency) * move_distance


func _on_PlayerDetector_body_entered(body: GameActor) -> void:
	animation_player.play("Warning")


func _on_PlayerDetector_body_exited(body: GameActor) -> void:
	animation_player.play("RESET")


func explode() -> void:
	var new_explosion = explosion_scene.instance()
	new_explosion.global_position = global_position
	get_parent().call_deferred("add_child", new_explosion)
	queue_free()


func propagate_effects(effects: Dictionary = {}) -> void:
	.propagate_effects(effects)
	if hitpoints == 0:
		explode()


func _on_TriggerArea_area_entered(area: Area2D) -> void:
	if !area.owner.is_in_group("Mines"):
		explode()
