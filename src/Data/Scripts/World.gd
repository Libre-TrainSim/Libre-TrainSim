class_name LTSWorld  # you can probably never use this, because it just causes cyclic dependency :^)
extends Spatial

var timeMSeconds: float = 0 # Just used for counting every second
var time: int = 0 # Unit: seconds (from 00:00:00)

var default_persons_at_station: int = 20

var globalDict := {} ## Used, if some nodes need to communicate globally. Modders could use it. Please make sure, that you pick an unique key_name

var currentScenario := ""

export (String) var FileName := "Name Me!"
onready var trackName: String = FileName.rsplit("/")[0]

var author: String = ""
var picturePath: String = "res://screenshot.png"
var description: String = ""

var pending_train_spawns := []

var player: LTSPlayer

var personVisualInstances := [
	preload("res://Resources/Persons/Man_Young_01.tscn"),
	preload("res://Resources/Persons/Man_Middleaged_01.tscn"),
	preload("res://Resources/Persons/Woman_Young_01.tscn"),
	preload("res://Resources/Persons/Woman_Middleaged_01.tscn"),
	preload("res://Resources/Persons/Woman_Old_01.tscn")
]

var chunk_manager: ChunkManager = null

var route_manager = RouteManager.new()
var j_save_module = jSaveModule.new()
var scenario_manager = ScenarioManager.new()



# If the World is just use as data source (e.g. for scenario editor)
var passive := false

func _ready() -> void:
	passive = Root.scenario_editor

	if passive:
		return

	chunk_manager = ChunkManager.new()
	chunk_manager.world = self
	chunk_manager.name = "ChunkManager"
	add_child(chunk_manager)

	# backward compat
	if has_node("Grass"):
		$Grass.queue_free()

	if trackName == "":
		trackName = FileName

	Logger.log("trackName: " +trackName + " " + FileName)

	if Root.Editor:
		j_save_module.set_save_path(find_parent("Editor").current_track_path + ".save")
	else:
		var save_path: String = Root.current_track.get_base_dir() + "/" + Root.current_track.get_file().get_basename() + ".save"
		j_save_module.set_save_path(save_path)

	if Root.Editor:
		$WorldEnvironment.environment.fog_enabled = jSettings.get_fog()
		$DirectionalLight.shadow_enabled = jSettings.get_shadows()
		return

	Root.world = self
	Root.checkAndLoadTranslationsForTrack(trackName)
	currentScenario = Root.current_scenario
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
	return j_save_module.save_value(key, value)


func get_value(key: String,  default_value = null):
	return j_save_module.get_value(key,  default_value)


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
		check_train_spawn(delta)


func advance_time(delta: float) -> void:
	timeMSeconds += delta
	if timeMSeconds > 1:
		timeMSeconds -= 1
		time += 1
	else:
		return


func get_signal_scenario_data() -> Dictionary:
	var signals := {}
	for s in $Signals.get_children():
		signals[s.name] = s.get_scenario_data()
	return signals


var train_spawn_information: Dictionary = {
	time = 0,
	player_train = false,
	train_path = "",
	route_name = "",
	minimal_platform_length = 0,
	route = [],
	station_table = [],
	despawn_information = {}
}


func set_scenario_to_world() -> void:
	scenario_manager.set_save_path(Root.current_scenario)

	# Apply General Settins
	time = Root.selected_time

	# Apply Signal Data
	var rail_logic_data: Dictionary = scenario_manager.get_rail_logic_settings()
	for signal_node in $Signals.get_children():
		if rail_logic_data.has(signal_node.name):
			signal_node.set_data(rail_logic_data[signal_node.name])

	# Apply all other routes
	var routes: Dictionary = scenario_manager.get_route_data()
	for i in range (routes.size()):
		var route_name: String = routes.keys()[i]
		var route: Dictionary = routes[route_name]
		# If this is a npc route, and this route should not be loaded for the current selected route, skip
		if not route.general_settings.player_can_drive_this_route and \
		route.general_settings.activate_only_at_specific_routes and \
		not route.general_settings.specific_routes.has(Root.selected_route):
			continue
		route_manager.set_route_data(route.route_points)
		var train_path: String = ContentLoader.find_train_path(route.general_settings.train_name)
		if train_path == "":
			train_path = Root.selected_train
		var minimal_platform_length: int = route_manager.get_minimal_platform_length(self)
		var train_rail_route: Array  = route_manager.get_calculated_rail_route(self)
		var train_station_table: Array = route_manager.get_calculated_station_points(Root.selected_time)
		var despawn_information: Dictionary = route_manager.get_despawn_information()
		var available_times: Array = scenario_manager.get_available_start_times_of_route(route_name)
		for available_time in available_times:
			# If the spawn time was before our start time, or the start time is above 2.5 hours
			if available_time < time or available_time - time > (3600*2.5):
				continue
			var pending_train_spawn: Dictionary = train_spawn_information.duplicate(true)
			pending_train_spawn.time = available_time
			pending_train_spawn.train_path = train_path
			# Player Train:
			if available_time == time and Root.selected_route == route_name:
				pending_train_spawn.player_train = true
				pending_train_spawn.train_path = Root.selected_train
			pending_train_spawn.route_name = route_name
			pending_train_spawn.minimal_platform_length = minimal_platform_length
			pending_train_spawn.route = train_rail_route
			pending_train_spawn.station_table = train_station_table
			pending_train_spawn.despawn_information = despawn_information
			pending_train_spawns.append(pending_train_spawn)

	check_train_spawn(1)

	jEssentials.call_delayed(1, $Players/Player, "show_textbox_message", [tr(routes[Root.selected_route].general_settings.description)])


