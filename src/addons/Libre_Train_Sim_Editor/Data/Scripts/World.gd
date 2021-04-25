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

var all_chunks = [] # All Chunks of the world
var istChunks = [] # All Current loaded Chunks
var sollChunks = [] # All Chunks, which should be loaded immediately

var activeChunk = string2Chunk("0,0") # Current Chunk of the player (ingame)


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


func _ready():
	jEssentials.call_delayed(2.0, self, "get_actual_loaded_chunks")
	if trackName == null:
		trackName = FileName
	print("trackName: " +trackName + " " + FileName)
	$jSaveModule.set_save_path(String("res://Worlds/" + trackName + "/" + trackName + ".save"))
	
	if Engine.editor_hint:
#		update_all_rails_overhead_line_setting(false)
		return

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
		
		all_chunks = get_all_chunks()
		
		istChunks = []
		configure_soll_chunks(activeChunk)

		apply_soll_chunks()

		player = $Players/Player
		lastchunk = pos2Chunk(getOriginalPos_bchunk(player.translation))
		
		apply_user_settings()


	pass
	
func save_value(key : String, value):
	return $jSaveModule.save_value(key, value)
	
func get_value(key : String,  default_value = null):
	return $jSaveModule.get_value(key,  default_value)

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
	return Vector3(int(position.x / chunkSize), 0, int(position.z / chunkSize))
	
func compareChunks(pos1, pos2):
	return (pos1.x == pos2.x && pos1.z == pos2.z)
	
func chunk2String(position : Vector3):
	return (String(position.x) + ","+String(position.z))
	
func string2Chunk(string : String):
	var array = string.split(",")
	return Vector3(int(array[0]), 0 , int(array[1]))

func getChunkeighbours(chunk):
	return [
		Vector3(chunk.x+1, 0, chunk.z+1), 
		Vector3(chunk.x+1, 0, chunk.z), 
		Vector3(chunk.x+1, 0, chunk.z-1), 
		Vector3(chunk.x, 0, chunk.z+1), 
		Vector3(chunk.x, 0, chunk.z-1), 
		Vector3(chunk.x-1, 0, chunk.z+1), 
		Vector3(chunk.x-1, 0, chunk.z), 
		Vector3(chunk.x-1, 0, chunk.z-1)
	]

func save_chunk(position):
	
	var chunk = {} #"position" : position, "Rails" : {}, "Buildings" : {}, "Flora" : {}}
	chunk.position = position
	chunk.Rails = {}
	var Rails = get_node("Rails").get_children()
	chunk.Rails = []
	for rail in Rails:
		if compareChunks(pos2Chunk(rail.translation), position):
			rail.update_is_switch_part()
			chunk.Rails.append(rail.name)

	
	chunk.Buildings = {}
	var Buildings = get_node("Buildings").get_children()
	for building in Buildings:
		if compareChunks(pos2Chunk(building.translation), position):
			var surfaceArr = []
			for i in range(building.get_surface_material_count()):
				surfaceArr.append(building.get_surface_material(i))
			chunk.Buildings[building.name] = {name = building.name, transform = building.transform, mesh_path = building.mesh.resource_path, surfaceArr = surfaceArr}

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
	$jSaveModule.save_value(chunk2String(position), null)
	$jSaveModule.save_value(chunk2String(position), chunk)
	print("Saved Chunk " + chunk2String(position))
	


func unload_chunk(position : Vector3):
	
	var chunk = $jSaveModule.get_value(chunk2String(position), null)
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
	
	var TrackObjects = get_node("TrackObjects").get_children()
	for node in TrackObjects:
		if compareChunks(pos2Chunk(node.translation), position):
			if chunk.TrackObjects.has(node.name):
				node.queue_free()
			else:
				print("Object not saved! I wont unload this for you...")
	
	print("Unloaded Chunk " + chunk2String(position))
	
	
	
