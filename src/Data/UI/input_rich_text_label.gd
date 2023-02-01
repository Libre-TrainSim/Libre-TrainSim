class_name InputRichTextLabel
extends RichTextLabel


export(Array, String) var actions := []
export(bool) var centered := false


onready var translation_id := text


func _ready() -> void:
	bbcode_enabled = true
	update_text()
	ControllerIcons.connect("input_type_changed", self, "update_text")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_text()


func set_text(text: String) -> void:
	.set_text(tr(text))


func update_text(var _x = null) -> void:
	var replaces := []
	for possible_action in actions:
		var combinations := ""
		for action in ControllerIcons.get_action_paths(possible_action):
			combinations += "[font=res://Data/Fonts/image_offset_pseudo.tres][img=36]%s[/img][/font]" % action
		replaces.push_back(combinations)
	bbcode_text = ""
	if centered:
		bbcode_text = "[center]"
	bbcode_text += tr(translation_id) % replaces
	if centered:
		bbcode_text += "[/center]"
