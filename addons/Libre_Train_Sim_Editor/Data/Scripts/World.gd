tool
extends Spatial

export (String) var FileName = "Name Me!"
export (int) var chunkSize = 1000

export (bool) var createChunksAndSaveWorld = false setget save_world

export (int) var  timeHour 
export (int)  var timeMinute
export (int) var timeSecond 
var timeMSeconds = 0
onready var time = [timeHour,timeMinute,timeSecond]


var save_path = "res://Worlds/" + FileName + ".cfg"
var config = ConfigFile.new()
var load_response = config.load(save_path)

var allChunks = config.get_value("Chunks", "allChunks", null)
var istChunks = []
var sollChunks = []

var activeChunk = string2Chunk("0,0")

var initProcessorTime = 0
var processorTime = 0
func _ready():
	if Engine.editor_hint:
		pass
		# Code to execute in editor.
	if not Engine.editor_hint:
		save_path = "res://Worlds/" + FileName + ".cfg"
		config = ConfigFile.new()
		load_response = config.load(save_path)
		if config.get_value("Chunks", chunk2String(activeChunk), null) == null:
			save_world(true)
		istChunks = allChunks.duplicate()
		configure_soll_chunks(activeChunk)

		apply_soll_chunks()
		processorTime = OS.get_ticks_msec() / 1000
		print("Processor Time 2: " + String(processorTime - initProcessorTime))
		print(load_response)
		var player = $Players/Player
		lastchunk = pos2Chunk(getOriginalPos_bchunk(player.translation))



	pass
	
func _process(delta):
	if not Engine.editor_hint:
		time(delta)
		handle_chunk()
		checkBigChunk()


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
	processorTime = OS.get_ticks_msec() / 1000
	print("Processor Time 2: " + String(processorTime - initProcessorTime))	
	var Rails = get_node("Rails").get_children()
	for rail in Rails:
		if compareChunks(pos2Chunk(rail.translation), position):
			chunk.Rails[rail.name] = {name = rail.name, transform = rail.transform, length = rail.length, radius = rail.radius, buildDistance = rail.buildDistance, railType = rail.railType }

	
	chunk.Buildings = {}
	var Buildings = get_node("Buildings").get_children()
	for building in Buildings:
		if compareChunks(pos2Chunk(building.translation), position):
			chunk.Buildings[building.name] = {name = building.name, transform = building.transform, mesh = building.mesh}

	chunk.Flora = {}
	var Flora = get_node("Flora").get_children()
	for forest in Flora:
		if compareChunks(pos2Chunk(forest.translation), position):
			chunk.Flora[forest.name] = {name = forest.name, transform = forest.transform, x = forest.x, z = forest.z, spacing = forest.spacing, randomLocation = forest.randomLocation, randomLocationFactor = forest.randomLocationFactor, randomRotation = forest.randomRotation, randomScale = forest.randomScale, randomScaleFactor = forest.randomScaleFactor, multimesh = forest.multimesh, material_override = forest.material_override}
	
