tool
extends Spatial

var timeHour 
var timeMinute
var timeSecond 
var timeMSeconds = 0
onready var time = [timeHour,timeMinute,timeSecond]

var default_persons_at_station = 20

var globalDict = {} ## Used, if some nodes need to communicate globally. Modders could use it. Please make sure, that you pick an unique key_name

################################################################################
var currentScenario = ""

export (String) var FileName = "Name Me!"
onready var trackName = FileName.rsplit("/")[0]
export var debug = false
var chunkSize = 1000

var createChunksAndSaveWorld = false setget save_world

var save_path
var config = ConfigFile.new()
var load_response

var allChunks = []
var istChunks = []
var sollChunks = []

var activeChunk = string2Chunk("0,0")


var author = ""
var picturePath = "res://screenshot.png"
var description = ""

var pendingTrains = {"TrainName" : [], "SpawnTime" : []}

var player

export var editorAllObjectsUnloaded = false ## saves, if all Objects in World where unloaded, or not. That's important for Saving and creating Chunks. It only works, if every Objet is loaded in the world.

var trainFiles = {"Array" : []}

var personVisualInstancesPathes = [
	"res://Resources/Basic/Persons/RedDummy.tscn"
]
var personVisualInstances = []


#var initProcessorTime = 0
#var processorTime = 0
func _ready():


	
	if trackName == null:
		trackName = FileName
	save_path = "res://Worlds/" + trackName + "/" + trackName + ".cfg"
	load_response = config.load(save_path)
	if Engine.editor_hint:
		return
		# Code to execute in editor.
	if not Engine.editor_hint:
		Root.world = self
		Root.checkAndLoadTranslationsForTrack(trackName)
		Root.crawlDirectory("res://Trains",trainFiles,"tscn")
		trainFiles = trainFiles["Array"]
		currentScenario = Root.currentScenario
		set_scenario_to_world()
		
		
		## Create Persons-Node:
		var personsNode = Spatial.new()
		personsNode.name = "Persons"
		personsNode.owner = self
		add_child(personsNode)
		
		for personVisualInstancesPath in personVisualInstancesPathes:
			personVisualInstances.append(load(personVisualInstancesPath))
			
		for signalN in $Signals.get_children():
			if signalN.type == "Station":
				signalN.personsNode = personsNode
				signalN.spawnPersonsAtBeginning()
				
				
				
				
		loadWorldConfig()
		if config.get_value("Chunks", chunk2String(activeChunk), null) == null:
			save_world(true)
		
		allChunks = config.get_value("Chunks", "allChunks", [])
		
		if editorAllObjectsUnloaded == true:
			istChunks = []
		else:
			istChunks = allChunks.duplicate()
		configure_soll_chunks(activeChunk)

		apply_soll_chunks()
#		processorTime = OS.get_ticks_msec() / 1000
#		print("Processor Time 2: " + String(processorTime - initProcessorTime))
		print(load_response)
		player = $Players/Player
		lastchunk = pos2Chunk(getOriginalPos_bchunk(player.translation))
		
		apply_user_settings()


	pass

func loadWorldConfig():
	save_path = "res://Worlds/" + trackName + "/" + trackName + ".cfg"
	config = ConfigFile.new()
	load_response = config.load(save_path)



func apply_user_settings():
	if Root.mobile_version:
		$DirectionalLight.shadow_enabled = false
		player.get_node("Camera").far = 400
		get_viewport().set_msaa(0)
		$WorldEnvironment.environment.fog_enabled = false
		return
	if get_node("DirectionalLight") != null:
		$DirectionalLight.shadow_enabled = jSettings.get_shadows()
	player.get_node("Camera").far = jSettings.get_view_distance()
	get_viewport().set_msaa(jSettings.get_anti_aliasing())
	$WorldEnvironment.environment.fog_enabled = jSettings.get_fog()
	
func _process(delta):
	if not Engine.editor_hint:
		time(delta)
		checkTrainSpawn(delta)
		handle_chunk()
		checkBigChunk()
	else:
		var buildings = get_node("Buildings")
		for child in get_children():
			if child.is_class("MeshInstance"):
				remove_child(child)
				buildings.add_child(child)
				child.owner = self



func time(delta):
	timeMSeconds += delta
	if timeMSeconds > 1:
		timeMSeconds -= 1
		time[2] += 1
	else:
		return
	if time[2] == 60:
		time[2] = 0
		time[1] += 1
	if time[1] == 60:
		time[1] = 0
		time[0] += 1
	if time[0] == 24:
		time[0] = 0




