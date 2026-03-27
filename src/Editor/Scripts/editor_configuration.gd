extends Control


# TODO: move into project settings?
@onready var editor_directory: String = jSaveManager.get_setting("editor_directory_path", "user://editor/")
@onready var track_list := $PanelContainer/VBoxContainer/TracksList as jList
@onready var editor_path := $PanelContainer/VBoxContainer/HBoxContainer/EditorPath as LineEdit


var dir := DirAccess.open("res://")
var tracks := {}


func _ready() -> void:
	_initialize_editor_directory()
	editor_path.text = editor_directory
	_find_content()
	$PanelContainer/VBoxContainer/TracksList/VBoxContainer/ItemList.select(0)

func _on_draw() -> void:
	if tracks.is_empty():
		$PanelContainer/VBoxContainer/TracksList/VBoxContainer/HBoxContainer/Back.grab_focus()
	else:
		$PanelContainer/VBoxContainer/TracksList/VBoxContainer/ItemList.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_Back_pressed()
		accept_event()


func to_file_name(track_name: String) -> String:
	track_name = track_name.replace("/", "")
	track_name = track_name.replace('\\' , "")
	track_name = track_name.replace(" ", "")
	return track_name


func _initialize_editor_directory():
	if DirAccess.open("user://") == null:
		Logger.err("Can't open directory '%s'" % editor_directory, self)
		return
	DirAccess.make_dir_recursive_absolute(editor_directory)


func _find_content():
	tracks = ContentLoader.get_editor_tracks()
	track_list.set_data(tracks.keys())


func _initialize_mod_directory(entry_name: String) -> bool:
	var mod_path := editor_directory + entry_name
	if dir.dir_exists(mod_path):
		return false

	var worlds_path := "Worlds/" + entry_name
	DirAccess.make_dir_recursive_absolute(mod_path + "/" + worlds_path)
	DirAccess.make_dir_recursive_absolute(mod_path + "/" + worlds_path + "/chunks")
	DirAccess.make_dir_recursive_absolute(mod_path + "/" + worlds_path + "/scenarios")

	dir.copy("res://Data/Modules/World-Pattern.tscn", \
			mod_path + "/" + worlds_path + "/" + entry_name + ".tscn")

	var chunk_0_0 := preload("res://Data/Modules/chunk_prefab.tscn").instantiate() as Chunk
	chunk_0_0.name = "chunk_0_0"
	chunk_0_0.rails = ["Rail"]
	var packed_chunk := PackedScene.new()
	if packed_chunk.pack(chunk_0_0) != OK:
		Logger.err("Failed to pack default chunk", self)
	if ResourceSaver.save(packed_chunk, mod_path + "/" + worlds_path + "/" + "chunks" + "/" + "chunk_0_0.tscn") != OK:
		Logger.err("Failed to write default chunk to disk", self)
	chunk_0_0.free()

	var authors := Authors.new()
	if ResourceSaver.save(authors, mod_path + "/" + "authors.tres") != OK:
		Logger.err("Can't save authors at path %s" % mod_path + "authors.tres", self)

	var content := ModContentDefinition.new()
	content.display_name = entry_name
	content.unique_name = "%s" % entry_name
	content.worlds.push_back("res://Mods/" + entry_name + "/" + worlds_path + "/" + entry_name + ".tscn")
	if ResourceSaver.save(content, mod_path + "/" + "content.tres") != OK:
		Logger.err("Can't save content at path %s" % mod_path + "content.tres", self)
		return false

	var world_config = WorldConfig.new()
	world_config.title = entry_name
	var path = mod_path + "/" + worlds_path + "/" + entry_name + "_config.tres"
	var err = ResourceSaver.save(world_config, path)
	if err != OK:
		Logger.err("Can't save WorldConfig at %s (Reason %s)" % [path, err], self)
		return false

	return true


func _on_UpdateEditorPathButton_pressed():
	editor_directory = editor_path.text
	if !editor_directory.ends_with("/"):
		editor_directory += "/"
	editor_path.text = editor_directory
	jSaveManager.save_setting("editor_directory_path", editor_directory)
	_initialize_editor_directory()
	track_list.clear()
	_find_content()


func _on_TracksList_user_added_entry(entry_name):
	track_list.remove_entry(entry_name)
	entry_name = to_file_name(entry_name)
	if !_initialize_mod_directory(entry_name):
		var msg: String = "DirAccess " + editor_directory + entry_name + " already exists.\nPlease choose a different name!"
		track_list.show_error(msg)
		Logger.warn(msg, self)
		return


func _on_TracksList_user_pressed_action(entry_names):
	var screenshot := Image.new()
	var texture: ImageTexture
	if screenshot.load(entry_names[0].get_base_dir() + "/screenshot.png") == OK:
		texture = ImageTexture.create_from_image(screenshot)
	else:
		texture = null

	Root.current_track = entry_names[0]
	LoadingScreen.load_editor(entry_names[0], texture)


func _on_TracksList_user_removed_entries(entry_names):
	# jList is only in single selection mode. entry_names.size() == 1
	assert(entry_names.size()==1)
	jEssentials.remove_folder_recursively(editor_directory + "/" + tracks[entry_names[0]][0].unique_name)


func _on_Back_pressed() -> void:
	hide()
