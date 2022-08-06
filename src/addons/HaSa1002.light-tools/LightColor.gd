tool
extends EditorInspectorPlugin


func can_handle(object):
	return object is Light || object is Light2D


func parse_property(object, type, path, hint, hint_text, usage):
	if ((path == "light_color" and object is Light) ||
			(path == "color" and object is Light2D)):
		add_property_editor(path, LightColorEditor.new())
		return true
	return false
