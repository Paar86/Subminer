extends Node

signal last_page_faded_out

var _pages := []
var _current_page: Label = null
var _last_page: Label = null

var _current_page_index := -1
var _number_of_pages := 0
var _page_tween: Tween

var _label_fade_duration := 1.0
var _can_quit := false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and _can_quit:
		_close_last_page()


func _ready() -> void:
	_pages = $Pages.get_children()
	_number_of_pages = _pages.size()
	assert(_number_of_pages, "Pages are empty, cannot show credits scene.")

	_last_page = _pages[_number_of_pages - 1] if _number_of_pages else null

	_page_tween = Tween.new()
	_page_tween.connect("tween_all_completed", self, "_on_tween_all_completed")
	add_child(_page_tween)

	MusicManager.play_music("red_skies")


func _show_next_page() -> void:
	# Possibly null if the function has been called for the first time
	var previous_page = _current_page

	_current_page_index += 1
	_current_page = _pages[_current_page_index] if _current_page_index < _number_of_pages else null

	_page_tween.remove_all()

	if previous_page:
		_page_tween.interpolate_property(
			previous_page,
			"modulate:a",
			previous_page.modulate.a,
			0.0,
			_label_fade_duration,
			Tween.TRANS_LINEAR
		)

	if _current_page:
		_page_tween.interpolate_property(
			_current_page,
			"modulate:a",
			_current_page.modulate.a,
			1.0,
			_label_fade_duration,
			Tween.TRANS_LINEAR
		)
		
		$NextPageTimer.wait_time = _current_page.duration

	_page_tween.start()


func _close_last_page() -> void:
	_page_tween.remove_all()

	var last_page = _current_page
	_current_page = null

	if last_page:
		_page_tween.interpolate_property(
			last_page,
			"modulate:a",
			last_page.modulate.a,
			0.0,
			3.0,
			Tween.TRANS_LINEAR
		)

	_page_tween.start()
	MusicManager.stop_music_with_fadeout()


func _on_tween_all_completed() -> void:
	if _current_page == _last_page:
		$QuitEnablerTimer.start()
		return

	if _current_page == null:
		yield(get_tree().create_timer(5.0), "timeout")
		EventProvider.request_game_restart()

	$NextPageTimer.start()


func _on_NextPageTimer_timeout() -> void:
	_show_next_page()


func _on_DelayTimer_timeout() -> void:
	_show_next_page()


func _on_QuitEnablerTimer_timeout() -> void:
	_can_quit = true