func load_chunk(position : Vector3):
	

	
	
	print("Loading Chunk " + chunk2String(position))
	
	var chunk = $jSaveModule.get_value(chunk2String(position), {"empty" : true})

	if chunk.has("empty"):
		print("Chunk "+chunk2String(position) + " not found in Save File. Chunk not loaded!")
		return
	## Rails:
	var Rails = chunk.Rails
	for rail in Rails:
		print("Loading Rail: " + rail)
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
			meshInstance.set_mesh(load(Buildings[building].mesh_path))
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
	
	var unloaded_chunks = get_value("unloaded_chunks", [])
	unloaded_chunks.erase(chunk2String(position))
	save_value("unloaded_chunks", unloaded_chunks)
	
	print("Chunk " + chunk2String(position) + " loaded")
	pass

func get_all_chunks(): # Returns Array of Strings
	all_chunks = []
	var railNode = get_node("Rails")
	if railNode == null:
		printerr("Rail Node not found. World is corrupt!")
		return
	for rail in railNode.get_children():
		var railChunk = pos2Chunk(rail.translation)
		all_chunks = add_single_to_array(all_chunks, chunk2String(railChunk))

		for chunk in getChunkeighbours(railChunk):
			all_chunks = add_single_to_array(all_chunks, chunk2String(chunk))
	return all_chunks

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
	var currentChunk = pos2Chunk(getOriginalPos_bchunk(player.translation))
	if not compareChunks(currentChunk, lastchunk):
		activeChunk = currentChunk
		configure_soll_chunks(currentChunk)
		apply_soll_chunks()
	lastchunk = pos2Chunk(getOriginalPos_bchunk(player.translation))







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
			

func update_rail_connections():
	for rail_node in $Rails.get_children():
		rail_node.update_positions_and_rotations()
	for rail_node in $Rails.get_children():
		rail_node.update_connections()

# pathfinding from a start rail to an end rail. returns an array of rail nodes
func get_path_from_to(start_rail : Node, forward : bool, destination_rail : Node):
	if Engine.editor_hint:
		update_rail_connections()
	else:
		print_debug("Be sure you called update_rail_connections once before..")
	var route = _get_path_from_to_helper(start_rail, forward, [], destination_rail)
	print_debug(route)
	return route

# Recursive Function
func _get_path_from_to_helper(start_rail : Node, forward : bool, already_visited_rails : Array, destination_rail : Node):
	already_visited_rails.append(start_rail)
	print(already_visited_rails)
	if start_rail == destination_rail:
		return already_visited_rails
	else:
		var possbile_rails
		if forward:
			possbile_rails = start_rail.get_connected_rails_at_ending()
		else:
			possbile_rails = start_rail.get_connected_rails_at_beginning()
		for rail_node in possbile_rails:
			print("Possible Rails" + String(possbile_rails))
			if not already_visited_rails.has(rail_node):
				if rail_node.get_connected_rails_at_ending().has(start_rail):
					forward = false
				if rail_node.get_connected_rails_at_beginning().has(start_rail):
					forward = true
				var outcome = _get_path_from_to_helper(rail_node, forward, already_visited_rails, destination_rail)
				if outcome != []:
					return outcome
#				return _get_path_from_to_helper(rail_node, forward, already_visited_rails, destination_rail)
	return []

# Iterates through all currently loaded/visible rails, buildings, flora. Returns an array of chunks in strings
func get_actual_loaded_chunks():
	var actual_loaded_chunks = []
	for rail_node in $Rails.get_children():
		if rail_node.visible and not actual_loaded_chunks.has(chunk2String(pos2Chunk(rail_node.translation))): 
			actual_loaded_chunks.append(chunk2String(pos2Chunk(rail_node.translation)))
	for building_node in $Buildings.get_children():
		if building_node.visible and not actual_loaded_chunks.has(chunk2String(pos2Chunk(building_node.translation))): 
			actual_loaded_chunks.append(chunk2String(pos2Chunk(building_node.translation)))
	for flora_node in $Flora.get_children():
		if flora_node.visible and not actual_loaded_chunks.has(chunk2String(pos2Chunk(flora_node.translation))): 
			actual_loaded_chunks.append(chunk2String(pos2Chunk(flora_node.translation)))
	
	return actual_loaded_chunks

