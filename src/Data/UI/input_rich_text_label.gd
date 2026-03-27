class_name InputRichTextLabel
extends RichTextLabel


@export var actions := [] # (Array, String)
@export var centered := false


func _ready() -> void:
	update_text()
	ControllerIcons.connect("input_type_changed", Callable(self, "update_text"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_text()


func set_text_input(text_input: String, p_actions := []) -> void:
	text = text_input
	actions = p_actions
	update_text()


func update_text(_x = null) -> void:
	var font := get_theme_font("normal_font")
	var icon_size := font.get_height() + font.get_descent()
	var replaces := []
	#for possible_action in actions:
		#var combinations := ""
		#for action in ControllerIcons.get_action_paths(possible_action):
			#combinations += "[font=res://Data/Fonts/image_offset_pseudo_%s.tres][img=%d]%s[/img][/font]" % [get_font_specifier(), icon_size, action]
		#replaces.push_back(combinations)
	if centered:
		text = "[center]%s[/center]" % (tr(text) % replaces)
		return
	text = tr(text) % replaces

func get_font_specifier() -> String:
	var font = get("theme_override_fonts/normal_font").resource_path.get_file()
	if font == "FontMedium.tres":
		return "medium"
	return "ingame"
