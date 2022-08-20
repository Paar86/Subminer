extends Node

onready var FrequencyTimer := $FrequencyTimer
onready var DurationTimer := $DurationTimer
onready var ShakeTween := $ShakeTween

onready var _camera := get_parent() as Camera2D

var _amplitude_current := 0
var _priority_current := 0


func _ready() -> void:
	EventProvider.connect("shake_requested", self, "_on_shake_request")


func _start(
		duration: float,
		frequency: float,
		amplitude: float,
		priority: int
	) -> void:
	
	if priority < _priority_current:
		return
	
	_amplitude_current = amplitude
	_priority_current = priority

	DurationTimer.wait_time = duration
	FrequencyTimer.wait_time = 1 / frequency

	DurationTimer.start()
	FrequencyTimer.start()

	_new_shake()


func _new_shake() -> void:
	var rand_offset = Vector2.ZERO
	rand_offset.x = rand_range(-_amplitude_current, _amplitude_current)
	rand_offset.y = rand_range(-_amplitude_current, _amplitude_current)

	ShakeTween.interpolate_property(
		_camera,
		"offset",
		_camera.offset,
		rand_offset,
		FrequencyTimer.wait_time,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	ShakeTween.start()


func _reset() -> void:
	ShakeTween.interpolate_property(
		_camera,
		"offset",
		_camera.offset,
		Vector2.ZERO,
		FrequencyTimer.wait_time,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	_priority_current = 0


func _on_FrequencyTimer_timeout() -> void:
	_new_shake()


func _on_DurationTimer_timeout() -> void:
	FrequencyTimer.stop()
	_reset()


func _on_shake_request(amplitude: float, duration: float, priority: int) -> void:
	_start(duration, 60.0, amplitude, priority)
