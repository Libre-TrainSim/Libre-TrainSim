extends Control

onready var editor_directory: String = jSaveManager.get_setting("editor_directory_path", "user://editor/")

var dir := Directory.new()
var tracks := {}


func _ready() -> void:
	_initialize_editor_directory()
	$PanelContainer/VBoxContainer/HBoxContainer/EditorPath.text = editor_directory
	_find_content()


func to_file_name(track_name: String) -> String:
	track_name = track_name.replace("/", "")
	track_name = track_name.replace('\\' , "")
	track_name = track_name.replace(" ", "")
	return track_name


func _initialize_editor_directory():
	if dir.open("user://") != OK:
		Logger.err("Can't open directory '%s'" % editor_directory, self)
		return
	dir.make_dir_recursive(editor_directory)


func _find_content():
	tracks = ContentLoader.get_editor_tracks()
	$PanelContainer/VBoxContainer/TracksList.set_data(tracks.keys())


func _initialize_mod_directory(entry_name: String) -> bool:
	var mod_path := editor_directory + entry_name
	if dir.dir_exists(mod_path):
		return false
	var worlds_path := "/Worlds/%s/" % entry_name
	dir.make_dir_recursive(mod_path + worlds_path)
	dir.copy("res://Data/Modules/World-Pattern.tscn", \
			"%s%s/%s.tscn" % [mod_path, worlds_path, entry_name])
	dir.copy("res://Data/Modules/World-Pattern.save", \
			"%s%s/%s.save" % [mod_path, worlds_path, entry_name])

	var authors := Authors.new()
	if ResourceSaver.save(mod_path.plus_file("authors.tres"), authors) != OK:
		Logger.warn("Can't save authors at path %s" % mod_path + "authors.tres", self)
	var content := ModContentDefinition.new()
	content.display_name = entry_name
	content.unique_name = "%s" % entry_name
	content.worlds.push_back("res://Mods/%s%s%s.tscn" % [entry_name, worlds_path, entry_name])
	if ResourceSaver.save(mod_path.plus_file("content.tres"), content) != OK:
		Logger.err("Can't save content at path %s" % mod_path + "content.tres", self)
		return false
	return true


func _on_UpdateEditorPathButton_pressed():
	editor_directory = $PanelContainer/VBoxContainer/HBoxContainer/EditorPath.text
	if !editor_directory.ends_with("/"):
		editor_directory += "/"
	$PanelContainer/VBoxContainer/HBoxContainer/EditorPath.text = editor_directory
	jSaveManager.save_setting("editor_directory_path", editor_directory)


func _on_TracksList_user_added_entry(entry_name):
	$PanelContainer/VBoxContainer/TracksList.remove_entry(entry_name)
	entry_name = to_file_name(entry_name)
	if !_initialize_mod_directory(entry_name):
		var msg: String = "Directory " + editor_directory + entry_name + " already exists.\nPlease choose a different name!"
		$PanelContainer/VBoxContainer/TracksList.show_error(msg)
		Logger.warn(msg, self)
		return
	$PanelContainer/VBoxContainer/TracksList.clear()
	_find_content()


func _on_TracksList_user_pressed_action(entry_names):
	var screenshot := Image.new()
	var texture := ImageTexture.new()
	if screenshot.load(entry_names[0].get_base_dir().plus_file("screenshot.png")) == OK:
		texture.create_from_image(screenshot)
	else:
		texture = null
	LoadingScreen.load_editor(entry_names[0], tracks[entry_names[0]][0], \
			tracks[entry_names[0]][1], texture)


func _on_Back_pressed() -> void:
	hide()
