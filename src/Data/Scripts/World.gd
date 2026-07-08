class_name LTSWorld  # you can probably never use this, because it just causes cyclic dependency :^)
extends Spatial

const DAY_SECONDS := 24 * 60 * 60
const WEATHER_CLEAR := 0
const WEATHER_RAIN := 1
const WEATHER_SNOW := 2
const WEATHER_RADIUS := 85.0
const WEATHER_HEIGHT := 45.0

var timeMSeconds: float = 0 # Just used for counting every second
var time: int = 0 # Unit: seconds (from 00:00:00)

var default_persons_at_station: int = 20

var current_scenario: TrackScenario = null
var current_world_config: WorldConfig = null

export (String) var FileName := "Name Me!"
onready var trackName: String = FileName.rsplit("/")[0]

export var world_origin_on_last_save = Vector3(0,0,0) # Used for chunk manager.


var pending_train_spawns := []

var player: LTSPlayer

var _person_template: PackedScene = preload("res://Data/Modules/Person.tscn")
var _person_visual_instances := [
	preload("res://Resources/Persons/Man_Young_01.tscn"),
	preload("res://Resources/Persons/Man_Middleaged_01.tscn"),
	preload("res://Resources/Persons/Woman_Young_01.tscn"),
	preload("res://Resources/Persons/Woman_Middleaged_01.tscn"),
	preload("res://Resources/Persons/Woman_Old_01.tscn")
]

var chunk_manager: ChunkManager = null

var _scenario_start_time: int = 0
var _scenario_environment_prepared := false
var _last_environment_time := -1
var _weather_particles: Particles = null
var _weather_particle_mode := -1

# If the World is just use as data source (e.g. for scenario editor)
var passive := false

func _ready() -> void:
	passive = Root.scenario_editor
	if passive:
		return

	var world_config_path = Root.current_track.get_basename() + "_config.tres"
	current_world_config = load(world_config_path) as WorldConfig
	if not is_instance_valid(current_world_config):
		Logger.err("Could not load world config at %s" % world_config_path, self)
		return

	chunk_manager = ChunkManager.new()
	chunk_manager.world = self
	chunk_manager.name = "ChunkManager"
	chunk_manager.world_origin = world_origin_on_last_save
	add_child(chunk_manager)

	# backward compat
	if has_node("Grass"):
		$Grass.queue_free()

	if trackName == "":
		trackName = FileName

	Logger.log("trackName: " +trackName + " " + FileName)

	if Root.Editor:
		$WorldEnvironment.environment.fog_enabled = ProjectSettings["game/graphics/fog"]
		$DirectionalLight.shadow_enabled = ProjectSettings["game/graphics/shadows"]
		return

	Root.world = self
	Root.checkAndLoadTranslationsForTrack(trackName)
	set_scenario_to_world()

	## Create Persons-Node:
	var personsNode := Spatial.new()
	personsNode.name = "Persons"
	add_child(personsNode)
	personsNode.owner = self

	for signalN in $Signals.get_children():
		if signalN.type == "Station":
			signalN.spawn_persons_at_beginning()

	player = $Players/Player
	assert(player)
	_get_scenario_environment()
	apply_user_settings()
	_apply_scenario_environment(true)

	player.update_waiting_persons_on_next_station()


func get_new_person_instance() -> Person:
	randomize()
	var person: Person = _person_template.instance()
	var person_visual: PackedScene = _person_visual_instances[int(rand_range(0, _person_visual_instances.size()))]
	person.add_child(person_visual.instance())
	$Persons.add_child(person)
	return person


func apply_user_settings() -> void:
	if Root.mobile_version:
		$DirectionalLight.shadow_enabled = false
		player.get_node("Camera").far = 400
		get_viewport().set_msaa(0)
		$WorldEnvironment.environment.fog_enabled = false
		return
	if get_node("DirectionalLight") != null:
		$DirectionalLight.shadow_enabled = ProjectSettings["game/graphics/shadows"]
	player.get_node("Camera").far = ProjectSettings["game/gameplay/view_distance"]
	get_viewport().set_msaa(ProjectSettings["rendering/quality/filters/msaa"])
	$WorldEnvironment.environment.fog_enabled = ProjectSettings["game/graphics/fog"]


func _process(delta: float) -> void:
	if not Root.Editor:
		advance_time(delta)
		check_train_spawn(delta)
		_apply_scenario_environment()


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


