class_name ObjectTransform
extends PanelContainer


var local_mode := false
var selected_object: Node
var selected_type := ""


func _process(_delta: float) -> void:
	update_values()


func update_values():
	if not visible:
		return
	if not is_instance_valid(selected_object):
		hide()
		return
	if local_mode:
		$HBoxContainer/x.value = selected_object.translation.x
		$HBoxContainer/y.value = selected_object.translation.y
		$HBoxContainer/z.value = selected_object.translation.z
		$HBoxContainer/x_rot.value = rad2deg(selected_object.rotation.x)
		$HBoxContainer/y_rot.value = rad2deg(selected_object.rotation.y)
		$HBoxContainer/z_rot.value = rad2deg(selected_object.rotation.z)
	else:
		$HBoxContainer/x.value = selected_object.global_translation.x
		$HBoxContainer/y.value = selected_object.global_translation.y
		$HBoxContainer/z.value = selected_object.global_translation.z
		$HBoxContainer/x_rot.value = rad2deg(selected_object.global_rotation.x)
		$HBoxContainer/y_rot.value = rad2deg(selected_object.global_rotation.y)
		$HBoxContainer/z_rot.value = rad2deg(selected_object.global_rotation.z)


func _on_x_value_changed(value):
	if is_instance_valid(selected_object):
		if local_mode:
			selected_object.translation.x = value
		else:
			selected_object.global_translation.x = value


func _on_y_value_changed(value):
	if is_instance_valid(selected_object):
		if local_mode:
			selected_object.translation.y = value
		else:
			selected_object.global_translation.y = value


func _on_z_value_changed(value):
	if is_instance_valid(selected_object):
		if local_mode:
			selected_object.translation.z = value
		else:
			selected_object.global_translation.z = value


func _on_x_rot_value_changed(value: float):
	if is_instance_valid(selected_object):
		if local_mode:
			selected_object.rotation.x = deg2rad(value)
		else:
			selected_object.global_rotation.x = deg2rad(value)


func _on_y_rot_value_changed(value: float):
	if is_instance_valid(selected_object):
		if local_mode:
			selected_object.rotation.y = deg2rad(value)
		else:
			selected_object.global_rotation.y = deg2rad(value)


func _on_z_rot_value_changed(value: float):
	if is_instance_valid(selected_object):
		if local_mode:
			selected_object.rotation.z = deg2rad(value)
		else:
			selected_object.global_rotation.z = deg2rad(value)


func _on_local_toggled(is_local: bool) -> void:
	local_mode = is_local
	for child in selected_object.get_children():
		var gizmo := child as Gizmo
		if not gizmo:
			continue
		gizmo.local_mode = is_local
		break


func _on_selected_object_changed(new_object, type_string) -> void:
	selected_object = new_object
	selected_type = type_string
	visible = selected_type in ["Building", "Rail"]
