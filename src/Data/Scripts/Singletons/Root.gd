extends Node

var currentTrack: String
var currentScenario: String
var currentTrain: String
var EasyMode: bool = true
var mobile_version: bool = OS.has_feature("mobile")

var start_menu_in_play_menu: bool = false

var ingame_pause: bool = false

var world: Node  ## Reference to world

var Editor: bool = false
var current_editor_track: String = ""  # Name of track


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	set_low_resolution(mobile_version)


func _unhandled_key_input(_event) -> void:
	if Engine.is_editor_hint():
		return
	if Input.is_action_just_pressed("ingame_pause"):
		if not Root.Editor and not Engine.is_editor_hint():
			if ingame_pause:
				get_tree().paused = false
				ingame_pause = false
			else:
				get_tree().paused = true
				ingame_pause = true
				jEssentials.show_message(tr("PAUSE_MODE_ENABLED"))
	if Input.is_action_just_released("fullscreen"):
		jSettings.set_fullscreen(!OS.window_fullscreen)


## Get appropriate name for new object. Used for adding and renaming nodes at ingame editor
func name_node_appropriate(node: Node, wanted_name: String, parent_node: Node) -> String:
	# Remove last Numbers from wanted name
	while(wanted_name[-1].is_valid_integer()):
		wanted_name.erase(wanted_name.length() -1, 1)

	wanted_name = wanted_name.replace(" " , "")
	wanted_name = wanted_name.validate_node_name()

	if not parent_node.has_node(wanted_name):
		node.name = wanted_name
		return wanted_name

	var counter: int = 2
	var base_name: String = wanted_name

	while(true):
		var new_name: String = base_name + String(counter)
		if not parent_node.has_node(new_name):
			node.name = new_name
			return new_name
		counter += 1
	return ""


# Searches for translation files with trackName in res://Translations/
func checkAndLoadTranslationsForTrack(trackName: String) -> void:
	Logger.vlog(trackName.get_file().get_basename())
	var trackTranslations := []
	var dir := Directory.new()
	var _unused = dir.open("res://Translations")
	_unused = dir.list_dir_begin()
	while(true):
		var file: String = dir.get_next()
		if file == "":
				break
		if file.get_extension() == "translation":
			if file.get_file().begins_with(trackName):
				trackTranslations.append("res://Translations/" + file.get_file())
				Logger.vlog("Track Translation Found " + "res://Translations/" + file.get_file())
	for trackTranslationPath in trackTranslations:
		var trackTranslation: Translation = load(trackTranslationPath)
		Logger.vlog(trackTranslation.locale)
		TranslationServer.add_translation(trackTranslation)


# Searches for translation files wich are located in the same folder as the train.tscn.
# Gets the full path to train.tscn as input
func checkAndLoadTranslationsForTrain(trainDirPath: String) -> void:
	Logger.vlog(trainDirPath)
	var trainTranslations := []
	var dir := Directory.new()
	var _unused = dir.open(trainDirPath)
	_unused = dir.list_dir_begin()
	while(true):
		var file: String = dir.get_next()
		if file == "":
				break
		if file.get_extension() == "translation":
			trainTranslations.append(trainDirPath+"/"+file)
			Logger.vlog("Track Translation Found " + "res://Translations/" + file.get_file())
	for trainTranslationPath in trainTranslations:
		var tainTranslation: Translation = load(trainTranslationPath)
		Logger.vlog(tainTranslation.locale)
		TranslationServer.add_translation(tainTranslation)


func crawlDirectory(directoryPath: String, foundFiles: Array, fileExtensions: Array) -> void:
	var dir := Directory.new()
	if dir.open(directoryPath) != OK:
		return
	var _unused = dir.list_dir_begin()

	while(true):
		var file: String = dir.get_next()
		if file == "":
			break
		if file.begins_with("."):
			continue
		if dir.current_is_dir():
			if directoryPath.ends_with("/"):
				crawlDirectory(directoryPath+file, foundFiles, fileExtensions)
			else:
				crawlDirectory(directoryPath+"/"+file, foundFiles, fileExtensions)
		else:
			if file.get_extension() in fileExtensions:
				var exportString: String
				if directoryPath.ends_with("/"):
					exportString = directoryPath +file
				else:
					exportString = directoryPath +"/"+file
				foundFiles.append(exportString)
	dir.list_dir_end()


func get_subfolders_of(directoryPath: String) -> Array:
	var dir := Directory.new()
	if dir.open(directoryPath) != OK:
		return []
	var _unused = dir.list_dir_begin()
	var folder_names: Array = []
	while(true):
		var file: String = dir.get_next()
		if file == "":
			break
		if file.begins_with("."):
			continue
		if dir.current_is_dir():
			folder_names.append(file)
	dir.list_dir_end()
	return folder_names


# approaches 'ist' value to 'soll' value in one second  (=smooth transitions from current 'ist' value to 'soll' value)
func clampViaTime(soll: float, ist: float, delta: float) -> float:
	ist += (soll-ist)*delta
	return ist


func fix_frame_drop() -> void:
	if not jSettings.get_framedrop_fix():
		return
	jEssentials.call_delayed(0.7, self,  "set_fullscreen", [!jSettings.get_fullscreen()])
	jEssentials.call_delayed(0.9, self,  "set_fullscreen", [jSettings.get_fullscreen()])


func set_fullscreen(value: bool) -> void:
	OS.window_fullscreen = value


func set_low_resolution(value: bool) -> void:
	if value:
		if ProjectSettings.get_setting("display/window/stretch/mode") == "viewport":
			return
		ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
		ProjectSettings.set_setting("display/window/stretch/aspect", "keep")
		ProjectSettings.set_setting("display/window/size/width", "1280")
		ProjectSettings.set_setting("display/window/size/height", "720")
	else:
		ProjectSettings.set_setting("display/window/stretch/mode", "disabled")
		ProjectSettings.set_setting("display/window/stretch/aspect", "ignore")
		ProjectSettings.set_setting("display/window/size/width", "800")
		ProjectSettings.set_setting("display/window/size/height", "600")
