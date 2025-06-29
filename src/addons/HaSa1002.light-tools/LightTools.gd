@tool
extends EditorPlugin

var light3d := preload("res://addons/HaSa1002.light-tools/LightColor.gd").new()
var old_icon: Texture2D
var theme: Theme

func _enter_tree():
	add_inspector_plugin(light3d)
	theme = get_editor_interface().get_base_control().theme
	if theme.has_theme_icon("Light3D", "EditorIcons"):
		old_icon = theme.get_icon("Light3D", "EditorIcons")
	else:
		old_icon = theme.get_icon("Object", "EditorIcons")
	theme.set_icon("Light3D", "EditorIcons", preload("res://addons/HaSa1002.light-tools/Light3D.png"))


func _exit_tree():
	remove_inspector_plugin(light3d)
	theme.set_icon("Light3D", "EditorIcons", old_icon)


func _get_plugin_icon():
	return preload("res://addons/HaSa1002.light-tools/ToolIcon.svg")


func _get_plugin_name():
	return "Light3D Tools"
