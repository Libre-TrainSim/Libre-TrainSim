extends VBoxContainer


enum {MATERIALS, OBJECTS, RAIL_TYPES, SIGNAL_TYPES, SOUNDS, TEXTURES}

signal resource_selected(complete_path)


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

	if current_type == MATERIALS:
		for folder in ContentLoader.repo.material_folders:
			Root.crawlDirectory(folder, current_resources, ["tres", "res"])

	if current_type == OBJECTS:
		for folder in ContentLoader.repo.object_folders:
			Root.crawlDirectory(folder, current_resources, ["obj"])

	if current_type == RAIL_TYPES:
		for folder in ContentLoader.repo.rail_type_folders:
			Root.crawlDirectory(folder, current_resources, ["tscn", "scn"])

	if current_type == SIGNAL_TYPES:
		for folder in ContentLoader.repo.signal_type_folders:
			Root.crawlDirectory(folder, current_resources, ["tscn", "scn"])

	if current_type == SOUNDS:
		for folder in ContentLoader.repo.sound_folders:
			Root.crawlDirectory(folder, current_resources, ["ogg", "wav", "mp3"])

	if current_type == TEXTURES:
		for folder in ContentLoader.repo.texture_folders:
			Root.crawlDirectory(folder, current_resources, ["png", "jpg", "jpeg", "bmp"])

	current_resources = jEssentials.remove_duplicates(current_resources)

	Logger.vlog(current_resources)


func update_ItemList():
	$ItemList.clear()
	if $HBoxContainer/LineEdit.text == "":
		for resource in current_resources:
			$ItemList.add_item(resource.get_file())
	else:
		for resource in current_resources:
			if resource.get_file().to_lower().find($HBoxContainer/LineEdit.text.to_lower()) != -1:
				$ItemList.add_item(resource.get_file())
	$ItemList.sort_items_by_text()


func _on_LineEdit_text_changed(new_text):
	update_ItemList()


func _on_ItemList_item_activated(index):
	emit_selected_resource()


func emit_selected_resource():
	if $ItemList.get_selected_items().size() == 0:
		return
	# TODO: rework the item list, I don't like this search...
	var index = $ItemList.get_selected_items()[0]
	var text = $ItemList.get_item_text(index)
	var res
	for resource in current_resources:
		if resource.ends_with(text):
			res = resource
			break

	hide()
	emit_signal("resource_selected", res)

func _on_Select_pressed():
	emit_selected_resource()


func _on_Cancel_pressed():
	hide()
	clear_text()
	emit_signal("resource_selected", "")
