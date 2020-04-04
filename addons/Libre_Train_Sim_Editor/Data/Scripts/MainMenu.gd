extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var save_path = OS.get_executable_path().get_base_dir()+"config.cfg"
var config = ConfigFile.new()
var load_response = config.load(save_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	update_config()
	OS.window_fullscreen = config.get_value("Settings", "fullscreen", true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

var foundTracks = []
var foundContentPacks = []

var currentTrack

func _on_Quit_pressed():
	get_tree().quit()


func _on_BackPlay_pressed():
	$Play.hide()
	$MenuBackground.hide()
	$Front.show()


func _on_PlayFront_pressed():
	update_track_list()
	$Play.show()
	$MenuBackground.show()
	$Front.hide()

func _on_Content_pressed():
	update_content()
	$Front.hide()
	$MenuBackground.show()
	$Content.show()

func _on_SettingsFrong_pressed():
	$Front.hide()
	$MenuBackground.show()
	$Settings.show()
	update_settings()
	pass # Replace with function body.
	



func update_config():
	## Get All .pck files:
	foundContentPacks = []
	var dir = Directory.new()
	dir.open(OS.get_executable_path().get_base_dir())
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "":
			break
		if file.get_extension() == "pck":
			foundContentPacks.append(file)
	dir.list_dir_end()
	print("Found Content Packs: " + String(foundContentPacks))
	
	for contentPack in foundContentPacks:
		if ProjectSettings.load_resource_pack(contentPack, false):
			print("Loading Content Pack "+ contentPack+" successfully finished")
			
	## Get all found Tracks:
	foundTracks = []
	var dir2 = Directory.new()
	dir2.open("res://Worlds")
	dir2.list_dir_begin()
	while(true):
		var file = dir2.get_next()
		if file == "":
			break
		print(file)
		if file.get_extension() == "tscn":
			foundTracks.append(file)
	dir2.list_dir_end()
	print("Found Tracks: " + String(foundTracks))

func update_track_list():
	$Play/Selection/Tracks/ItemList.clear()
	for track in foundTracks:
		$Play/Selection/Tracks/ItemList.add_item(track.get_file().get_basename())
	

# Play Page:
func _on_PlayPlay_pressed():
	if currentScenario == "" or currentTrack == "": return
	var index = $Play/Selection/Tracks/ItemList.get_selected_items()[0]
	Root.currentScenario = currentScenario
	get_tree().change_scene("res://Worlds/" + foundTracks[index])

func _on_ItemList_itemTracks_selected(index):
	var save_path = "res://Worlds/" + foundTracks[index].get_basename() + "-scenarios.cfg"
	var config = ConfigFile.new()
	var load_response = config.load(save_path)
	
	var wData = config.get_value("WorldConfig", "Data", null)
	if wData == null: 
		print(save_path)
		$Play/Info/Description.text = "No Scenario data could be found. This Track is obsolete. Sadly you cant play it."
		$Play/Selection/Scenarios.hide()
		return
	$Play/Info/Description.text = wData["TrackDesciption"]
	$Play/Info/Info/Author.text = " Author: "+ wData["Author"] + " "
	$Play/Info/Info/ReleaseDate.text = " Release: " + String(wData["ReleaseDate"][1]) + " " + String(wData["ReleaseDate"][2]) + " "
	$Play/Info/Screenshot.texture = load(wData["ThumbnailPath"])
	
	$Play/Selection/Scenarios.show()
	$Play/Selection/Scenarios/ItemList.clear()
	var scenarios = config.get_value("Scenarios", "List", [])
	for scenario in scenarios:
		$Play/Selection/Scenarios/ItemList.add_item(scenario)

## Content Page:
func update_content():
	$Content/Label.text = "To add content you have to place .pck files at " + OS.get_executable_path().get_base_dir()
	$Content/ItemList.clear()
	for contentPack in foundContentPacks:
		$Content/ItemList.add_item(contentPack)



func _on_BackContent_pressed():
	$MenuBackground.hide()
	$Content.hide()
	$Front.show()

func _on_ReloadContent_pressed():
	update_config()
	update_content()




## Settings:
func _on_FullscreenSettings_pressed():
	config.set_value("Settings", "fullscreen", $Settings/GridContainer/Fullscreen.pressed)
	config.save(save_path)
	OS.window_fullscreen = $Settings/GridContainer/Fullscreen.pressed

func update_settings():
	$Settings/GridContainer/Fullscreen.pressed = config.get_value("Settings", "fullscreen", true)


func _on_BackSettings_pressed():
	$Settings.hide()
	$MenuBackground.hide()
	$Front.show()
	



var currentScenario
func _on_ItemList_scenario_selected(index):
	currentScenario = $Play/Selection/Scenarios/ItemList.get_item_text(index)
	var save_path = "res://Worlds/" + foundTracks[$Play/Selection/Tracks/ItemList.get_selected_items()[0]].get_basename() + "-scenarios.cfg"
	var config = ConfigFile.new()
	var load_response = config.load(save_path)
	var sData = config.get_value("Scenarios", "sData", {})
	$Play/Info/Description.text = sData[currentScenario]["Description"]
