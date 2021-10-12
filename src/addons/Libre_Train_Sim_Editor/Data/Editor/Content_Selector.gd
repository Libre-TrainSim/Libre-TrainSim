extends VBoxContainer


enum {MATERIALS, OBJECTS, RAIL_TYPES, SIGNAL_TYPES, SOUNDS, TEXTURES}

signal resource_selected(complete_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if visible and Input.is_action_just_pressed("ui_accept"):
		emit_selected_resource()

func clear_text():
	$HBoxContainer/LineEdit.text = ""

func _on_ClearText_pressed():
	clear_text()

var current_type = null
func set_type(type):
	current_type = type
	clear_text()
	crawl_directory_for_resources()
	update_ItemList()
	$HBoxContainer/LineEdit.grab_focus()
	show()

var current_resources = []
func crawl_directory_for_resources():
	current_resources.clear()
	var resource_subfolders = Root.get_subfolders_of("res://Resources")
	print(resource_subfolders)
	if current_type == MATERIALS:
		for resource_subfolder in resource_subfolders:
			var found_files = {"Array" : []}
			Root.crawlDirectory("res://Resources/"+ resource_subfolder + "/Materials", found_files, "tres")
			for file in found_files["Array"]:
				current_resources.append(file.replace("res://Resources/", "").replace("/Materials", "").get_basename())
	if current_type == OBJECTS:
		for resource_subfolder in resource_subfolders:
			var found_files = {"Array" : []}
			Root.crawlDirectory("res://Resources/"+ resource_subfolder + "/Objects", found_files, "import")
			Root.crawlDirectory("res://Resources/"+ resource_subfolder + "/Objects", found_files, "obj")
			for file in found_files["Array"]:
				current_resources.append(file.replace("res://Resources/", "").replace("/Objects", "").get_basename().get_basename())
	current_resources = jEssentials.remove_duplicates(current_resources)
	if current_type == RAIL_TYPES:
		for resource_subfolder in resource_subfolders:
			var found_files = {"Array" : []}
			Root.crawlDirectory("res://Resources/"+ resource_subfolder + "/RailTypes", found_files, "tscn")
			for file in found_files["Array"]:
				current_resources.append(file.replace("res://Resources/", "").replace("/RailTypes", "").get_basename())
	if current_type == SIGNAL_TYPES:
		for resource_subfolder in resource_subfolders:
			var found_files = {"Array" : []}
			Root.crawlDirectory("res://Resources/"+ resource_subfolder + "/SignalTypes", found_files, "tscn")
			for file in found_files["Array"]:
				current_resources.append(file.replace("res://Resources/", "").replace("/SignalTypes", "").get_basename())
	if current_type == SOUNDS:
		for resource_subfolder in resource_subfolders:
			var found_files = {"Array" : []}
			Root.crawlDirectory("res://Resources/"+ resource_subfolder + "/Sounds", found_files, "ogg")
			for file in found_files["Array"]:
				current_resources.append(file.replace("res://Resources/", "").replace("/Sounds", "").get_basename())
	if current_type == TEXTURES:
		for resource_subfolder in resource_subfolders:
			var found_files = {"Array" : []}
			Root.crawlDirectory("res://Resources/"+ resource_subfolder + "/Textures", found_files, "png")
			for file in found_files["Array"]:
				current_resources.append(file.replace("res://Resources/", "").replace("/Texutres", "").get_basename())
	print(current_resources)

func update_ItemList():
	$ItemList.clear()
	if $HBoxContainer/LineEdit.text == "":
		for resource in current_resources:
			$ItemList.add_item(resource)
	else:
		for resource in current_resources:
			if resource.to_lower().find($HBoxContainer/LineEdit.text.to_lower()) != -1:
				$ItemList.add_item(resource)
	$ItemList.sort_items_by_text()

func _on_LineEdit_text_changed(new_text):
	update_ItemList()


func _on_ItemList_item_activated(index):
	emit_selected_resource()

func emit_selected_resource():
	if $ItemList.get_selected_items().size() == 0:
		return
	var index = $ItemList.get_selected_items()[0]
	var resource = $ItemList.get_item_text(index)
	var split_position = resource.find("/")
	var complete_path = "res://Resources/" + resource.left(split_position)
	if current_type == MATERIALS:
		complete_path += "/Materials" + resource.right(split_position) + ".tres"
	elif current_type == OBJECTS:
		complete_path += "/Objects" + resource.right(split_position) + ".obj"
	elif current_type == RAIL_TYPES:
		complete_path += "/RailTypes" + resource.right(split_position) + ".tscn"
	elif current_type == SIGNAL_TYPES:
		complete_path += "/SignalTypes" + resource.right(split_position) + ".tscn"
	elif current_type == SOUNDS:
		complete_path += "/Sounds" + resource.right(split_position) + ".ogg"
	elif current_type == TEXTURES:
		complete_path += "/Textures" + resource.right(split_position) + ".png"

	hide()
	get_parent()._on_dialog_closed()
	emit_signal("resource_selected", complete_path)




func _on_Select_pressed():
	emit_selected_resource()
	get_parent()._on_dialog_closed()




func _on_Cancel_pressed():
	hide()
	clear_text()
	emit_signal("resource_selected", "")
	get_parent()._on_dialog_closed()
