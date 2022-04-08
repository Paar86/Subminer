extends KinematicBody2D
class_name GameActor

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


func blink() -> void:
	if !_blinking:
		_blinking = true
		visible = false
		# We must rrun the other function safely to not throw error if
		# the GameActor object is deleted before it could be finished
		var function: FuncRef = funcref(self, "unblink")
		YieldHandler.run_with_delay_frames(function, 1)


func unblink() -> void:
	_blinking = false
	visible = true


func flip_horizontally() -> void:
	pass


func flip_vertically() -> void:
	pass
	
	
func flash_before_vanish(number_of_flashes: int = 5) -> void:
	for i in number_of_flashes:
		hide()
		yield(get_tree().create_timer(0.05), "timeout")
		show()
		yield(get_tree().create_timer(0.05), "timeout")

	queue_free()


func _on_blink_finished() -> void:
	visible = true
	_blinking = false
