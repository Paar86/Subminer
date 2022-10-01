extends GameActor


export var request_level_end := false

onready var AnimPlayer: AnimationPlayer = $AnimationPlayer
onready var DetonationDelayTimer := $DetonationDelayTimer

onready var _mine_explosion_scene: PackedScene = preload("res://src/Enemies/MineExplosion.tscn")

# To every mine to oscillate a little differently
onready var _time: float = position.x + position.y

var _starting_position: Vector2
var _move_distance: float = 2.0
var _move_frequency: float = 2.0


func propagate_effects(effects: Dictionary = {}) -> void:
	.propagate_effects(effects)
	if _hitpoints == 0:
		prepare_explosion()


func _ready() -> void:
	_hitpoints = 3
	_starting_position = position


func _physics_process(delta: float) -> void:
	_time += delta
	position.y = _starting_position.y + sin(_time * _move_frequency) * _move_distance


func _on_PlayerDetector_body_entered(body: GameActor) -> void:
	AnimPlayer.play("Warning")


func _on_PlayerDetector_body_exited(body: GameActor) -> void:
	AnimPlayer.play("RESET")


func prepare_explosion() -> void:
	if DetonationDelayTimer.is_stopped():
		$TriggerArea.set_deferred("monitoring", false)
		$Sprite.set_deferred("frame", 1)
		DetonationDelayTimer.start()


func _explode() -> void:
	var new_explosion = _mine_explosion_scene.instance()
	new_explosion.global_position = global_position
	get_parent().call_deferred("add_child", new_explosion)
	queue_free()

	if request_level_end:
		EventProvider.request_level_fade_out_white()


func _on_TriggerArea_body_entered(body: Node) -> void:
	prepare_explosion()


func _on_DetonationDelayTimer_timeout() -> void:
	_explode()
