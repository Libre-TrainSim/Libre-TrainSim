class_name LTSWorld  # you can probably never use this, because it just causes cyclic dependency :^)
extends Spatial

var timeHour: int # Wont't be updated during game. Use time instead.
var timeMinute: int # Wont't be updated during game. Use time instead.
var timeSecond: int  # Wont't be updated during game. Use time instead.
var timeMSeconds: float = 0
onready var time := [timeHour,timeMinute,timeSecond]

var default_persons_at_station: int = 20

var globalDict: Dictionary = {} ## Used, if some nodes need to communicate globally. Modders could use it. Please make sure, that you pick an unique key_name

################################################################################
var currentScenario: String = ""

export (String) var FileName: String = "Name Me!"
onready var trackName: String = FileName.rsplit("/")[0]

var author: String = ""
var picturePath: String = "res://screenshot.png"
var description: String = ""

var pendingTrains: Dictionary = {"TrainName" : [], "SpawnTime" : []}

var player: LTSPlayer

var personVisualInstances: Array = [
	preload("res://Resources/Persons/Man_Young_01.tscn"),
	preload("res://Resources/Persons/Man_Middleaged_01.tscn"),
	preload("res://Resources/Persons/Woman_Young_01.tscn"),
	preload("res://Resources/Persons/Woman_Middleaged_01.tscn"),
	preload("res://Resources/Persons/Woman_Old_01.tscn")
]

var chunk_manager: ChunkManager = null

func _ready() -> void:
	chunk_manager = ChunkManager.new()
	chunk_manager.world = self
	add_child(chunk_manager)

	# backward compat
	if has_node("Grass"):
		$Grass.queue_free()

	if trackName == "":
		trackName = FileName

	Logger.log("trackName: " +trackName + " " + FileName)

	if Root.Editor:
		$jSaveModule.set_save_path(find_parent("Editor").current_track_path + ".save")
	else:
		var save_path = Root.currentTrack.get_base_dir() + "/" + Root.currentTrack.get_file().get_basename() + ".save"
		$jSaveModule.set_save_path(save_path)

	if Root.Editor:
		$WorldEnvironment.environment.fog_enabled = jSettings.get_fog()
		$DirectionalLight.shadow_enabled = jSettings.get_shadows()
		return

	Root.world = self
	Root.checkAndLoadTranslationsForTrack(trackName)
	currentScenario = Root.currentScenario
	set_scenario_to_world()

	jEssentials.call_delayed(1.0, self, "load_configs_to_cache")

	## Create Persons-Node:
	var personsNode := Spatial.new()
	personsNode.name = "Persons"
	add_child(personsNode)
	personsNode.owner = self

	for signalN in $Signals.get_children():
		if signalN.type == "Station":
			signalN.personsNode = personsNode
			signalN.spawnPersonsAtBeginning()

	player = $Players/Player
	apply_user_settings()


func save_value(key: String, value):
	return $jSaveModule.save_value(key, value)


func get_value(key: String,  default_value = null):
	return $jSaveModule.get_value(key,  default_value)


func apply_user_settings() -> void:
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


func _process(delta: float) -> void:
	if not Root.Editor:
		advance_time(delta)
		checkTrainSpawn(delta)


func advance_time(delta: float) -> void:
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


func apply_scenario_to_signals(signals: Dictionary) -> void:
	## Apply Scenario Data
	for signalN in $Signals.get_children():
		if signals.has(signalN.name):
			signalN.set_scenario_data(signals[signalN.name] if signals[signalN.name] != null else {})


func get_signal_scenario_data() -> Dictionary:
	var signals := {}
	for s in $Signals.get_children():
		signals[s.name] = s.get_scenario_data()
	return signals


