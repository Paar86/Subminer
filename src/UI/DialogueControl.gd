extends Control

enum States { PAGE_LOADING, PAGE_LOADED, LAST_PAGE_LOADED }

onready var DialogueTextLabel: Label = $BorderRect/DialogueText

var dialogue_text := "" setget _set_dialogue_text

var _is_dialogue_finished := false setget , _get_is_dialogue_finished
var _state = States.PAGE_LOADING
var _pages: PoolStringArray = PoolStringArray()
var _current_page := -1

# Properties
func _set_dialogue_text(_dialogue_text: String) -> void:
	dialogue_text = _dialogue_text
	DialogueTextLabel.text = _dialogue_text
	DialogueTextLabel.visible_characters = 0
	DialogueTextLabel.lines_skipped = 0


func _get_is_dialogue_finished() -> bool:
	var all_lines_count = DialogueTextLabel.get_line_count()
	var skipped_lines_count = DialogueTextLabel.lines_skipped
	var visible_lines_count = DialogueTextLabel.get_visible_line_count()
	return visible_lines_count + skipped_lines_count >= all_lines_count


# Functions
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		match _state:
			States.PAGE_LOADING:
				DialogueTextLabel.visible_characters = DialogueTextLabel.get_total_character_count()
				return
			States.PAGE_LOADED:
				_load_next_page()
				return
			States.LAST_PAGE_LOADED:
				hide()


func _ready() -> void:
	var default_string = TextManager.get_string_by_key("level1")
	_pages = _create_pages(default_string)
	_load_next_page()
	
	
func _load_next_page() -> void:
	_current_page += 1
	
	if _current_page > _pages.size() - 1:
		push_error("Cannot load page number %s." % str(_current_page))
		return
		
	_start_dialogue()
	
	
func _start_dialogue() -> void:
	_state = States.PAGE_LOADING
	DialogueTextLabel.text = _pages[_current_page]
	DialogueTextLabel.visible_characters = 0
	var characters_count = DialogueTextLabel.get_total_character_count()
	while (DialogueTextLabel.visible_characters < characters_count):
		DialogueTextLabel.visible_characters += 1
		yield(get_tree().create_timer(0.025), "timeout")
		
	if _current_page == _pages.size() - 1:
		_state = States.LAST_PAGE_LOADED
		return
		
	_state = States.PAGE_LOADED


func _create_pages(text: String) -> PoolStringArray:
	var string_tokens: PoolStringArray = text.split(" ", false)
	var pages: PoolStringArray = PoolStringArray()
	var initial_text = DialogueTextLabel.text
	DialogueTextLabel.text = ""

	if string_tokens.size() == 0:
		return pages

	var page_string: String
	for token in string_tokens:
		var page_string_temp: String
		if page_string.length() == 0:
			page_string = token
			page_string_temp = page_string
		else:
			page_string_temp = page_string + " " + token

		DialogueTextLabel.text = page_string_temp
		# If there is overflow on the Label
		
		if (DialogueTextLabel.max_lines_visible >= 0 and
				DialogueTextLabel.get_line_count() > DialogueTextLabel.max_lines_visible):
			pages.append(page_string)
			DialogueTextLabel.text = ""
			page_string = ""
			continue
			
		page_string = page_string_temp
	
	# This is for the last lines which won't cause Label overflow
	if page_string.length() > 0:
		pages.append(page_string)
	
	# Getting the Label to it's original state
	DialogueTextLabel.text = initial_text

	return pages
