extends KinematicBody2D
class_name GameActor

var hitpoints: int
var blinking := false


func propagate_effects(effects: Dictionary = {}) -> void:
	if Enums.Effects.DAMAGE in effects:
		blink()
		var value: int = effects[Enums.Effects.DAMAGE]
		if hitpoints > value:
			hitpoints -= value
		else:
			hitpoints = 0
	if Enums.Effects.PUSH in effects:
		# Every object needs to implement it differently
		pass


func blink() -> void:
	if !blinking:
		blinking = true
		visible = false
		yield(get_tree().create_timer(0.02), "timeout")
		visible = true
		blinking = false


func flip_horizontally() -> void:
	pass
	
	
func flip_vertically() -> void:
	pass
