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

func _on_ItemList_item_selected(index):
	var editor = find_parent("Editor")
	$ItemList.unselect_all()
	if index == 0: # Rail
		editor.add_rail()
		
	hide_menu()
		
	
	
		
