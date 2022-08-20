extends KinematicBody2D
class_name GameActor

onready var _explosion_scene := preload("res://src/Common/ActorExplosion.tscn")
onready var _random_bubble_generator := preload("res://src/Common/RandomBubbleSpawner.tscn")

var _hitpoints: int
var _blinking := false

var _hit_sfx_path := "res://assets/sfx/hitHurt2.wav"


func propagate_effects(effects: Dictionary = {}) -> void:
	if Enums.Effects.DAMAGE in effects:
		AudioStreamManager.play_sound(_hit_sfx_path)
		var value: int = effects[Enums.Effects.DAMAGE]
		if _hitpoints > value:
			_hitpoints -= value
			blink()
		else:
			_hitpoints = 0
	if Enums.Effects.PUSH in effects:
		# Every object needs to implement it differently
		pass


func create_explosion(spawn_position: Vector2 = Vector2.ZERO) -> void:
	var explosion_scene = _explosion_scene.instance()
	explosion_scene.global_position = spawn_position if spawn_position != Vector2.ZERO else global_position
	get_parent().call_deferred("add_child", explosion_scene)


func blink() -> void:
	if !_blinking:
		_blinking = true
		visible = false
		# We must rrun the other function safely to not throw error if
		# the GameActor object is deleted before it could be finished
		var function: FuncRef = funcref(self, "unblink")
		YieldHandler.run_with_delay_frames(function, 1)


func _ready() -> void:
	var bubble_generator = _random_bubble_generator.instance()
	call_deferred("add_child", bubble_generator)
	bubble_generator.set_deferred("owner", self)


func unblink() -> void:
	_blinking = false
	visible = true


func transpose() -> void:
	pass


func flip_horizontally() -> void:
	pass


func flip_vertically() -> void:
	pass


func _on_blink_finished() -> void:
	visible = true
	_blinking = false
