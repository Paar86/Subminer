extends Label

export var translate := true
export var duration := 3.0


func _ready() -> void:
	if translate:
		var page_text = TextManager.get_string_by_key(text)
		text = page_text
