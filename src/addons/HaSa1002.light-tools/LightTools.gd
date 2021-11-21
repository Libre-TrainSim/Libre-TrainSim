tool
extends EditorPlugin

var light3d := preload("res://addons/HaSa1002.light-tools/LightColor.gd").new()
var old_icon: Texture
var theme: Theme

func _enter_tree():
	add_inspector_plugin(light3d)
	theme = get_editor_interface().get_base_control().theme
	if theme.has_icon("Light", "EditorIcons"):
		old_icon = theme.get_icon("Light", "EditorIcons")
	else:
		old_icon = theme.get_icon("Object", "EditorIcons")
	theme.set_icon("Light", "EditorIcons", preload("res://addons/HaSa1002.light-tools/Light.png"))


func _exit_tree():
	remove_inspector_plugin(light3d)
	theme.set_icon("Light", "EditorIcons", old_icon)


func get_plugin_icon():
	return preload("res://addons/HaSa1002.light-tools/ToolIcon.svg")


func get_plugin_name():
	return "Light Tools"
