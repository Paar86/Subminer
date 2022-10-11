extends Control

signal new_game_pressed


onready var NewGameButton = $VBoxContainer/Buttons/NewGameButton
onready var HowToButton = $VBoxContainer/Buttons/HowToButton
onready var ButtonENG = $VBoxContainer/Footing/LanguageButtons/ButtonENG
onready var ButtonCZE = $VBoxContainer/Footing/LanguageButtons/ButtonCZE
onready var AnimationPlayerScene = $AnimationPlayer

onready var _screen_size := get_viewport_rect().size


func _ready() -> void:
	_refresh_text()
	AnimationPlayerScene.play("INTRO")
	MusicManager.play_music("sunny_afternoon")


func _refresh_text() -> void:
	NewGameButton.text = TextManager.get_string_by_key("new_game_title")
	HowToButton.text = TextManager.get_string_by_key("how_to_title")


func _generate_bubble() -> void:
	var y = _screen_size.y + 20.0
	var x = rand_range(0.0, _screen_size.x)

	BubbleGenerator.generate_bubble_to_position(Vector2(x, y), self)


func _activate_buttons():
	NewGameButton.disabled = false
	HowToButton.disabled = false
	ButtonENG.disabled = false
	ButtonCZE.disabled = false


func _on_NewGameButton_pressed() -> void:
	MusicManager.stop_music_with_fadeout()
	AnimationPlayerScene.play("FADE_OUT")
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


func _on_BubbleTimer_timeout() -> void:
	_generate_bubble()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "INTRO":
		_generate_bubble()
		$BubbleTimer.start()