func set_scenario_to_world() -> void:
	current_scenario = TrackScenario.load_scenario()
	assert(current_scenario != null)

	# Apply General Settings
	_scenario_start_time = Root.selected_time
	if _scenario_start_time < 0:
		_scenario_start_time = current_scenario.time
	time = _scenario_start_time

	# Apply Signal Data
	var rail_logic_data = current_scenario.rail_logic_settings
	for signal_node in $Signals.get_children():
		if rail_logic_data.has(signal_node.name):
			signal_node.set_data(rail_logic_data[signal_node.name])

	# Apply all other routes
	var routes = current_scenario.routes
	for i in range(routes.size()):
		var route_name: String = routes.keys()[i]
		var route: ScenarioRoute = routes[route_name]

		# If this is a npc route, and this route should not be loaded for the current selected route, skip
		if not route.is_playable and route.activate_only_at_specific_routes and not route.specific_routes.has(Root.selected_route):
			continue

		var train_path := Root.selected_train
		if train_path.empty():
			train_path = ContentLoader.find_train_path(route.train_name)

		var minimal_platform_length: int = route.get_minimal_platform_length(self)
		var train_rail_route: Array = route.get_calculated_rail_route(self)
		var train_station_table: Array = route.get_calculated_station_points(time)
		var despawn_point: RoutePoint = route.get_despawn_point()
		var available_times: Array = route.get_start_times()

		for available_time in available_times:
			# If the spawn time was before our start time, or the start time is above 2.5 hours
			if available_time < time or available_time - time > (3600*2.5):
				continue

			var pending_train_spawn = TrainSpawnInformation.new()
			# Player Train:
			if available_time == time and Root.selected_route == route_name:
				pending_train_spawn.player_train = true
				pending_train_spawn.train_path = Root.selected_train

			pending_train_spawn.time = available_time
			pending_train_spawn.train_path = train_path
			pending_train_spawn.route_name = route_name
			pending_train_spawn.minimal_platform_length = minimal_platform_length
			pending_train_spawn.route = train_rail_route
			pending_train_spawn.station_table = train_station_table
			pending_train_spawn.despawn_point = despawn_point
			pending_train_spawn.scenario_route = route
			pending_train_spawns.append(pending_train_spawn)

	check_train_spawn(1)
	var description := tr(current_scenario.description) if \
			routes[Root.selected_route].description.empty() \
			else tr(routes[Root.selected_route].description)
	jEssentials.call_delayed(1, $Players/Player, "show_textbox_message", [description])


func _apply_scenario_environment(force := false) -> void:
	if current_scenario == null or Root.Editor:
		return

	var visual_time := time if current_scenario.dynamic_time_of_day else _scenario_start_time
	if force or visual_time != _last_environment_time:
		var environment := _get_scenario_environment()
		var sunlight := get_node_or_null("DirectionalLight") as DirectionalLight
		if environment != null:
			_apply_time_of_day(environment, sunlight, visual_time)
		_last_environment_time = visual_time

	_update_weather_particles()


func _get_scenario_environment() -> Environment:
	if not has_node("WorldEnvironment"):
		return null

	var environment_node := $WorldEnvironment as WorldEnvironment
	if environment_node.environment == null:
		return null

	if not _scenario_environment_prepared:
		var environment := environment_node.environment.duplicate(true) as Environment
		if environment.background_sky != null:
			environment.background_sky = environment.background_sky.duplicate(true)
		environment_node.environment = environment
		_scenario_environment_prepared = true

	return environment_node.environment


