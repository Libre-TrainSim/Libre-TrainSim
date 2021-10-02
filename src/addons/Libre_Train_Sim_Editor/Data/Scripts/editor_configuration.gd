extends Control

var editor_directory

func show():
	initialize_UI()
	initialize_editor_directory()
	load_additional_resources()
	.show()


func initialize_UI():
	editor_directory = jSaveManager.get_setting("editor_directory_path", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)+"Libre-TrainSim-Editor/")
	jSaveManager.save_setting("editor_directory_path", editor_directory)
	$PanelContainer/VBoxContainer/HBoxContainer/EditorPath.text = editor_directory

	var track_paths = jEssentials.find_files_recursively(editor_directory + "Worlds/", "tscn")
	var tracks = []
	for track_path in track_paths:
		tracks.append(track_path.get_file().get_basename())

	$PanelContainer/VBoxContainer/TracksList.set_data(tracks)



func initialize_editor_directory():
	var dir = Directory.new()
	if dir.open("user://") != OK:
		Logger.err("Can't open directory '%s'" % editor_directory, self)
		return
	dir.make_dir_recursive(editor_directory)
	dir.make_dir_recursive(editor_directory + "Resources/")
	dir.make_dir_recursive(editor_directory + "Worlds/")


func _on_UpdateEditorPathButton_pressed():
	editor_directory = $PanelContainer/VBoxContainer/HBoxContainer/EditorPath.text
	initialize_editor_directory()
	jSaveManager.save_setting("editor_directory_path", editor_directory)


func initialize_track_directory(entry_name):
	var dir = Directory.new()
	if dir.open(editor_directory) != OK:
		Logger.err("Can't open directory '%s'" % editor_directory, self)
		return
	if dir.dir_exists(editor_directory + "Worlds/" + entry_name):
		$PanelContainer/VBoxContainer/TracksList.revoke_last_user_action("Given Directory " + editor_directory + "Worlds/" + entry_name + " already exists.\nPlease delete this direcotry to create a new track with this name!")
		return
	dir.make_dir_recursive(editor_directory + "Worlds/" + entry_name)

	create_resource_directory_structure(entry_name)

	dir.copy("res://addons/Libre_Train_Sim_Editor/Data/Modules/World-Pattern.tscn", editor_directory + "Worlds/" + entry_name + "/" + entry_name + ".tscn")
	dir.copy("res://addons/Libre_Train_Sim_Editor/Data/Modules/World-Pattern.save", editor_directory + "Worlds/" + entry_name + "/" + entry_name + ".save")


func create_resource_directory_structure(track_name):
	var dir = Directory.new()
	if dir.open(editor_directory) != OK:
		Logger.err("Can't open directory '%s'" % editor_directory, self)
		return
	dir.make_dir_recursive(editor_directory + "Resources/" + track_name + "/Blender")
	dir.make_dir_recursive(editor_directory + "Resources/" + track_name + "/Materials")
	dir.make_dir_recursive(editor_directory + "Resources/" + track_name + "/Objects")
	dir.make_dir_recursive(editor_directory + "Resources/" + track_name + "/RailTypes")
	dir.make_dir_recursive(editor_directory + "Resources/" + track_name + "/Signals")
	dir.make_dir_recursive(editor_directory + "Resources/" + track_name + "/Sounds")
	dir.make_dir_recursive(editor_directory + "Resources/" + track_name + "/Textures")


func _on_TracksList_user_added_entry(entry_name):
	$PanelContainer/VBoxContainer/TracksList.remove_entry(entry_name)
	entry_name = remove_inappropriate_signs_from_track_name(entry_name)
	$PanelContainer/VBoxContainer/TracksList.add_entry(entry_name)
	initialize_track_directory(entry_name)


func remove_inappropriate_signs_from_track_name(track_name):
	track_name = track_name.replace("/", "")
	track_name = track_name.replace('\\' , "")
	track_name = track_name.replace(" ", "")
	return track_name


func _on_TracksList_user_renamed_entry(old_name, new_name):
	rename_track(old_name, new_name)


func rename_track(old_name, new_name):
	new_name = remove_inappropriate_signs_from_track_name(new_name)
	jEssentials.copy_folder_recursively(editor_directory + "Worlds/" + old_name, \
			editor_directory + "Worlds/" + new_name)
	var dir = Directory.new()
	if dir.open(editor_directory + "Worlds/" + new_name) != OK:
		Logger.err("Can't open directory '%s'" % editor_directory, self)
		return

	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "":
			break
		if file == ".":
			continue
		if file == "..":
			continue
		var dir2 = Directory.new()
		dir2.rename(editor_directory + "Worlds/" + new_name + "/" + file, editor_directory + "Worlds/" + new_name + "/" + file.replace(old_name, new_name))

	dir.list_dir_end()
	jEssentials.remove_folder_recursively(editor_directory + "Worlds/" + old_name)
	create_resource_directory_structure(new_name)


func _on_TracksList_user_pressed_action(entry_names):
	var entry_name = entry_names[0]
	Root.current_editor_track = entry_name
	get_tree().change_scene_to(load("res://addons/Libre_Train_Sim_Editor/Data/Modules/Editor.tscn"))


func load_additional_resources():
	var pck_file = editor_directory + "/.cache/additional_resources.pck"
	if jEssentials.does_path_exist(pck_file):
		ProjectSettings.load_resource_pack(pck_file)


func _on_ImportDescriptionOkay_pressed():
	$ImportDescription.hide()


func _on_DonwloadResourceImporter_pressed():
	OS.shell_open("https://github.com/Jean28518/Libre-TrainSim-Resource-Importer/releases/latest")


func _on_ImportResources_pressed():
	$ImportDescription/VBoxContainer/RichTextLabel.text = tr("IMPORT_DESCRIPTION")
	$ImportDescription.show()


func _on_Back_pressed() -> void:
	hide()