func pos2Chunk(position):
	return {x= int(position.x / chunkSize), z = int(position.z / chunkSize)}
	
func compareChunks(pos1, pos2):
	return (pos1.x == pos2.x && pos1.z == pos2.z)
	
func chunk2String(position):
	return (String(position.x) + ","+String(position.z))
	
func string2Chunk(string):
	var array = string.split(",")
	return Vector3(int(array[0]), 0 , int(array[1]))

func getChunkeighbours(chunk):
	return [{x = chunk.x+1, z = chunk.z+1}, {x= chunk.x+1, z = chunk.z}, {x= chunk.x+1, z = chunk.z-1}, {x= chunk.x, z = chunk.z+1}, {x = chunk.x, z = chunk.z-1}, {x = chunk.x-1, z = chunk.z+1}, {x = chunk.x-1, z = chunk.z}, {x = chunk.x-1, z = chunk.z-1}]

func save_chunk(position):
	
	var chunk = {} #"position" : position, "Rails" : {}, "Buildings" : {}, "Flora" : {}}
	chunk.position = position
	chunk.Rails = {}
#	processorTime = OS.get_ticks_msec() / 1000
#	print("Processor Time 2: " + String(processorTime - initProcessorTime))	
	var Rails = get_node("Rails").get_children()
	chunk.Rails = []
	for rail in Rails:
		if compareChunks(pos2Chunk(rail.translation), position):
			rail.checkForSwitch()
			chunk.Rails.append(rail.name)

	
	chunk.Buildings = {}
	var Buildings = get_node("Buildings").get_children()
	for building in Buildings:
		if compareChunks(pos2Chunk(building.translation), position):
			var surfaceArr = []
			for i in range(building.get_surface_material_count()):
				surfaceArr.append(building.get_surface_material(i))
			chunk.Buildings[building.name] = {name = building.name, transform = building.transform, mesh = building.mesh, surfaceArr = surfaceArr}

	chunk.Flora = {}
	var Flora = get_node("Flora").get_children()
	for forest in Flora:
		if compareChunks(pos2Chunk(forest.translation), position):
			chunk.Flora[forest.name] = {name = forest.name, transform = forest.transform, x = forest.x, z = forest.z, spacing = forest.spacing, randomLocation = forest.randomLocation, randomLocationFactor = forest.randomLocationFactor, randomRotation = forest.randomRotation, randomScale = forest.randomScale, randomScaleFactor = forest.randomScaleFactor, multimesh = forest.multimesh, material_override = forest.material_override}
	

	
	chunk.TrackObjects = {}
	var trackObjects = get_node("TrackObjects").get_children()
	for trackObject in trackObjects:

		if compareChunks(pos2Chunk(trackObject.translation), position):
			chunk.TrackObjects[trackObject.name] = {name = trackObject.name, transform = trackObject.transform, data = trackObject.get_data()}
#	processorTime = OS.get_ticks_msec() / 1000
#	print("Processor Time 3: " + String(processorTime - initProcessorTime))	
	config.set_value("Chunks", chunk2String(position), null)
	config.set_value("Chunks", chunk2String(position), chunk)
	print("Saved Chunk " + chunk2String(position))
	


func unload_chunk(position):
	
	var chunk = config.get_value("Chunks", chunk2String(position), null)
	if chunk == null:
		return
	var Rails = get_node("Rails").get_children()
	for rail in Rails:
		if compareChunks(pos2Chunk(rail.translation), position):
			if chunk.Rails.has(rail.name):
				rail.unload_visible_Instance()
	
	var Buildings = get_node("Buildings").get_children()
	for building in Buildings:
		if compareChunks(pos2Chunk(building.translation), position):
			if chunk.Buildings.has(building.name):
				building.queue_free()
			else:
				print("Object not saved! I wont unload this for you...")
	
	var Flora = get_node("Flora").get_children()
	for forest in Flora:
		if compareChunks(pos2Chunk(forest.translation), position):
			if chunk.Flora.has(forest.name):
				forest.queue_free()
			else:
				print("Object not saved! I wont unload this for you...")
	
