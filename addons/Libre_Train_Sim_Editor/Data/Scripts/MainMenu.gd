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
	var index = $Play/Selection/Tracks/ItemList.get_selected_items()[0]
	get_tree().change_scene("res://Worlds/" + foundTracks[index])

func _on_ItemList_itemTracks_selected(index):
	currentTrack = load("res://Worlds/"+foundTracks[index]).instance()
	if currentTrack == null: print("HUHU")
	$Play/Info/Description.text = currentTrack.description
	$Play/Info/Screenshot.texture = load(currentTrack.picturePath)

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