func spawn_train(train_spawn_information: Dictionary) -> void:
	var new_train: Node = load(train_spawn_information.train_path).instance()
	if train_spawn_information.player_train:
		new_train.name = "Player"
		player = new_train
	else:
		Root.name_node_appropriate(new_train, train_spawn_information.route_name + "_npc", $Players)
		new_train.ai = true

	$Players.add_child(new_train)
	new_train.add_to_group("Player")
	new_train.owner = self
	if new_train.length + 25 > train_spawn_information.minimal_platform_length:
		new_train.length = train_spawn_information.minimal_platform_length - 25
	new_train.route_information = train_spawn_information.route
	route_manager.set_route_data(scenario_manager.get_route_data()[train_spawn_information.route_name].route_points)
	route_manager.calculated_rail_route = train_spawn_information.route
	new_train.spawn_information = route_manager.get_spawn_position(new_train.length, self)
	new_train.despawn_information = train_spawn_information.despawn_information
	new_train.station_table = train_spawn_information.station_table


	new_train.ready()

var _check_train_spawn_timer: float = 0
func check_train_spawn(delta: float) -> void:
	_check_train_spawn_timer += delta
	if _check_train_spawn_timer < 0.5:
		return
	_check_train_spawn_timer = 0
	for pending_train_spawn in pending_train_spawns:
		if pending_train_spawn.time <= time:
			spawn_train(pending_train_spawn)
			pending_train_spawns.erase(pending_train_spawn)


func update_rail_connections() -> void:
	for rail_node in $Rails.get_children():
		rail_node.update_positions_and_rotations()
	for rail_node in $Rails.get_children():
		rail_node.update_connections()


# Ensure you called update_rail_connections() before.
# pathfinding from a start rail to an end rail. returns an array of dicts with rail nodes and direction
func get_path_from_to(start_rail: Node, forward: bool, destination_rail: Node) -> Array:
	var route = _get_path_from_to_helper(start_rail, forward, [], destination_rail)
	return route


# Recursive Function
func _get_path_from_to_helper(start_rail: Node, forward: bool, already_visited_rails: Array, destination_rail: Node) -> Array:
	already_visited_rails.append({
		rail = start_rail,
		forward = forward
		})
	if start_rail == destination_rail:
		return already_visited_rails
	else:
		var possbile_rails: Array
		if forward:
			possbile_rails = start_rail.get_connected_rails_at_ending()
		else:
			possbile_rails = start_rail.get_connected_rails_at_beginning()
		for rail_node in possbile_rails:
			if rail_node.get_connected_rails_at_ending().has(start_rail):
				forward = false
			if rail_node.get_connected_rails_at_beginning().has(start_rail):
				forward = true
			var loop_detected: bool = false
			for entry in already_visited_rails:
				if rail_node == entry.rail and forward == entry.forward:
					loop_detected = true
					break
			if not loop_detected:
				var outcome: Array = _get_path_from_to_helper(rail_node, forward, already_visited_rails, destination_rail)
				if outcome != []:
					return outcome
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
	j_save_module.load_everything_into_cache()


func jump_player_to_station(station_table_index: int) -> void:
	Logger.log("Jumping player to station " + player.station_table[station_table_index].station_name)
	var new_station_node: Spatial = get_signal(player.station_table[station_table_index].node_name)

	time = player.station_table[station_table_index].arrival_time

	# Delete npcs with are crossing rails with player route to station
	update_rail_connections()
	var route_player_to_station: Array = get_path_from_to(player.currentRail, player.forward, new_station_node.rail)
	for player_node in $Players.get_children():
		if player_node == player or not player_node.is_in_group("Player"):
			continue
		for entry in route_player_to_station:
			var rail: Node = entry.rail
			if player_node.baked_route.has(rail.name):
				player_node.despawn()
				continue
	player.jump_to_station(station_table_index)


func get_rail(rail_name: String) -> Node:
	return $Rails.get_node_or_null(rail_name)


func get_signal(signal_name: String) -> Node:
	return $Signals.get_node_or_null(signal_name)


func get_assigned_station_of_signal(signal_name : String) -> Node:
	for signal_node in $Signals.get_children():
		if signal_node.type == "Station" and signal_node.assigned_signal == signal_name:
			return signal_node
	return null

# Used from scenario editor, does update assigned signals from stations
func write_station_data(rail_logic_settings) -> void:
	for rail_logic_name in rail_logic_settings.keys():
		var rail_logic_node: Node = get_signal(rail_logic_name)
		if rail_logic_node == null:
			continue
		if rail_logic_node.type == "Station":
			var signal_one: Node = get_signal(rail_logic_node.assigned_signal)
			if rail_logic_settings[rail_logic_name].overwrite:
				rail_logic_node.assigned_signal = rail_logic_settings[rail_logic_name].assigned_signal
				rail_logic_node.personSystem = rail_logic_settings[rail_logic_name].enable_person_system
			var signal_two: Node = get_signal(rail_logic_node.assigned_signal)
			if signal_one != null:
				signal_one.update()
			if signal_two != null:
				signal_two.update()
