extends CanvasLayer

onready var MouseCursor := $MouseCursor


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _process(delta: float) -> void:
	MouseCursor.position = get_viewport().get_mouse_position()