#	chunk.TO = {}
#	var TO = get_node("TO").get_children()
#	for to in TO:
#		if compareChunks(pos2Chunk(to.translation), position):
#			chunk.TO[to.name] = to
	
	chunk.Signals = {}
	var Signals = get_node("Signals").get_children()
	for signalN in Signals:
		if compareChunks(pos2Chunk(signalN.translation), position):
			if signalN.type == "Signal":
				chunk.Signals[signalN.name] = {type = signalN.type, forward = signalN.forward, name = signalN.name, transform = signalN.transform, status = signalN.status, signalAfter=signalN.signalAfter, setPassAtH=signalN.setPassAtH, setPassAtM=signalN.setPassAtM, setPassAtS=signalN.setPassAtS, attachedRail=signalN.attachedRail, onRailPosition=signalN.onRailPosition, speed=signalN.speed, warnSpeed=signalN.warnSpeed }
			elif signalN.type == "Station":
				chunk.Signals[signalN.name] = {type = signalN.type, forward = signalN.forward, name = signalN.name, transform = signalN.transform, attachedRail=signalN.attachedRail, onRailPosition=signalN.onRailPosition, stationName=signalN.stationName, beginningStation=signalN.beginningStation, regularStop=signalN.regularStop, endStation=signalN.endStation, stationLength=signalN.stationLength, stopTime=signalN.stopTime, departureH=signalN.departureH, departureM=signalN.departureM, departureS=signalN.departureS}
			elif signalN.type == "Speed":
				chunk.Signals[signalN.name] = {type = signalN.type, forward = signalN.forward, name = signalN.name, transform = signalN.transform, attachedRail=signalN.attachedRail, onRailPosition=signalN.onRailPosition, speed=signalN.speed}
			elif signalN.type == "WarnSpeed":
				chunk.Signals[signalN.name] = {type = signalN.type, forward = signalN.forward, name = signalN.name, transform = signalN.transform, attachedRail=signalN.attachedRail, onRailPosition=signalN.onRailPosition, warnSpeed=signalN.warnSpeed}
	

	
	chunk.TrackObjects = {}
	var trackObjects = get_node("TrackObjects").get_children()
	for trackObject in trackObjects:
		if compareChunks(pos2Chunk(trackObject.translation), position):
			chunk.TrackObjects[trackObject.name] = {name = trackObject.name, transform = trackObject.transform, data = trackObject.get_data()}
	processorTime = OS.get_ticks_msec() / 1000
	print("Processor Time 3: " + String(processorTime - initProcessorTime))	
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
				rail.queue_free()
			else:
				print("Object not saved! I wont unload this for you...")
	
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
	
	var Signals = get_node("Signals").get_children()
	for signalN in Signals:
		if compareChunks(pos2Chunk(signalN.translation), position):
			if chunk.Signals.has(signalN.name):
				signalN.queue_free()
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
	
	
	
