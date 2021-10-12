extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



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
	get_parent()._on_dialog_closed()

var current_waiting_index = -1
func _on_ItemList_item_selected(index):
	var editor = find_parent("Editor")
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
		if find_parent("Editor").selected_object_type != "Rail":
			find_parent("Editor").send_message("At first you need to select a rail,\nto which you want to add the Rail Logic Element!")
			hide_menu()
		else:
			$RailLogicMenu.show()


func _on_RailLogicMenu_item_selected(index):
	var editor = find_parent("Editor")
	hide_menu()
	if find_parent("Editor").selected_object_type != "Rail":
		find_parent("Editor").send_message("At first you need to select a rail,\nto which you want to add the Rail Logic Element!")
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


	pass







func _on_Content_Selector_resource_selected(complete_path):
	if complete_path == "": ## User canceled action
		return
	if current_waiting_index == -1: ## Not waiting for any input
		return
	if current_waiting_index == 1: ## Object
		find_parent("Editor").add_object(complete_path)
		current_waiting_index = -1
	pass # Replace with function body.



