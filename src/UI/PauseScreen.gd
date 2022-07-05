extends Control

signal restart_pressed
signal back_pressed


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and visible:
		emit_signal("back_pressed")
		get_tree().set_input_as_handled()


func _ready() -> void:
	$VBoxContainer/PauseLabel.text = "-" + TextManager.get_string_by_key("pause_text").to_upper() + "-"
	$VBoxContainer/RestartButton.text = TextManager.get_string_by_key("restart_text")
	$VBoxContainer/BackButton.text = TextManager.get_string_by_key("back_text")


func _on_RestartButton_pressed() -> void:
	emit_signal("restart_pressed")


func _on_BackButton_pressed() -> void:
	emit_signal("back_pressed")
