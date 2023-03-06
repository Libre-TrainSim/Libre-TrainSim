class_name TranslatedRichTextLabel
extends RichTextLabel


onready var translation_id := text


func _ready() -> void:
	update_text()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_text()


func set_text(text: String) -> void:
	translation_id = text
	update_text()


func update_text() -> void:
	if bbcode_enabled:
		bbcode_text = tr(translation_id)
	else:
		text = tr(translation_id)
