tool
extends EditorPlugin

const mod_created_setting = "libre_train_sim/modding_tools/mod_created"

func _enter_tree():
	if ProjectSettings.has_setting(mod_created_setting) \
	and ProjectSettings.get_setting(mod_created_setting) == true:
		return

	var base_control = get_editor_interface().get_base_control()
	var popup = preload("new_mod_popup.tscn").instance()
	popup.base_control = base_control
	base_control.add_child(popup)
	popup.popup_centered()