#	var Signals = get_node("Signals").get_children()
#	for signalN in Signals:
#		if compareChunks(pos2Chunk(signalN.translation), position):
#			if chunk.Signals.has(signalN.name):
#				signalN.queue_free()
#			else:
#				print("Object not saved! I wont unload this for you...")
	
	var TrackObjects = get_node("TrackObjects").get_children()
	for node in TrackObjects:
		if compareChunks(pos2Chunk(node.translation), position):
			if chunk.TrackObjects.has(node.name):
				node.queue_free()
			else:
				print("Object not saved! I wont unload this for you...")
	
	print("Unloaded Chunk " + chunk2String(position))
	
	
	
func load_chunk(position):
	
	print("Loading Chunk " + chunk2String(position))
	var chunk = config.get_value("Chunks", chunk2String(position), null)
	
	if chunk == null:
		print("Chunk "+chunk2String(position) + " not found in Save File. Chunk not loaded!")
		return
	## Rails:
	var Rails = chunk.Rails
#	var railNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
	for rail in Rails:
		printerr("Loading Rail: " + rail)
		## IF YOU GET HERE AN ERROR: Do Save and Create Chunks, and check, if only Rails are assigned to the "Rails" Node
		if $Rails.get_node(rail) != null:  ##DEBUG
			$Rails.get_node(rail).load_visible_Instance()
		else:
			printerr("WARNING: Rail "+ rail+ " not found in scene tree, but was saved in chunk. That shouldn't be.")
		

	##buildings:
	var buildingsNode = get_node("Buildings")
	var Buildings = chunk.Buildings
	for building in Buildings:
		if buildingsNode.find_node(building) == null:
			var meshInstance = MeshInstance.new()
			meshInstance.name = Buildings[building].name
			meshInstance.mesh = Buildings[building].mesh
			meshInstance.transform = Buildings[building].transform
			meshInstance.translation = getNewPos_bchunk(meshInstance.translation)
			var surfaceArr = Buildings[building].surfaceArr
			if surfaceArr == null:
				surfaceArr = []
			print(surfaceArr)
			for i in range (surfaceArr.size()):
				meshInstance.set_surface_material(i, surfaceArr[i])
			buildingsNode.add_child(meshInstance)
			meshInstance.set_owner(self)
		else:
			print("Node " + building + " already loaded!") 
	
	
	##Flora:
	var floraNode = get_node("Flora")
	var Flora = chunk.Flora
	var forestNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Forest.tscn")
	for forest in Flora:#
		if floraNode.find_node(forest) == null:
			var forestInstance = forestNode.instance()
			forestInstance.name = Flora[forest].name
			forestInstance.multimesh = Flora[forest].multimesh
			forestInstance.randomLocation = Flora[forest].randomLocation
			forestInstance.randomLocationFactor = Flora[forest].randomLocationFactor
			forestInstance.randomRotation = Flora[forest].randomRotation
			forestInstance.randomScale = Flora[forest].randomScale
			forestInstance.randomScaleFactor = Flora[forest].randomScaleFactor
			forestInstance.spacing = Flora[forest].spacing
			forestInstance.transform = Flora[forest].transform
			forestInstance.translation = getNewPos_bchunk(forestInstance.translation)
			forestInstance.x = Flora[forest].x
			forestInstance.z = Flora[forest].z
			forestInstance.material_override = Flora[forest].material_override
			floraNode.add_child(forestInstance)
			forestInstance.set_owner(self)
			get_node("Flora/"+forest)._update(true)
		else:
			print("Node " + forest + " already loaded!") 
			
			
	##TrackObjects:
	var ParentNode = get_node("TrackObjects")
	var nodeArray = chunk.TrackObjects
	var nodeIInstance = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
	for node in nodeArray:
		if ParentNode.find_node(node) == null:
			var nodeI = nodeIInstance.instance()
			nodeI.name = nodeArray[node].name
			nodeI.set_data(nodeArray[node].data)
			nodeI.transform = nodeArray[node].transform
			nodeI.translation = getNewPos_bchunk(nodeI.translation)
			ParentNode.add_child(nodeI)
			nodeI.set_owner(self)
		else:
			print("Node " + node + " already loaded!") 
	
	print("Chunk " + chunk2String(position) + " loaded")
	pass


func save_world(newvar):
	if editorAllObjectsUnloaded:
		print("Saving World skipped. Load all Objects from configuration first!")
		return
	save_path = "res://Worlds/" + trackName + "/" + trackName + ".cfg"
	config = ConfigFile.new()
	load_response = config.load(save_path)

	get_allChunks()
	
	
	for chunk in allChunks:
		save_chunk(string2Chunk(chunk))
	

	config.save(save_path)
	print("Saved the whole world. Chunks set correctly.")