func _apply_time_of_day(environment: Environment, sunlight: DirectionalLight, seconds: int) -> void:
	var normalized_seconds := int(seconds) % DAY_SECONDS
	if normalized_seconds < 0:
		normalized_seconds += DAY_SECONDS

	var hour := float(normalized_seconds) / 3600.0
	var sun_height := sin(((hour - 6.0) / 12.0) * PI)
	var daylight := clamp((sun_height + 0.15) / 0.55, 0.0, 1.0)
	var twilight := clamp(1.0 - abs(sun_height) / 0.25, 0.0, 1.0)
	var weather := int(current_scenario.weather)

	var night_color := Color(0.08, 0.10, 0.18, 1.0)
	var day_color := Color(1.0, 0.96, 0.90, 1.0)
	var twilight_color := Color(1.0, 0.56, 0.34, 1.0)
	var light_color := night_color.linear_interpolate(day_color, daylight)
	light_color = light_color.linear_interpolate(twilight_color, twilight * (1.0 - daylight * 0.35))
	var light_energy := lerp(0.05, 1.15, daylight)

	match weather:
		WEATHER_RAIN:
			light_color = light_color.linear_interpolate(Color(0.60, 0.66, 0.74, 1.0), 0.45)
			light_energy *= 0.55
		WEATHER_SNOW:
			light_color = light_color.linear_interpolate(Color(0.84, 0.90, 1.0, 1.0), 0.35)
			light_energy *= 0.75

	if sunlight != null:
		var altitude := lerp(-22.0, 68.0, max(sun_height, 0.0))
		var azimuth := (float(normalized_seconds) / float(DAY_SECONDS)) * 360.0 - 90.0
		sunlight.rotation_degrees = Vector3(-altitude, azimuth, 0.0)
		sunlight.light_color = light_color
		sunlight.light_energy = light_energy

	environment.background_energy = lerp(0.12, 1.0, daylight)
	environment.ambient_light_color = night_color.linear_interpolate(day_color, clamp(daylight + 0.15, 0.0, 1.0))
	environment.ambient_light_energy = lerp(0.22, 0.75, daylight)
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.0

	var sky = environment.background_sky
	if sky is ProceduralSky:
		var sky_top := Color(0.04, 0.06, 0.14, 1.0).linear_interpolate(Color(0.51, 0.68, 0.82, 1.0), daylight)
		var sky_horizon := Color(0.08, 0.09, 0.16, 1.0).linear_interpolate(Color(0.80, 0.87, 0.91, 1.0), daylight)
		sky_top = sky_top.linear_interpolate(twilight_color, twilight * 0.35)
		sky_horizon = sky_horizon.linear_interpolate(twilight_color, twilight * 0.55)
		sky.sky_top_color = sky_top
		sky.sky_horizon_color = sky_horizon
		sky.ground_bottom_color = sky_horizon
		sky.ground_horizon_color = sky_horizon
		sky.sun_latitude = clamp(lerp(-20.0, 58.0, max(sun_height, 0.0)), -20.0, 58.0)
		sky.sun_longitude = (float(normalized_seconds) / float(DAY_SECONDS)) * 360.0
		sky.sun_energy = light_energy * 3.0

	if Root.mobile_version:
		return

	match weather:
		WEATHER_RAIN:
			environment.fog_enabled = true
			environment.fog_color = Color(0.39, 0.43, 0.48, 1.0)
			environment.fog_sun_color = Color(0.62, 0.67, 0.72, 1.0)
			environment.fog_depth_begin = 50.0
			environment.fog_depth_end = 420.0
			environment.background_energy *= 0.72
			environment.adjustment_saturation = 0.72
		WEATHER_SNOW:
			environment.fog_enabled = true
			environment.fog_color = Color(0.80, 0.85, 0.90, 1.0)
			environment.fog_sun_color = Color(0.92, 0.95, 1.0, 1.0)
			environment.fog_depth_begin = 35.0
			environment.fog_depth_end = 360.0
			environment.background_energy *= 0.85
			environment.adjustment_saturation = 0.82
		_:
			environment.fog_enabled = ProjectSettings["game/graphics/fog"]
			environment.fog_color = Color(1.0, 1.0, 1.0, 1.0)
			environment.fog_sun_color = Color(1.0, 1.0, 1.0, 1.0)
			environment.fog_depth_begin = 156.3
			environment.fog_depth_end = 766.7


func _update_weather_particles() -> void:
	if current_scenario == null:
		return

	var weather := int(current_scenario.weather)
	if weather == WEATHER_CLEAR or Root.mobile_version:
		_clear_weather_particles()
		return

	if _weather_particles == null:
		_weather_particles = Particles.new()
		_weather_particles.name = "ScenarioWeather"
		add_child(_weather_particles)

	if _weather_particle_mode != weather:
		_configure_weather_particles(weather)

	var target := player if is_instance_valid(player) else null
	if target != null:
		var origin: Vector3 = target.global_transform.origin
		origin.y += WEATHER_HEIGHT
		_weather_particles.global_transform.origin = origin

	_weather_particles.emitting = true


func _configure_weather_particles(weather: int) -> void:
	_weather_particle_mode = weather
	_weather_particles.amount = 900 if weather == WEATHER_RAIN else 450
	_weather_particles.lifetime = 1.4 if weather == WEATHER_RAIN else 4.0
	_weather_particles.preprocess = _weather_particles.lifetime
	_weather_particles.local_coords = false
	_weather_particles.visibility_aabb = AABB(
		Vector3(-WEATHER_RADIUS, -WEATHER_HEIGHT, -WEATHER_RADIUS),
		Vector3(WEATHER_RADIUS * 2.0, WEATHER_HEIGHT * 2.0, WEATHER_RADIUS * 2.0)
	)

	var particle_material := ParticlesMaterial.new()
	particle_material.emission_shape = ParticlesMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(WEATHER_RADIUS, 1.0, WEATHER_RADIUS)
	particle_material.direction = Vector3(0.0, -1.0, 0.0)
	particle_material.spread = 7.0 if weather == WEATHER_RAIN else 45.0

	var mesh := CubeMesh.new()
	var mesh_material := SpatialMaterial.new()
	mesh_material.flags_unshaded = true

	if weather == WEATHER_RAIN:
		particle_material.gravity = Vector3(4.0, -42.0, 0.0)
		particle_material.initial_velocity = 25.0
		mesh.size = Vector3(0.025, 0.75, 0.025)
		mesh_material.albedo_color = Color(0.62, 0.74, 0.95, 0.62)
	else:
		particle_material.gravity = Vector3(1.5, -4.0, 0.0)
		particle_material.initial_velocity = 2.0
		mesh.size = Vector3(0.12, 0.12, 0.12)
		mesh_material.albedo_color = Color(1.0, 1.0, 1.0, 0.86)

	mesh.material = mesh_material
	_weather_particles.process_material = particle_material
	_weather_particles.draw_pass_1 = mesh


