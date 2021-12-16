extends Control

signal user_added_entry(entry_name) # string
signal user_removed_entries(entry_names) # array of strings
signal user_renamed_entry(old_name, new_name) # string
signal user_duplicated_entries(source_entry_names, duplicated_entry_names) # arrays of strings
signal user_copied_entries(entry_names)
signal user_pasted_entries(source_entry_names, source_jList_id, pasted_entry_names)
signal user_pressed_save(data) # array of strings (equal to entry_names)
signal user_selected_entry(entry_name) # string
signal user_pressed_action(entry_names) # array of strings (equal to entry_names)

export (String) var _id = "_random"
var id
export (String) var entry_duplicate_text = "_duplicate"

export (bool) var only_unique_entries_allowed = true
export (bool) var multi_selection_allowed = true
export (String) var custom_font_path = ""
export (bool) var enable_add_button = true
export (bool) var enable_remove_button = true
export (bool) var enable_rename_button = false
export (bool) var enable_duplicate_button = false
export (bool) var enable_copy_button = false
export (bool) var enable_paste_button = false
export (bool) var enable_save_button = false
export (bool) var enable_action_button = false

export (String) var add_button_text = "Add"
export (String) var remove_button_text = "Remove"
export (String) var rename_button_text = "Rename"
export (String) var duplicate_button_text = "Duplicate"
export (String) var copy_button_text = "Copy"
export (String) var paste_button_text = "Paste"
export (String) var save_button_text = "Save"
export (String) var action_button_text = "Custom Action"

export (bool) var update setget update_visible_buttons


func get_data():
	var entry_names = []
	for i in range(item_list.get_item_count()):
		entry_names.append(item_list.get_item_text(i))
	return entry_names


func set_data(entry_names : Array): # Input: Array of strings
	clear()
	for i in range (entry_names.size()):
		item_list.add_item(entry_names[i])


func clear():
	item_list.clear()
	$VBoxContainer/HBoxContainer/LineEdit.text = ""


func add_entry(entry_name : String):
	if only_unique_entries_allowed:
		entry_name = get_unique_entry_name(entry_name)
	item_list.add_item(entry_name)
	return entry_name


func remove_entry(entry_name : String):
	var entry_id = get_entry_id(entry_name)
	if entry_id != -1:
		remove_entry_id(entry_id)


func has_entry(entry_name : String):
	return -1 != get_entry_id(entry_name)


func select_entry(entry_name : String):
	if not has_entry(entry_name):
		print_debug("jList " + name + ": Entry " + entry_name + " not found. Dont selecting anything...")
	$VBoxContainer/ItemList.select(get_entry_id(entry_name))


func get_size():
	return item_list.get_item_count()#


func show_error(message := "This action is not allowed!"):
	$PopupDialog/Label.text = message
	$PopupDialog.popup_centered_minsize()


## Internal Code ###############################################################
var item_list


func _ready():
	update_visible_buttons(true)
	if multi_selection_allowed:
		$VBoxContainer/ItemList.select_mode = ItemList.SELECT_MULTI
	else:
		$VBoxContainer/ItemList.select_mode = ItemList.SELECT_SINGLE


func _unhandled_key_input(_event: InputEventKey) -> void:
	if $VBoxContainer/HBoxContainer/LineEdit.has_focus() and enable_add_button \
			and Input.is_action_just_pressed("ui_accept"):
		_on_Add_pressed()


func is_entry_name_unique(entry : String):
	for i in range(get_size()):
		if item_list.get_item_text(i) == entry:
			return true
	return false


func get_entry_id(entry : String):
	for i in range(get_size()):
		if item_list.get_item_text(i) == entry:
			return i
	return -1


func get_unique_entry_name(entry_name : String):
	while is_entry_name_unique(entry_name):
		entry_name = entry_name + entry_duplicate_text
	return entry_name


func rename_entry_id(entry_id : int, new_entry_name : String):
	if entry_id >= get_size():
		print_debug("jList " + name + ": rename_entry(): entry_id out of bounds! Skipping...")
		return
	if only_unique_entries_allowed:
		new_entry_name = get_unique_entry_name(new_entry_name)
	item_list.set_item_text(entry_id, new_entry_name)
	return new_entry_name


func duplicate_entry_id(entry_id : int):
	return add_entry(item_list.get_item_text(entry_id))


func remove_entry_id(entry_id : int):
	if entry_id >= get_size():
		print_debug("jList " + name + ": remove_entry_id(): entry_id out of bounds! Skipping...")
		return
	item_list.remove_item(entry_id)


func update_visible_buttons(newvar):
	$VBoxContainer/HBoxContainer/Add.visible = enable_add_button
	$VBoxContainer/HBoxContainer/Remove.visible = enable_remove_button
	$VBoxContainer/HBoxContainer/Rename.visible = enable_rename_button
	$VBoxContainer/HBoxContainer/Duplicate.visible = enable_duplicate_button
	$VBoxContainer/HBoxContainer/Copy.visible = enable_copy_button
	$VBoxContainer/HBoxContainer/Paste.visible = enable_paste_button
	$VBoxContainer/HBoxContainer/Save.visible = enable_save_button
	$VBoxContainer/HBoxContainer/Action.visible = enable_action_button

	$VBoxContainer/HBoxContainer/Add.text = TranslationServer.translate(add_button_text)
	$VBoxContainer/HBoxContainer/Remove.text = TranslationServer.translate(remove_button_text)
	$VBoxContainer/HBoxContainer/Rename.text = TranslationServer.translate(rename_button_text)
	$VBoxContainer/HBoxContainer/Duplicate.text = TranslationServer.translate(duplicate_button_text)
	$VBoxContainer/HBoxContainer/Copy.text = TranslationServer.translate(copy_button_text)
	$VBoxContainer/HBoxContainer/Paste.text = TranslationServer.translate(paste_button_text)
	$VBoxContainer/HBoxContainer/Save.text = TranslationServer.translate(save_button_text)
	$VBoxContainer/HBoxContainer/Action.text = TranslationServer.translate(action_button_text)

	_update_fonts()
	update = false


