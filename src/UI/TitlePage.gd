extends Control

signal new_game_pressed


onready var NewGameButton = $VBoxContainer/Buttons/NewGameButton
onready var HowToButton = $VBoxContainer/Buttons/HowToButton
onready var AnimationPlayerScene = $AnimationPlayer


func _ready() -> void:
	_refresh_text()


func _refresh_text() -> void:
	NewGameButton.text = TextManager.get_string_by_key("new_game_title")
	HowToButton.text = TextManager.get_string_by_key("how_to_title")


func _on_NewGameButton_pressed() -> void:
	AnimationPlayerScene.play("fade_out")
	yield(AnimationPlayerScene, "animation_finished")
	emit_signal("new_game_pressed")


func _on_HowToButton_pressed() -> void:
	pass # Replace with function body.


func _on_ButtonENG_toggled(button_pressed: bool) -> void:
	TextManager.current_lang = Enums.Languages.EN
	_refresh_text()


func _on_ButtonCZE_toggled(button_pressed: bool) -> void:
	TextManager.current_lang = Enums.Languages.CZ
	_refresh_text()
