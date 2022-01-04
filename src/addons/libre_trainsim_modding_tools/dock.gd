tool
extends VBoxContainer

var base: Control
var dir_select_dialog: FileDialog

func _on_new_mod_pressed() -> void:
	var popup = preload("new_mod_popup.tscn").instance()
	popup.base_control = base
	base.add_child(popup)
	popup.popup_centered()


func _on_LinkButton_pressed() -> void:
	OS.shell_open("https://www.libretrainsim.org/contribute")


func _on_open_addons_dir_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://addons"))


func _on_export_mod_pressed() -> void:
	dir_select_dialog = FileDialog.new()
	dir_select_dialog.rect_min_size = Vector2(500, 300)
	dir_select_dialog.rect_size = Vector2(500, 300)
	dir_select_dialog.resizable = true
	dir_select_dialog.window_title = "Select Mod to Export"
	dir_select_dialog.mode = FileDialog.MODE_OPEN_DIR
	dir_select_dialog.access = FileDialog.ACCESS_RESOURCES
	dir_select_dialog.current_dir = "res://Mods"
	dir_select_dialog.connect("dir_selected", self, "_on_export_dir_selected")
	base.add_child(dir_select_dialog)
	dir_select_dialog.popup_centered()


func _on_export_dir_selected(dir: String) -> void:
	dir_select_dialog.queue_free()

	var mod_name = dir.get_file()
	var mod_path = "user://addons/".plus_file(mod_name)

	var directory = Directory.new()
	directory.open("user://")
	directory.make_dir_recursive(mod_path)
	directory.change_dir(mod_path)

	var packer = PCKPacker.new()
	var ok = packer.pck_start(mod_path.plus_file(mod_name) + ".pck")
	if ok != OK:
		Logger.err("Error creating %s!" % mod_path.plus_file(mod_name) + ".pck", self)
		return

	var files = get_files_in_directory("res://Mods/".plus_file(mod_name))
	for file in files:
		ok = packer.add_file(file, file)
		if ok != OK:
			Logger.err("Could not add file %s to pck!" % file, self)

	ok = packer.flush(true)
	if ok != OK:
		Logger.err("Could not flush pck!", self)

	ok = directory.copy(dir.plus_file("content.tres"), mod_path.plus_file("content.tres"))
	if ok != OK:
		Logger.err("Unable to copy content.tres to mod folder!", self)


func get_files_in_directory(path: String) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			files.append_array(get_files_in_directory(path.plus_file(file_name)))
		else:
			files.append(path.plus_file(file_name))
		file_name = dir.get_next()
	return files