func _update_fonts():
	if custom_font_path == "":
		return
	if not jEssentials.does_path_exist(custom_font_path):
		return
	var font = load(custom_font_path)
	$VBoxContainer/HBoxContainer/LineEdit.add_font_override("font", font)
	$VBoxContainer/HBoxContainer/Add.add_font_override("font", font)
	$VBoxContainer/HBoxContainer/Remove.add_font_override("font", font)
	$VBoxContainer/HBoxContainer/Rename.add_font_override("font", font)
	$VBoxContainer/HBoxContainer/Duplicate.add_font_override("font", font)
	$VBoxContainer/HBoxContainer/Copy.add_font_override("font", font)
	$VBoxContainer/HBoxContainer/Paste.add_font_override("font", font)
	$VBoxContainer/HBoxContainer/Save.add_font_override("font", font)
	$VBoxContainer/HBoxContainer/Action.add_font_override("font", font)

	$VBoxContainer/ItemList.add_font_override("font", font)
	$PopupDialog/Label.add_font_override("font", font)
	$PopupDialog/Okay.add_font_override("font", font)


## Button Signals ##############################################################
func _enter_tree():
	item_list = $VBoxContainer/ItemList
	if owner != self:
		if _id == "_random":
			randomize()
			id = String(randi())
		else:
			id = _id


func _on_Add_pressed():
	if $VBoxContainer/HBoxContainer/LineEdit.text == "":
		return
	var entry_name = add_entry($VBoxContainer/HBoxContainer/LineEdit.text)
	$VBoxContainer/HBoxContainer/LineEdit.text = ""
	emit_signal("user_added_entry", entry_name)


func _on_Remove_pressed():
	if item_list.get_selected_items().size() == 0:
		return
	var removed_entries = []
	while item_list.get_selected_items().size() != 0:
		removed_entries.append(item_list.get_item_text(item_list.get_selected_items()[0]))
		remove_entry_id(item_list.get_selected_items()[0])
	emit_signal("user_removed_entries", removed_entries)


func _on_Rename_pressed():
	var new_text = $VBoxContainer/HBoxContainer/LineEdit.text
	if item_list.get_selected_items().size() != 1:
		return
	var entry_id = item_list.get_selected_items()[0]
	var old_text = item_list.get_item_text(entry_id)
	if new_text == "":
		return
	if new_text == old_text:
		return
	rename_entry_id(entry_id, new_text)
	emit_signal("user_renamed_entry", old_text, new_text)
	$VBoxContainer/HBoxContainer/LineEdit.text = ""


func _on_Duplicate_pressed():
	if  item_list.get_selected_items().size() == 0:
		return
	var source_entry_ids = item_list.get_selected_items()
	var source_entry_names = []
	var duplicated_entry_names = []
	for entry_id in source_entry_ids:
		source_entry_names.append(item_list.get_item_text(entry_id))
		duplicated_entry_names.append(duplicate_entry_id(entry_id))
	emit_signal("user_duplicated_entries", source_entry_names, duplicated_entry_names)


func _on_Copy_pressed(): # stores the current entry_names into the global buffer
	if  item_list.get_selected_items().size() == 0:
		return
	var source_entry_names = []
	var source_entry_ids = item_list.get_selected_items()
	for entry_id in source_entry_ids:
		source_entry_names.append(item_list.get_item_text(entry_id))
	OS.clipboard = var2str(source_entry_names)
	emit_signal("user_copied_entries", source_entry_names)


func _on_Paste_pressed(): # Adds entry_names from global buffer into jList.
	var source_entry_names = str2var(OS.clipboard)
	if source_entry_names == null:
		return
	var pasted_entry_names = []
	for source_entry in source_entry_names:
		pasted_entry_names.append(add_entry(source_entry))
	emit_signal("user_pasted_entries", source_entry_names, id, pasted_entry_names)


func _on_Save_pressed():
	emit_signal("user_pressed_save", get_data())


func _on_Action_pressed():
	if  item_list.get_selected_items().size() == 0:
		return
	var source_entry_names = []
	var source_entry_ids = item_list.get_selected_items()
	for entry_id in source_entry_ids:
		source_entry_names.append(item_list.get_item_text(entry_id))
	emit_signal("user_pressed_action", source_entry_names)


func _on_ItemList_item_activated(index):
	_on_Action_pressed()


func _on_PopupDiaglog_Okay_pressed():
	$PopupDialog.hide()


func _on_ItemList_multi_selected(index, selected):
	var selected_items = item_list.get_selected_items()
	if selected_items.size() == 1:
		emit_signal("user_selected_entry", item_list.get_item_text(selected_items[0]))


func _on_ItemList_item_selected(index):
	$VBoxContainer/HBoxContainer/LineEdit.text = item_list.get_item_text(index)
