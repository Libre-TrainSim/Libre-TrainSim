extends CanvasLayer


var selected_object: Node
var selected_object_type := ""


func _ready() -> void:
	var station_popup: PopupMenu = $GlobalMenu/JumpToStation.get_popup()
	station_popup.connect("index_pressed", self, "_on_jump_station_pressed")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("pause", true):
		get_tree().paused = true
		$Pause.show()


func provide_settings_for_selected_object() -> void:
	match selected_object_type:
		"Rail":
			$Settings/TabContainer/RailAttachments.update_selected_rail(selected_object)
			$Settings/TabContainer/RailBuilder.update_selected_rail(selected_object)
			_show_rail_settings()
		"Building":
			var children: Array = get_parent().get_children_of_type_recursive(selected_object, MeshInstance)
			var mesh: ArrayMesh = children[0].mesh as ArrayMesh if children.size() > 0 else null
			$Settings/TabContainer/BuildingSettings.set_mesh(mesh, children[0])
			$Settings/TabContainer.current_tab = 3
		"Signal":
			$Settings/TabContainer/RailLogic.set_rail_logic(selected_object)
			$Settings/TabContainer.current_tab = 1
		_:
			$EditorHUD/Settings/TabContainer/RailAttachments.update_selected_rail(null)
			$EditorHUD/Settings/TabContainer/RailBuilder.update_selected_rail(null)
	_update_settings_button_label()


func _update_settings_button_label():
	var descriptions := {false: "Show Settings", true: "Hide Settings"}
	$GlobalMenu/ShowSettingsButton.text = descriptions[$Settings.visible]


func _show_rail_settings():
	if not $Settings/TabContainer.current_tab == 0 and not $Settings/TabContainer.current_tab == 2:
		$Settings/TabContainer.current_tab = 0


func _on_ShowSettings_pressed():
	$Settings.visible = not $Settings.visible
	_update_settings_button_label()


func _on_ClearCurrentObject_pressed():
	get_parent().clear_selected_object()


func _on_CurrentObjectRename_pressed():
	Root.name_node_appropriate(selected_object, $ObjectName/Name/LineEdit.text, \
			selected_object.get_parent())
	$ObjectName/Name/LineEdit.text = selected_object.name
	provide_settings_for_selected_object()


func _on_DeleteCurrentObject_pressed():
	get_parent().delete_selected_object()


func _onObjectName_text_entered(_new_text):
	_on_CurrentObjectRename_pressed()


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


func _on_selected_object_changed(new_object, type_string) -> void:
	selected_object = new_object
	selected_object_type = type_string
	if is_instance_valid(new_object):
		$ObjectName/Name/LineEdit.text = new_object.name
		$ObjectName/Name/Duplicate.visible = type_string == "Building"
		$ObjectName.show()
		provide_settings_for_selected_object()
	else:
		$ObjectName.hide()
