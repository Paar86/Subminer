extends KinematicBody2D

enum modes {OPENING, CLOSING}

onready var animation_player := $AnimationPlayer
onready var blocking_shape := $BlockingShape

var opened := false
var current_mode: int


func open_door() -> void:
	if animation_player.is_playing():
		animation_player.stop(false)
		animation_player.play("", -1, 1.0, false)
	elif !opened:
		animation_player.play("Open")

	current_mode = modes.OPENING


func close_door() -> void:
	if animation_player.is_playing():
		animation_player.stop(false)
		animation_player.play("", -1, -1.0, false)
	elif opened:
		animation_player.play_backwards("Open")

	current_mode = modes.CLOSING


func toggle_blocking(disabled_value: bool) -> void:
	blocking_shape.set_deferred("disabled", disabled_value)


func _on_PlayerDetector_body_entered(body: KinematicBody2D) -> void:
	open_door()


func _on_PlayerDetector_body_exited(body: KinematicBody2D) -> void:
	close_door()


func _on_AnimationPlayer_animation_finished(anim_name: Animation):
	match current_mode:
		modes.CLOSING:
			opened = false
		modes.OPENING:
			opened = true
