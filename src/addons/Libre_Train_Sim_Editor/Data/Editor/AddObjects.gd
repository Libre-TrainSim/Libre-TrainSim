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
	$ItemList.show()
	$ShowMenu.text = " - "

func hide_menu():
	$ItemList.hide()
	$ShowMenu.text = " + "

var current_waiting_index = -1
func _on_ItemList_item_selected(index):
	var editor = find_parent("Editor")
	$ItemList.unselect_all()
	if index == 0: # Rail
		editor.add_rail()
	if index == 1: # Object
		var content_selector = get_parent().get_node("Content_Selector")
		content_selector.set_type(content_selector.OBJECTS)
		content_selector.show()
		current_waiting_index = 1
		pass
		
	hide_menu()
	

		
	
	
		


func _on_Content_Selector_resource_selected(complete_path):
	if complete_path == "": ## User canceled action
		return
	if current_waiting_index == -1: ## Not waiting for any input
		return
	if current_waiting_index == 1: ## Object
		find_parent("Editor").add_object(complete_path)
		current_waiting_index = -1
	pass # Replace with function body.
