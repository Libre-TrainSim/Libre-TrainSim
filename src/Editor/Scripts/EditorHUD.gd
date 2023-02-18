extends CanvasLayer


func _ready() -> void:
	var station_popup: PopupMenu = $GlobalMenu/JumpToStation.get_popup()
	station_popup.connect("index_pressed", self, "_on_jump_station_pressed")


func handle_object_transform_field():
	$ObjectName/Name/Duplicate.visible = get_parent().selected_object_type == "Building"
	if not $ObjectTransform.visible:
		return
	var selected_object = get_parent().selected_object
	if is_instance_valid(selected_object):
		$ObjectTransform/HBoxContainer/x.value = selected_object.translation.x
		$ObjectTransform/HBoxContainer/y.value = selected_object.translation.y
		$ObjectTransform/HBoxContainer/z.value = selected_object.translation.z
		$ObjectTransform/HBoxContainer/y_rot.value = rad2deg(selected_object.rotation.y)


func _unhandled_input(_event: InputEvent) -> void:
	handle_object_transform_field()
	if Input.is_action_just_released("pause", true):
		get_tree().paused = true
		$Pause.show()


func update_ShowSettingsButton():
	if not $Settings.visible:
		$GlobalMenu/ShowSettingsButton.text = "Show Settings"
	else:
		$GlobalMenu/ShowSettingsButton.text = "Hide Settings"


func _on_ShowSettings_pressed():
	if $Settings.visible:
		hide_settings()
	else:
		show_settings()
	update_ShowSettingsButton()


func hide_settings():
	$Settings.hide()


func show_settings():
	$Settings.show()


func set_current_object_name(object_name : String):
	$ObjectName/Name/LineEdit.text = object_name
	$ObjectName.show()


func clear_current_object_name():
	$ObjectName.hide()


func hide_current_object_transform():
	$ObjectTransform.hide()


func show_current_object_transform():
	$ObjectTransform.show()
	handle_object_transform_field()


func _on_ClearCurrentObject_pressed():
	get_parent().clear_selected_object()


func _on_CurrentObjectRename_pressed():
	get_parent().rename_selected_object($ObjectName/Name/LineEdit.text)


func _on_DeleteCurrentObject_pressed():
	get_parent().delete_selected_object()


func _on_x_value_changed(value):
	var selected_object = get_parent().selected_object
	if is_instance_valid(selected_object):
		selected_object.translation.x = value


func _on_y_value_changed(value):
	var selected_object = get_parent().selected_object
	if is_instance_valid(selected_object):
		selected_object.translation.y = value


func _on_z_value_changed(value):
	var selected_object = get_parent().selected_object
	if is_instance_valid(selected_object):
		selected_object.translation.z = value


func _on_y_rot_value_changed(value):
	var selected_object = get_parent().selected_object
	if is_instance_valid(selected_object):
		selected_object.rotation.y = deg2rad(value)


func _onObjectName_text_entered(_new_text):
	_on_CurrentObjectRename_pressed()


func show_building_settings():
	$Settings/TabContainer.current_tab = 3


func show_signal_settings():
	$Settings/TabContainer.current_tab = 1


func show_rail_settings():
	if not $Settings/TabContainer.current_tab == 0 and not $Settings/TabContainer.current_tab == 2:
		$Settings/TabContainer.current_tab = 0


func  _on_DuplicateObject_pressed():
	get_parent().duplicate_selected_object()


func _on_JumpToStation_pressed():
	var station_menu: PopupMenu = $GlobalMenu/JumpToStation.get_popup()
	station_menu.clear()
	var station_node_names: Array = get_parent().get_all_station_node_names_in_world()
	station_node_names.sort()
	for station_node_name in station_node_names:
		station_menu.add_item(station_node_name)


func _on_jump_station_pressed(index: int) -> void:
	var station_menu: PopupMenu = $GlobalMenu/JumpToStation.get_popup()
	get_parent().jump_to_station(station_menu.get_item_text(index))


func _on_ShowConfig_pressed() -> void:
	var config: WindowDialog = preload("res://Editor/Docks/Configuration/Configuration.tscn").instance()
	add_child(config)
	config.popup_centered()
