extends Node


func run_with_delay_time(function: FuncRef, delay: float) -> void:
	yield(get_tree().create_timer(delay), "timeout")
	if function.is_valid():
		function.call_func()


func run_with_delay_frames(function: FuncRef, delay_frames: int) -> void:
	var frames_passed := 0
	while (frames_passed <= delay_frames):
		yield(get_tree(), "idle_frame")
		frames_passed += 1
	if function.is_valid():
		function.call_func()