func set_scenario_to_world() -> void:
	var Ssave_path: String = Root.currentTrack.get_base_dir() + "/" + Root.currentTrack.get_file().get_basename() + "-scenarios.cfg"
	$jSaveModuleScenarios.set_save_path(Ssave_path)
	var sData: Dictionary = $jSaveModuleScenarios.get_value("scenario_data")
	var scenario: Dictionary = sData[currentScenario]
	# set world Time:
	timeHour = scenario["TimeH"]
	timeMinute = scenario["TimeM"]
	timeSecond = scenario["TimeS"]
	time = [timeHour,timeMinute,timeSecond]

	apply_scenario_to_signals(scenario["Signals"])

	## SPAWN TRAINS:
	for train in scenario["Trains"].keys():
		spawnTrain(train)

	jEssentials.call_delayed(1, $Players/Player, "show_textbox_message", [TranslationServer.translate(scenario["Description"])])
#	$Players/Player.show_textbox_message(TranslationServer.translate(scenario["Description"]))


func spawnTrain(trainName: String) -> void:
	if $Players.has_node(trainName):
		Logger.err("Train is already loaded! - Aborted loading...", trainName)
		return
	var sData: Dictionary = $jSaveModuleScenarios.get_value("scenario_data")
	var scenario: Dictionary = sData[currentScenario]
	var spawnTime: Array = scenario["Trains"][trainName]["SpawnTime"]
	if scenario["Trains"][trainName]["SpawnTime"][0] != -1 and not (spawnTime[0] == time[0] and spawnTime[1] == time[1] and spawnTime[2] == time[2]):
		Logger.log("Spawn Time of "+trainName + " not reached, spawning later...")
		pendingTrains["TrainName"].append(trainName)
		pendingTrains["SpawnTime"].append(scenario["Trains"][trainName]["SpawnTime"].duplicate())
		return
	# Find preferred train:
	var new_player: Node
	var preferredTrain: String = scenario["Trains"][trainName].get("PreferredTrain", "")
	if (preferredTrain == "" and not trainName == "Player") or trainName == "Player":
		if not trainName == "Player":
			Logger.warn("no preferred train specified. Loading player train...", self)
		new_player = load(Root.currentTrain).instance()
	else:
		for train_path in ContentLoader.repo.trains:
			Logger.vlog(train_path)
			Logger.log(preferredTrain)
			if train_path.get_file() == preferredTrain:
				new_player = load(train_path).instance()
		if new_player == null:
			Logger.warn("Preferred train not found. Loading player train...", preferredTrain)
			new_player = load(Root.currentTrain).instance()

	new_player.name = trainName
	$Players.add_child(new_player)
	new_player.add_to_group("Player")
	new_player.owner = self
	if new_player.length  +25 > scenario["TrainLength"]:
		new_player.length = scenario["TrainLength"] -25
	new_player.route = scenario["Trains"][trainName]["Route"]
	new_player.startRail = scenario["Trains"][trainName]["StartRail"]
	new_player.forward = bool(scenario["Trains"][trainName]["Direction"])
	new_player.startPosition = scenario["Trains"][trainName]["StartRailPosition"]
	new_player.stations = scenario["Trains"][trainName]["Stations"]
	new_player.stations["passed"] = []
	for _i in range(new_player.stations["nodeName"].size()):
		new_player.stations["passed"].append(false)
	new_player.despawnRail = scenario["Trains"][trainName]["DespawnRail"]
	new_player.ai = trainName != "Player"
	new_player.initialSpeed = Math.kmHToSpeed(scenario["Trains"][trainName].get("InitialSpeed", 0))
	if scenario["Trains"][trainName].get("InitialSpeedLimit", -1) != -1:
		new_player.currentSpeedLimit = scenario["Trains"][trainName].get("InitialSpeedLimit", -1)

	var doorStatus: int = scenario["Trains"][trainName]["DoorConfiguration"]
	match doorStatus:
		0:
			pass
		1:
			new_player.doorLeft = true
		2:
			new_player.doorRight = true
		3:
			new_player.doorLeft = true
			new_player.doorRight = true
	new_player.ready()


