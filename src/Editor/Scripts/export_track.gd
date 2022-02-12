class_name ExportTrack

static func export_editor_track(track_name: String, export_path: String) -> String:
	var editor_directory = jSaveManager.get_setting("editor_directory_path", "user://editor/")
	var mod_path = editor_directory.plus_file(track_name)
	export_path = export_path.plus_file(track_name)

	var directory := Directory.new()
	directory.open("user://")
	directory.make_dir_recursive(export_path)
	directory.change_dir(export_path)

	var packer = PCKPacker.new()
	var ok = packer.pck_start(export_path.plus_file(track_name) + ".pck")
	if ok != OK:
		Logger.err("Error creating %s!" % export_path.plus_file(track_name) + ".pck", null)
		return "Error creating %s!" % export_path.plus_file(track_name) + ".pck"

	var files = get_files_in_directory(mod_path)
	var errors = ""
	for file in files:
		ok = packer.add_file(file.replace(editor_directory, "res://Mods/"), file)
		if ok != OK:
			Logger.err("Could not add file %s to pck!" % file, null)
			errors += "\nCould not add file %s to pck!" % file

	ok = packer.flush(true)
	if ok != OK:
		Logger.err("Could not flush pck!", null)
		return "Could not flush pck!"
	ok = directory.copy(mod_path.plus_file("content.tres"), export_path.plus_file("content.tres"))
	if ok != OK:
		Logger.err("Unable to copy content.tres to mod folder!", "ExportTrack")
	return "Track exported to the addons folder." + errors


static func get_files_in_directory(path: String) -> Array:
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