func load_chunk(position):
	
	print("Loading Chunk " + chunk2String(position))
	var chunk = config.get_value("Chunks", chunk2String(position), null)
	
	if chunk == null:
		print("Chunk "+chunk2String(position) + " not found in Save File. Chunk not loaded!")
		return
	## Rails:
	var railsNode = get_node("Rails")
	var Rails = chunk.Rails
	var railNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
	for rail in Rails:
		if railsNode.find_node(rail) == null:
			var railInstance = railNode.instance()
			railInstance.set_name(Rails[rail].name)
			railInstance.buildDistance = Rails[rail].buildDistance
			railInstance.length = Rails[rail].length
			railInstance.radius = Rails[rail].radius
			railInstance.transform = Rails[rail].transform
			railInstance.translation = getNewPos_bchunk(railInstance.translation)
			railInstance.railType = Rails[rail].railType
			railsNode.add_child(railInstance)
			railInstance.set_owner(self)
			print(rail)
		else:
			print("Node " + rail + " already loaded!") 
			
		
	
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
			
	## Signals:
	var signalsNode = get_node("Signals")
	var Signals = chunk.Signals
	var signalNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Signal.tscn")
	var stationNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Station.tscn")
	var speedNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SpeedLimit.tscn")
	var warnSpeedNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/WarnSpeedLimit.tscn")
	for signalN in Signals:
		if signalsNode.find_node(signalN) == null:
			if Signals[signalN].type == "Signal":
				var signalInstance = signalNode.instance()
				signalInstance.set_name(Signals[signalN].name)
				signalInstance.transform = Signals[signalN].transform
				signalInstance.translation = getNewPos_bchunk(signalInstance.translation)
				signalInstance.forward = Signals[signalN].forward
				signalInstance.status = Signals[signalN].status
				signalInstance.signalAfter = Signals[signalN].signalAfter
				signalInstance.setPassAtH = Signals[signalN].setPassAtH
				signalInstance.setPassAtM = Signals[signalN].setPassAtM
				signalInstance.setPassAtS = Signals[signalN].setPassAtS
				signalInstance.speed = Signals[signalN].speed
				signalInstance.warnSpeed = Signals[signalN].warnSpeed
				signalInstance.attachedRail = Signals[signalN].attachedRail
				signalInstance.onRailPosition = Signals[signalN].onRailPosition
				signalsNode.add_child(signalInstance)
				signalInstance.set_owner(self)
			if Signals[signalN].type == "Station":
				var signalInstance = stationNode.instance()
				signalInstance.set_name(Signals[signalN].name)
				signalInstance.transform = Signals[signalN].transform
				signalInstance.translation = getNewPos_bchunk(signalInstance.translation)
				signalInstance.forward = Signals[signalN].forward
				signalInstance.stationName = Signals[signalN].stationName
				signalInstance.beginningStation = Signals[signalN].beginningStation
				signalInstance.regularStop = Signals[signalN].regularStop
				signalInstance.endStation = Signals[signalN].endStation
				signalInstance.stationLength = Signals[signalN].stationLength
				signalInstance.stopTime = Signals[signalN].stopTime
				signalInstance.departureH = Signals[signalN].departureH
				signalInstance.departureM = Signals[signalN].departureM
				signalInstance.departureS = Signals[signalN].departureS
				signalInstance.attachedRail = Signals[signalN].attachedRail
				signalInstance.onRailPosition = Signals[signalN].onRailPosition
				signalsNode.add_child(signalInstance)
				signalInstance.set_owner(self)
			if Signals[signalN].type == "Speed":
				var signalInstance = speedNode.instance()
				signalInstance.set_name(Signals[signalN].name)
				signalInstance.transform = Signals[signalN].transform
				signalInstance.translation = getNewPos_bchunk(signalInstance.translation)
				signalInstance.forward = Signals[signalN].forward
				signalInstance.speed = Signals[signalN].speed
				signalInstance.attachedRail = Signals[signalN].attachedRail
				signalInstance.onRailPosition = Signals[signalN].onRailPosition
				signalsNode.add_child(signalInstance)
				signalInstance.set_owner(self)
			if Signals[signalN].type == "WarnSpeed":
				var signalInstance = warnSpeedNode.instance()
				signalInstance.set_name(Signals[signalN].name)
				signalInstance.transform = Signals[signalN].transform
				signalInstance.translation = getNewPos_bchunk(signalInstance.translation)
				signalInstance.forward = Signals[signalN].forward
				signalInstance.warnSpeed = Signals[signalN].warnSpeed
				signalInstance.attachedRail = Signals[signalN].attachedRail
				signalInstance.onRailPosition = Signals[signalN].onRailPosition
				signalsNode.add_child(signalInstance)
				signalInstance.set_owner(self)
		else:
			print("Node " + signalN + " already loaded!") 
			
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
	save_path = "res://Worlds/" + FileName + ".cfg"
	config = ConfigFile.new()
	load_response = config.load(save_path)
	
	initProcessorTime = OS.get_ticks_msec() / 1000
	allChunks = []
	## Get all chunks of the world
	var railNode = get_node("Rails")
	if railNode == null:
		print("Rail Node not found. World not saved!")
		return
	for rail in railNode.get_children():
		processorTime = OS.get_ticks_msec() / 1000
		print("Processor Time 1: " + String(processorTime - initProcessorTime))	
		var railChunk = pos2Chunk(rail.translation)
		allChunks = add_single_to_array(allChunks, chunk2String(railChunk))
		processorTime = OS.get_ticks_msec() / 1000
		print("Processor Time 10: " + String(processorTime - initProcessorTime))	
		for chunk in getChunkeighbours(railChunk):
			allChunks = add_single_to_array(allChunks, chunk2String(chunk))
	
	for chunk in allChunks:
		save_chunk(string2Chunk(chunk))
	

	config.save(save_path)
	print("Saved the whole world. Chunks set correctly.")


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
		




