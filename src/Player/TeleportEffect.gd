extends Node2D

signal teleport_in_finished
signal teleport_out_finished


func _on_TeleportInDelay_timeout() -> void:
	$TeleportAnimationPlayer.play("TELEPORT_START")


func _on_TeleportAnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "TELEPORT_START":
		emit_signal("teleport_in_finished")

	hide()
