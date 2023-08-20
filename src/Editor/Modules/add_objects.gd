extends Control


onready var editor = find_parent("Editor")
onready var objects_menu := $"../Objects"


func _on_RailLogicMenu_item_selected(index):
	$RailLogicMenu.hide()
	$RailLogicMenu.unselect_all()
	if editor.selected_object_type != "Rail":
		editor.send_message("At first you need to select a rail,\nto which you want to add the Rail Logic Element!")
		return
	match index:
		0:
			editor.add_signal_to_selected_rail()
		1:
			editor.add_station_to_selected_rail()
		2:
			editor.add_speed_limit_to_selected_rail()
		3:
			editor.add_warn_speed_limit_to_selected_rail()
		4:
			editor.add_contact_point_to_selected_rail()


func _on_AddRail_pressed() -> void:
	editor.add_rail()


func _on_AddRailObject_pressed() -> void:
	if editor.selected_object_type != "Rail":
		editor.send_message("At first you need to select a rail,\nto which you want to add the Rail Logic Element!")
		return
	$RailLogicMenu.visible = !$RailLogicMenu.visible


func _on_AddObjects_toggled(button_pressed: bool) -> void:
	objects_menu.visible = button_pressed


func _on_selected_object_changed(_new_object, type_string) -> void:
	$RailLogicMenu.visible = $RailLogicMenu.visible and type_string == "Rail"
