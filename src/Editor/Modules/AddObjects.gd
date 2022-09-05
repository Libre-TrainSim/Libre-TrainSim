extends Control

onready var editor = find_parent("Editor")


func _on_ShowMenu_pressed():
	if $ShowMenu.text == " + ":
		show_menu()
	else:
		hide_menu()


func show_menu():
	$Menu1.show()
	$ShowMenu.text = " - "


func hide_menu():
	$Menu1.hide()
	$Menu1.unselect_all()
	$RailLogicMenu.hide()
	$RailLogicMenu.unselect_all()
	$ShowMenu.text = " + "


var current_waiting_index = -1
func _on_ItemList_item_selected(index):
	$Menu1.unselect_all()
	if index == 0: # Rail
		editor.add_rail()
		hide_menu()
	if index == 1: # Object
		var content_selector = get_parent().get_node("Content_Selector")
		content_selector.set_type(content_selector.OBJECTS)
		content_selector.show()
		current_waiting_index = 1
		hide_menu()
	if index == 2: # Rail Logic
		if editor.selected_object_type != "Rail":
			editor.send_message("At first you need to select a rail,\nto which you want to add the Rail Logic Element!")
			hide_menu()
		else:
			$RailLogicMenu.show()


func _on_RailLogicMenu_item_selected(index):
	hide_menu()
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


func _on_Content_Selector_resource_selected(complete_path):
	if complete_path == "": ## User canceled action
		return
	if current_waiting_index == -1: ## Not waiting for any input
		return
	if current_waiting_index == 1: ## Object
		editor.add_object(complete_path)
		current_waiting_index = -1

