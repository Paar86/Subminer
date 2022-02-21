extends Node2D

var rotation_speed := 150.0
var mouse_global_position := Vector2.ZERO


func _process(delta: float) -> void:
	mouse_global_position = get_global_mouse_position()
	var rotation_speed_rad := deg2rad(rotation_speed)
	var smallest_angle_to_mouse: float = get_smallest_angle_to()
	rotate(sign(smallest_angle_to_mouse) * rotation_speed_rad * delta)
	if abs(smallest_angle_to_mouse) < rotation_speed_rad * delta:
		look_at(mouse_global_position)

# We need to determine the shortest way to the destination (clockwise/counterclockwise)
func get_smallest_angle_to() -> float:
	var angle_to_mouse: float = get_angle_to(mouse_global_position)
	if angle_to_mouse > PI:
		return 2 * PI - angle_to_mouse

	return angle_to_mouse
