class_name InputRichTextLabel
extends RichTextLabel


export(Array, String) var actions := []
export var centered := false


onready var translation_id := text


func _ready() -> void:
	bbcode_enabled = true
	update_text()
	ControllerIcons.connect("input_type_changed", self, "update_text")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_text()


func set_text(text: String, p_actions := []) -> void:
	translation_id = text
	actions = p_actions
	update_text()


func update_text(var _x = null) -> void:
	var font := get_font("normal_font")
	var icon_size := font.get_height() + font.get_descent()
	var replaces := []
	for possible_action in actions:
		var combinations := ""
		for action in ControllerIcons.get_action_paths(possible_action):
			combinations += "[font=res://Data/Fonts/image_offset_pseudo_%s.tres][img=%d]%s[/img][/font]" % [get_font_specifier(), icon_size, action]
		replaces.push_back(combinations)
	if centered:
		bbcode_text = "[center]%s[/center]" % (tr(translation_id) % replaces)
		return
	bbcode_text = tr(translation_id) % replaces

func get_font_specifier() -> String:
	var font = get("custom_fonts/normal_font").resource_path.get_file()
	if font == "FontMedium.tres":
		return "medium"
	return "ingame"
