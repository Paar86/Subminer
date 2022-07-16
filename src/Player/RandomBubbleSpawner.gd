extends Node2D

var _time_current := 0.0
var _time_goal := 0.0

var _rnd := RandomNumberGenerator.new()


func _ready() -> void:
	_rnd.randomize()
	_time_goal = _rnd.randf_range(4.0, 15.0)
	_randomize_time_goal()


func _physics_process(delta: float) -> void:
	_time_current += delta

	if _time_current >= _time_goal:
		BubbleGenerator.generate_bubbles_in_rect_with_delay(
			self,
			4.0,
			4.0,
			owner.get_parent(),
			1,
			0.03
		)

		_time_current = 0.0
		_randomize_time_goal()


func _randomize_time_goal() -> void:
	_time_goal = _rnd.randf_range(4.0, 8.0)
