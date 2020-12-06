extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export var version = ""
var save_path = OS.get_executable_path().get_base_dir()+"config.cfg"
var config = ConfigFile.new()
var load_response = config.load(save_path)

# Called when the node enters the scene tree for the first time.
func _ready():
	update_config()
	$Version.text = "Version: " + String(version)
	OS.window_fullscreen = config.get_value("Settings", "fullscreen", true)
	var openTimes = config.get_value("Main", "openTimes", 0)
	openTimes += 1
	config.set_value("Main", "openTimes", openTimes)
	config.save(save_path)
	var feedbackPressed = config.get_value("Main", "feedbackPressed", false)
	if openTimes > 3 and not feedbackPressed:
		$FeedBack.popup()
	update_MainMenuMusic()
	pass # Replace with function body.


func update_MainMenuMusic():
	if config.get_value("Settings", "mainMenuMusic", true):
		$MusicPlayer.play()
	else:
		$MusicPlayer.stop()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	load_scene(delta)
	updateBottmLabels()
	

var foundTracks = []
var foundContentPacks = []
var foundTrains = []

var currentTrack = ""
var currentTrain = ""
var currentScenario = ""

func _on_Quit_pressed():
	get_tree().quit()


func updateBottmLabels():
	$Label_Music.visible = $Front.visible and config.get_value("Settings", "mainMenuMusic", true)
	$Version.visible = $Front.visible

func _on_BackPlay_pressed():
	$Play.hide()
	$MenuBackground.hide()
	$Feedback.show()
	$Front.show()
	$Version.show()

	


func _on_PlayFront_pressed():
	update_track_list()
	$Play.show()
	$MenuBackground.show()
	$Feedback.hide()
	$Front.hide()
	$Version.hide()

func _on_Content_pressed():
	update_content()
	$Front.hide()
	$MenuBackground.show()
	$Content.show()

func _on_SettingsFront_pressed():
	$Front.hide()
	$MenuBackground.show()
	$Settings.show()

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
			
	## Get all Tracks:
	var foundFiles = {"Array": []}
	crawlDirectory("res://Worlds",foundFiles,"tscn")
	print(foundFiles)
	foundTracks = foundFiles["Array"].duplicate(true)
	
	## Get all Trains
	foundFiles = {"Array": []}
	crawlDirectory("res://Trains",foundFiles,"tscn")
	foundTrains = foundFiles["Array"].duplicate(true)
	

func update_track_list():
	$Play/Selection/Tracks/ItemList.clear()
	for track in foundTracks:
		$Play/Selection/Tracks/ItemList.add_item(track.get_file().get_basename())
		
func update_train_list():
	$Play/Selection/Trains/ItemList.clear()
	for train in foundTrains:
		$Play/Selection/Trains/ItemList.add_item(train.get_file().get_basename())
	

# Play Page:
func _on_PlayPlay_pressed():
	if currentScenario == "" or currentTrack == "" or currentTrain == "": return
	var index = $Play/Selection/Tracks/ItemList.get_selected_items()[0]
	Root.currentScenario = currentScenario
	Root.currentTrain = currentTrain
	Root.EasyMode = $Play/Info/Info/EasyMode.pressed
	$MenuBackground.hide()
	$Play.hide()
	$Loading.show()
	## Load Texture
	var save_path = foundTracks[index].get_basename() + "-scenarios.cfg"
	var config = ConfigFile.new()
	var load_response = config.load(save_path)
	var wData = config.get_value("WorldConfig", "Data", null)
	$Background.texture = load(wData["ThumbnailPath"])
	loadScenePath = foundTracks[index]

var loadScenePath = ""
var load_scene_timer = 0
func load_scene(delta):
	if loadScenePath != "":
		load_scene_timer += delta
		if load_scene_timer > 0.2:
			get_tree().change_scene(loadScenePath)

func _on_ItemList_itemTracks_selected(index):
	currentTrack = foundTracks[index]
	currentScenario = ""
	var save_path = foundTracks[index].get_basename() + "-scenarios.cfg"
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
	$Play/Selection/Trains.hide()
	$Play/Info/Info/EasyMode.hide()
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


func _on_ItemList_scenario_selected(index):
	currentScenario = $Play/Selection/Scenarios/ItemList.get_item_text(index)
	var save_path = foundTracks[$Play/Selection/Tracks/ItemList.get_selected_items()[0]].get_basename() + "-scenarios.cfg"
	var config = ConfigFile.new()
	var load_response = config.load(save_path)
	var sData = config.get_value("Scenarios", "sData", {})
	$Play/Info/Description.text = sData[currentScenario]["Description"]
	$Play/Info/Info/Duration.text = "Duration: " + String(sData[currentScenario]["Duration"]) + " min"
	$Play/Selection/Trains.show()
	$Play/Info/Info/EasyMode.hide()
	update_train_list()
	
	
func crawlDirectory(directoryPath,foundFiles,fileExtension):
	var dir = Directory.new()
	if dir.open(directoryPath) != OK: return
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "": break
		if file.begins_with("."): continue
		if dir.current_is_dir():
			crawlDirectory(directoryPath+"/"+file, foundFiles, fileExtension)
		else:
			if file.get_extension() == "tscn":
				foundFiles["Array"].append(directoryPath +"/"+file)
	dir.list_dir_end()


func _on_ItemList_Train_selected(index):
	currentTrain = foundTrains[index]
	var train = load(currentTrain).instance()
	currentTrain = foundTrains[index]
	print("Current Train: "+currentTrain)
	$Play/Info/Description.text = train.description
	$Play/Info/Info/ReleaseDate.text = "Release Date: "+ train.releaseDate
	$Play/Info/Info/Author.text = "Author: "+ train.author
	$Play/Info/Screenshot.texture = load(train.screenshotPath)#
	var electric = "yes"
	if not train.electric:
		electric = "no"
	$Play/Info/Info/Duration.text = "Electric: " + electric
	$Play/Info/Info/EasyMode.show()
	train.queue_free()
	


func _on_ButtonFeedback_pressed():
	config.set_value("Main", "feedbackPressed", true)
	config.save(save_path)
	OS.shell_open("https://libre-trainsim.de/feedback")
	


func _on_OpenWebBrowser_pressed():
	_on_ButtonFeedback_pressed()
	$FeedBack.hide()


func _on_Later_pressed():
	$FeedBack.hide()
















func _on_FrontCreate_pressed():
	OS.shell_open("https://github.com/Jean28518/Libre-TrainSim/wiki/Building-Tracks-for-Libre-TrainSim---Official-Documentation")