func _clear_weather_particles() -> void:
	_weather_particle_mode = -1
	if _weather_particles == null:
		return
	_weather_particles.queue_free()
	_weather_particles = null


func spawn_train(train_spawn_information: TrainSpawnInformation) -> void:
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
	new_train.route = train_spawn_information.scenario_route

	var route = train_spawn_information.scenario_route
	new_train.spawn_point = route.get_spawn_point(new_train.length, self)
	new_train.despawn_point = train_spawn_information.despawn_point
	new_train.station_table = train_spawn_information.station_table
	new_train.ready()


var _check_train_spawn_timer: float = 0
func check_train_spawn(delta: float) -> void:
	_check_train_spawn_timer += delta
	if _check_train_spawn_timer < 0.5:
		return
	_check_train_spawn_timer = 0
	var restart := true
	while restart:
		restart = false
		for pending_train_spawn in pending_train_spawns:
			if pending_train_spawn.time > time:
				continue
			spawn_train(pending_train_spawn)
			pending_train_spawns.erase(pending_train_spawn)
			restart = true
			break


func update_rail_connections() -> void:
	for rail_node in $Rails.get_children():
		rail_node.update_positions_and_rotations()
	for rail_node in $Rails.get_children():
		rail_node.update_connections()


func get_path_from_to(start_node: Rail, end_rail: Rail, forward: bool) -> Array:
	var reachable := { start_node: [0, null, forward] }
	var explored := {}

	while not reachable.empty():
		# Choose some node we know how to reach.
		var rail := _choose_node(reachable, end_rail)

		# Don't repeat ourselves.
		explored[rail] = reachable[rail]
		reachable.erase(rail)

		# If we just got to the goal node, build and return the path.
		if rail == end_rail:
			return _build_path(end_rail, explored)

		for adjacent in rail.get_connected_rails(explored[rail][2]):
			# Where can we get from here that we haven't explored before?
			if adjacent in explored:
				continue

			var fwd = adjacent.get_connection_direction(rail)

			# First time we see this node?
			if not adjacent in reachable:
				reachable[adjacent] = [explored[rail][0] + adjacent.length, rail, fwd]
				continue

			# If this is a new path, or a shorter path than what we have, keep it.
			if explored[rail][0] + adjacent.length < reachable[adjacent][0]:
				reachable[adjacent][0] = explored[rail][0] + adjacent.length
				reachable[adjacent][1] = rail
				reachable[adjacent][2] = fwd

	# If we get here, no path was found :(
	return []


func _choose_node(reachable: Dictionary, destination: Rail) -> Rail:
	var min_cost := INF
	var best_rail: Rail = null
	for rail in reachable:
		var cost: float = reachable[rail][0]
		cost += destination.translation.distance_squared_to(rail.translation)

		if cost < min_cost:
			min_cost = cost
			best_rail = rail
	assert(best_rail)
	return best_rail


func _build_path(rail: Rail, explored: Dictionary) -> Array:
	var path := []
	assert(rail in explored)
	while rail:
		path.append({"rail": rail, "forward": explored[rail][2]})
		rail = explored[rail][1]

	path.invert()
	return path


# Not called automaticly. From any instance or button, but very helpful.
func update_all_rails_overhead_line_setting(has_overhead_line: bool) -> void:
	for rail in $Rails.get_children():
		rail.has_overhead_line = has_overhead_line
		rail.updateOverheadLine()


## Should be later used if we have a real heightmap
func get_terrain_height_at(_position: Vector2) -> float:
	return 0.0


func jump_player_to_station(station_table_index: int) -> void:
	Logger.log("Jumping player to station " + player.station_table[station_table_index].station_name)
	var new_station_node: Spatial = get_signal(player.station_table[station_table_index].station_node_name)

	time = player.station_table[station_table_index].arrival_time

	# Delete npcs with are crossing rails with player route to station
	update_rail_connections()
	var route_player_to_station: Array = get_path_from_to(player.currentRail, new_station_node.rail, player.forward)
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
