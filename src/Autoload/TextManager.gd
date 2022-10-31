extends Node

var current_lang = Enums.Languages.EN setget _set_current_lang

const FILE_FORMAT_WARNING_MESSAGE := "Parsed file is in wrong format!"

var _text_resource := "res://assets/text/text_strings.json"
var _parsed_result: JSONParseResult
var _strings_dictionary := {}


# Properties
func _set_current_lang(value: int) -> void:
	if value >= Enums.Languages.UNDEFINED:
		push_error("Trying to set undefined language. Reverted to default.")
		current_lang = Enums.Languages.CZ
		return

	current_lang = value
	_strings_dictionary = _get_filtered_strings_by_lang(current_lang)


# Functions
func get_string_by_key(key: String) -> String:
	if not _strings_dictionary.has(key):
		return "{invalid key '%s'}" % key
		
	return _strings_dictionary[key]


func _ready() -> void:
	var file := File.new()
	if not file.file_exists(_text_resource):
		push_error("Translation file not found!")
		assert(false)

	file.open(_text_resource, File.READ)
	var file_contents = file.get_as_text()
	var result = JSON.parse(file_contents)

	if result.error != OK:
		push_error("Translation is in invalid format." +
					" Line: " + result.error_line +
					" Reason: " + result.error_string)
		assert(false)

	_parsed_result = result
	_strings_dictionary = _get_filtered_strings_by_lang(current_lang)


func _get_lang_as_string(language: int) -> String:
	match language:
		Enums.Languages.CZ:
			return "cz"
		Enums.Languages.EN:
			return "en"

	return "undefined"


func _get_string_as_lang(lang_string: String) -> String:
	if lang_string.nocasecmp_to(_get_lang_as_string(Enums.Languages.CZ)):
		return Enums.Languages.CZ

	if lang_string.nocasecmp_to(_get_lang_as_string(Enums.Languages.EN)):
		return Enums.Languages.EN

	return Enums.Languages.UNDEFINED


func _get_filtered_strings_by_lang(language: int) -> Dictionary:
	if !_parsed_result:
		push_warning("Parsed langugage file is empty!")
		return {}

	if typeof(_parsed_result.result["text_strings"]) != TYPE_ARRAY:
		push_warning(FILE_FORMAT_WARNING_MESSAGE)
		return {}

	var new_dict = {}
	var root_array = _parsed_result.result["text_strings"]
	for string_dict in root_array:
		if typeof(string_dict["id"]) != TYPE_STRING:
			push_warning(FILE_FORMAT_WARNING_MESSAGE)
			return {}

		if typeof(string_dict["languages"]) != TYPE_DICTIONARY:
			push_warning(FILE_FORMAT_WARNING_MESSAGE)
			return {}

		var id: String = string_dict["id"]
		var languages_dict: Dictionary = string_dict["languages"]
		var language_string: String = languages_dict[_get_lang_as_string(language)]
		new_dict[id] = language_string

	return new_dict