func get_allChunks():
	allChunks = []
	var railNode = get_node("Rails")
	if railNode == null:
		printerr("Rail Node not found. World is corrupt!")
		return
	for rail in railNode.get_children():
		var railChunk = pos2Chunk(rail.translation)
		allChunks = add_single_to_array(allChunks, chunk2String(railChunk))

		for chunk in getChunkeighbours(railChunk):
			allChunks = add_single_to_array(allChunks, chunk2String(chunk))

func add_single_to_array(array, value):
	if not array.has(value):
		array.append(value)
	return array
	

func configure_soll_chunks(chunk):
	sollChunks = []
	sollChunks.append(chunk2String(chunk))
	for a in getChunkeighbours(chunk):
		sollChunks.append(chunk2String(a))
	pass

func apply_soll_chunks():
	print("applying soll chunks...")
	print("istChunks: " + String(istChunks))
	print("sollChunks: " + String(sollChunks))
	var oldistChunks = istChunks.duplicate()
	for a in oldistChunks:
		if not sollChunks.has(a):
			unload_chunk(string2Chunk(a))
			istChunks.remove(istChunks.find(a))
	print("istChunks: " + String(istChunks))
	for a in sollChunks:
		if not istChunks.has(a):
			load_chunk(string2Chunk(a))
			istChunks.append(a)
			
var lastchunk
func handle_chunk():
	var player = $Players/Player
	#var world = get_parent().get_parent()
	var currentChunk = pos2Chunk(getOriginalPos_bchunk(player.translation))
	if not compareChunks(currentChunk, lastchunk):
		activeChunk = currentChunk
		configure_soll_chunks(currentChunk)
		apply_soll_chunks()
	lastchunk = pos2Chunk(getOriginalPos_bchunk(player.translation))

func editorUnloadAllChunks():
	editorAllObjectsUnloaded = true
	loadWorldConfig()
	get_allChunks()
	istChunks = allChunks.duplicate()
	sollChunks = []
	apply_soll_chunks()
	
func editorLoadAllChunks():
	editorAllObjectsUnloaded = false
	loadWorldConfig()
	get_allChunks()
	istChunks = []
	sollChunks = allChunks.duplicate()
	apply_soll_chunks()





## BIG CHUNK_SYSTEM: KEEPS THE WORLD under 5000

var currentbigchunk = Vector2(0,0)

func pos2bchunk(pos):
	return Vector2(int(pos.x/5000), int(pos.z/5000))+currentbigchunk
	
func getNewPos_bchunk(pos):
	return Vector3(pos.x-currentbigchunk.x*5000.0, pos.y, pos.z-currentbigchunk.y*5000.0)
	
func getOriginalPos_bchunk(pos):
	return Vector3(pos.x+currentbigchunk.x*5000.0, pos.y, pos.z+currentbigchunk.y*5000.0)
		
func checkBigChunk():
	var player = $Players/Player
	var newchunk = pos2bchunk(player.translation)

	if (newchunk != currentbigchunk):
		var deltaChunk = currentbigchunk - newchunk
		currentbigchunk = newchunk
		print (newchunk)
		print(currentbigchunk)
		print("Changed to new big Chunk. Changing Objects translation..")
		updateWorldTransform_bchunk(deltaChunk)
		


func updateWorldTransform_bchunk(deltachunk):
	var deltaTranslation = Vector3(deltachunk.x*5000, 0, deltachunk.y*5000)
	print(deltaTranslation)
	for player in $Players.get_children():
		player.translation += deltaTranslation
	for rail in $Rails.get_children():
		rail.translation += deltaTranslation
		rail._update(true)
	for signalN in $Signals.get_children():
		signalN.translation += deltaTranslation
	for building in $Buildings.get_children():
		building.translation += deltaTranslation
	for forest in $Flora.get_children():
		forest.translation += deltaTranslation
	for to in $TrackObjects.get_children():
		to.translation += deltaTranslation
	
		


func apply_scenario_to_signals(signals):
	## Apply Scenario Data
	for signalN in  $Signals.get_children():
		if signals.has(signalN.name):
			signalN.set_scenario_data(signals[signalN.name])
			
func get_signal_data_for_scenario():
	var signals = {}
	for s in $Signals.get_children():
		signals[s.name] = s.get_scenario_data()
	return signals
	