# loads all chunks (for Editor Use) (even if some chunks are loaded, and others not.)
func force_load_all_chunks():
	sollChunks = get_all_chunks()
	istChunks = []
	apply_soll_chunks()

# Accepts an array of chunks noted as strings
func save_chunks(chunks_to_save : Array):
	var current_unloaded_chunks = get_value("unloaded_chunks", []) # String
	for chunk_to_save in chunks_to_save:
		if current_unloaded_chunks.has(chunk_to_save): # If chunk is loaded but unloaded at the same time
			print("Chunk conflict: " + chunk_to_save + " is unloaded, but there are existing some currently loaded objects in this chunk! Trying to fix that...")
			load_chunk(string2Chunk(chunk_to_save))
			save_chunk(string2Chunk(chunk_to_save))
			continue
		save_chunk(string2Chunk(chunk_to_save))
	print("Saved chunks sucessfully.")
	
# Accepts an array of chunks noted as strings
func unload_and_save_chunks(chunks_to_unload : Array):
	save_chunks(chunks_to_unload)
	
	var current_unloaded_chunks = get_value("unloaded_chunks", []) # String
	for chunk_to_unload in chunks_to_unload:
		unload_chunk(string2Chunk(chunk_to_unload))
		current_unloaded_chunks.append(chunk_to_unload)
	current_unloaded_chunks = jEssentials.remove_duplicates(current_unloaded_chunks)
	save_value("unloaded_chunks", current_unloaded_chunks)
	print("Unloaded chunks sucessfully.")

# Accepts an array of chunks noted as strings
func load_chunks(chunks_to_load : Array):
	for chunk in chunks_to_load:
		load_chunk(string2Chunk(chunk))

func unload_and_save_all_chunks():
	unload_and_save_chunks(get_all_chunks())

func save_all_chunks():
	save_chunks(get_all_chunks())

# Returns all chunks in form of strings.
func get_chunks_between_rails(start_rail : String, destination_rail : String, include_neighbour_chunks : bool = false):
	var start_rail_node = $Rails.get_node_or_null(start_rail)
	var destination_rail_node = $Rails.get_node_or_null(destination_rail)
	if start_rail_node == null or destination_rail_node == null:
		print("Some Rails not found. Are the Names correct? Aborting...")
		return
	var rail_nodes = get_path_from_to(start_rail_node, true, destination_rail_node)
	if rail_nodes.empty():
		rail_nodes = get_path_from_to(start_rail_node, false, destination_rail_node)
	if rail_nodes.empty():
		print("Path between these rails could not be found. Are these rails reachable? Check the connections! Aborting...")
	
	var chunks = []
	for rail_node in rail_nodes:
		chunks.append(chunk2String(pos2Chunk(rail_node.translation)))
	chunks = jEssentials.remove_duplicates(chunks)
	if not include_neighbour_chunks:
		return chunks
	
	var chunks_with_neighbours = chunks.duplicate()
	for chunk in chunks:
		var chunks_neighbours = getChunkeighbours(string2Chunk(chunk))
		for chunk_neighbour in chunks_neighbours:
			chunks_with_neighbours.append(chunk2String(chunk_neighbour))
	chunks_with_neighbours = jEssentials.remove_duplicates(chunks_with_neighbours)
	return chunks_with_neighbours
	
func update_all_rails_overhead_line_setting(overhead_line : bool): # Not called automaticly. From any instance or button, but very helpful.
	for rail in $Rails.get_children():
		rail.overheadLine = overhead_line
		rail.updateOverheadLine()
	
