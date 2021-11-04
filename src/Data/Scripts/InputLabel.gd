class_name InputLabel
extends Label

export(Array, String) var actions: Array = []

var backing_text: String = ""


func _ready() -> void:
	backing_text = text
	var _unused = InputHelper.connect("control_type_changed", self, "make_string")
	make_string()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSLATION_CHANGED:
			make_string()


func make_string() -> void:
	# if you get a debug break here, the translation is broken
	text = tr(backing_text) % InputHelper.make_strings_from_actions(actions)