func set_scenario_to_world():
	var Ssave_path = "res://Worlds/" + trackName + "/" + trackName + "-scenarios.cfg"
	var sConfig = ConfigFile.new()
	var load_response = sConfig.load(Ssave_path)
	var sData = sConfig.get_value("Scenarios", "sData", {})
	var scenario = sData[currentScenario]
	# set world Time:
	timeHour = scenario["TimeH"]
	timeMinute = scenario["TimeM"]
	timeSecond = scenario["TimeS"]
	time = [timeHour,timeMinute,timeSecond]
	
	apply_scenario_to_signals(scenario["Signals"])
	
	## SPAWN TRAINS:
	for train in scenario["Trains"].keys():
		spawnTrain(train)
		
	$Players/Player.show_textbox_message(TranslationServer.translate(scenario["Description"]))



func spawnTrain(trainName):
	if $Players.has_node(trainName):
		print("Train is already loaded! - Abortet loading...")
		return
	var Ssave_path = "res://Worlds/" + trackName + "/" + trackName + "-scenarios.cfg"
	var sConfig = ConfigFile.new()
	var load_response = sConfig.load(Ssave_path)
	var sData = sConfig.get_value("Scenarios", "sData", {})
	var scenario = sData[currentScenario]
	var spawnTime = scenario["Trains"][trainName]["SpawnTime"]
	if scenario["Trains"][trainName]["SpawnTime"][0] != -1 and not (spawnTime[0] == time[0] and spawnTime[1] == time[1] and spawnTime[2] == time[2]):
		print("Spawn Time of "+trainName + " not reached, doing spawn later...")
		pendingTrains["TrainName"].append(trainName)
		pendingTrains["SpawnTime"].append(scenario["Trains"][trainName]["SpawnTime"].duplicate())
		return
	# Find preferred train:
	var player
	var preferredTrain = scenario["Trains"][trainName].get("PreferredTrain", "")
	if (preferredTrain == "" and not trainName == "Player") or trainName == "Player":
		if not trainName == "Player":
			print("no preferred train specified. Loading player train...")
		player = load(Root.currentTrain).instance()
	else:
		for trainFile in trainFiles:
			print(trainFile)
			print(preferredTrain)
			if trainFile.find(preferredTrain) != -1:
				player = load(trainFile).instance()
		if player == null:
			print("Preferred train not found. Loading player train...")
			player = load(Root.currentTrain).instance()
		
	player.name = trainName
	$Players.add_child(player)
	player.owner = self
	if player.length  +25 > scenario["TrainLength"]:
		player.length = scenario["TrainLength"] -25
	player.route = scenario["Trains"][trainName]["Route"]
	player.startRail = scenario["Trains"][trainName]["StartRail"]
	player.forward = bool(scenario["Trains"][trainName]["Direction"])
	player.startPosition = scenario["Trains"][trainName]["StartRailPosition"]
	player.stations = scenario["Trains"][trainName]["Stations"]
	player.stations["passed"] = []
	for i in range(player.stations["nodeName"].size()):
		player.stations["passed"].append(false)
	player.despawnRail = scenario["Trains"][trainName]["DespawnRail"]
	player.ai = trainName != "Player"
	player.initialSpeed = Math.kmHToSpeed(scenario["Trains"][trainName].get("InitialSpeed", 0))
	if scenario["Trains"][trainName].get("InitialSpeedLimit", -1) != -1:
		player.speedLimit = scenario["Trains"][trainName].get("InitialSpeedLimit", -1)
	
	if trainName == "Player":
		player.debug = debug
		
	
	var doorStatus = scenario["Trains"][trainName]["DoorConfiguration"]
	match doorStatus:
		0:
			pass
		1: 
			player.doorLeft = true
		2:
			player.doorRight = true
		3:
			player.doorLeft = true
			player.doorRight = true
	
	player.ready()
	

var checkTrainSpawnTimer = 0
func checkTrainSpawn(delta):
	checkTrainSpawnTimer += delta
	if checkTrainSpawnTimer < 0.5: return
	checkTrainSpawnTimer = 0
	for i in range (0, pendingTrains["TrainName"].size()):
		var spawnTime =  pendingTrains["SpawnTime"][i]
		if spawnTime[0] == time[0] and spawnTime[1] == time[1] and spawnTime[2] == time[2]:
			pendingTrains["SpawnTime"][i] = [-1, 0, 0]
			spawnTrain(pendingTrains["TrainName"][i])
			




