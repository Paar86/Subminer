extends Node2D

signal teleport_in_finished
signal teleport_out_finished

onready var TeleportAnimationPlayer = $TeleportAnimationPlayer


# Needs to be called manually
func start_teleport_away_animation() -> void:
	TeleportAnimationPlayer.play("BLACKOUT_START")


# Timer starts automatically
func _on_TeleportInDelay_timeout() -> void:
	TeleportAnimationPlayer.play("TELEPORT_START")


func _on_TeleportAnimationPlayer_animation_finished(anim_name: String) -> void:
	match anim_name:
		"TELEPORT_START":
			emit_signal("teleport_in_finished")
			$Sprite.hide()
		"TELEPORT_END":
			emit_signal("teleport_out_finished")
			$Sprite.hide()
		"BLACKOUT_START":
			TeleportAnimationPlayer.play("TELEPORT_END")