var checkTrainSpawnTimer: float = 0
func checkTrainSpawn(delta: float) -> void:
	checkTrainSpawnTimer += delta
	if checkTrainSpawnTimer < 0.5:
		return
	checkTrainSpawnTimer = 0
	for i in range (0, pendingTrains["TrainName"].size()):
		var spawnTime: Array =  pendingTrains["SpawnTime"][i]
		if spawnTime[0] == time[0] and spawnTime[1] == time[1] and spawnTime[2] == time[2]:
			pendingTrains["SpawnTime"][i] = [-1, 0, 0]
			spawnTrain(pendingTrains["TrainName"][i])


func update_rail_connections() -> void:
	for rail_node in $Rails.get_children():
		rail_node.update_positions_and_rotations()
	for rail_node in $Rails.get_children():
		rail_node.update_connections()


# Ensure you called update_rail_connections() before.
# pathfinding from a start rail to an end rail. returns an array of rail nodes
func get_path_from_to(start_rail: Node, forward: bool, destination_rail: Node) -> Array:
	if Engine.editor_hint:
		update_rail_connections()
	else:
		Logger.warn("Be sure you called update_rail_connections once before..", self)
	var route = _get_path_from_to_helper(start_rail, forward, [], destination_rail)
	Logger.vlog(str(route))
	return route


# Recursive Function
func _get_path_from_to_helper(start_rail: Node, forward: bool, already_visited_rails: Array, destination_rail: Node) -> Array:
	already_visited_rails.append(start_rail)
	Logger.vlog(already_visited_rails)
	if start_rail == destination_rail:
		return already_visited_rails
	else:
		var possbile_rails: Array
		if forward:
			possbile_rails = start_rail.get_connected_rails_at_ending()
		else:
			possbile_rails = start_rail.get_connected_rails_at_beginning()
		for rail_node in possbile_rails:
			Logger.vlog("Possible Rails" + String(possbile_rails))
			if not already_visited_rails.has(rail_node):
				if rail_node.get_connected_rails_at_ending().has(start_rail):
					forward = false
				if rail_node.get_connected_rails_at_beginning().has(start_rail):
					forward = true
				var outcome: Array = _get_path_from_to_helper(rail_node, forward, already_visited_rails, destination_rail)
				if outcome != []:
					return outcome
#				return _get_path_from_to_helper(rail_node, forward, already_visited_rails, destination_rail)
	return []


# Not called automaticly. From any instance or button, but very helpful.
func update_all_rails_overhead_line_setting(overhead_line: bool) -> void:
	for rail in $Rails.get_children():
		rail.overheadLine = overhead_line
		rail.updateOverheadLine()


## Should be later used if we have a real heightmap
func get_terrain_height_at(_position: Vector2) -> float:
	return 0.0


func load_configs_to_cache() -> void:
	$jSaveModule.load_everything_into_cache()
	$jSaveModuleScenarios.load_everything_into_cache()


func jump_player_to_station(station_table_index: int) -> void:
	Logger.log("Jumping player to station " + player.stations["stationName"][station_table_index])
	var new_station_node: Spatial = $Signals.get_node(player.stations["nodeName"][station_table_index])

	time = player.stations["arrivalTime"][station_table_index].duplicate()

	# Delete npcs with are crossing rails with player route to station
	update_rail_connections()
	var route_player_to_station: Array = get_path_from_to(player.currentRail, player.forward, new_station_node.rail)
	for player_node in $Players.get_children():
		if player_node == player or not player_node.is_in_group("Player"):
			continue
		for rail in route_player_to_station:
			if player_node.baked_route.has(rail):
				player_node.despawn()
				continue
	player.jump_to_station(station_table_index)


func get_rail(rail_name: String) -> Node:
	return $Rails.get_node_or_null(rail_name)


func get_signal(signal_name: String) -> Node:
	return $Signals.get_node_or_null(signal_name)
