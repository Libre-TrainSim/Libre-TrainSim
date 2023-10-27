extends Spatial


signal selected_object_changed(new_object, type_string)


var editor_directory: String = ""
var authors: Authors
var editor_info: EditorInfo = null
## Track path without file extension
var current_track_path := "" setget set_current_track_path
## Track name is the string after the last /
var current_track_name := ""

var selected_object: Node = null
var selected_object_type: String = ""

var rail_res: PackedScene = preload("res://Data/Modules/Rail.tscn")
var world: LTSWorld = null


onready var camera := $Camera as EditorCamera


func _ready() -> void:
	# must port trackinfo -> config.tres before loading the world
	# because it contains the world config
	_port_to_new_trackinfo()
	_port_very_old_trackinfo()

	if !load_world():
		return

	Root.connect("world_origin_shifted", self, "_on_world_origin_shifted")

	_port_to_new_chunk_system()
	_port_v1_to_v2_chunks()
	_port_to_new_scenario_system()
	_port_very_old_scenarios()


func _port_to_new_trackinfo():
	var info_file = current_track_path.plus_file(current_track_name) + ".trackinfo"
	var dir = Directory.new()
	if not dir.file_exists(info_file):
		return

	var jsavemodule = jSaveModule.new()
	jsavemodule.set_save_path(info_file)

	var new_file = current_track_path.plus_file(current_track_name) + "_config.tres"
	var world_config = WorldConfig.new()
	world_config.author = jsavemodule.get_value("author", "Unknown")
	world_config.track_description = jsavemodule.get_value("description")
	world_config.editor_notes = jsavemodule.get_value("editor_notes")
	var release_date = jsavemodule.get_value("release_date")
	world_config.release_date = {
		"day": release_date[0],
		"month": release_date[1],
		"year": release_date[2]
	}

	if ResourceSaver.save(new_file, world_config) != OK:
		Logger.err("Failed to save world config %s" % new_file, self)

	dir.remove(info_file)


func _port_very_old_trackinfo():
	var old_cfg = current_track_path.plus_file(current_track_name) + "-scenarios.cfg"
	var dir = Directory.new()
	if not dir.file_exists(old_cfg):
		return

	var jsavemodule = jSaveModule.new()
	jsavemodule.set_save_path(old_cfg)

	var old_world_config: Dictionary = jsavemodule.get_value("world_config", {})

	var world_config = WorldConfig.new()
	world_config.author = old_world_config.get("Author", "Unknown")
	world_config.track_description = old_world_config.get("TrackDesciption", "")
	world_config.editor_notes = ""
	var release_date = old_world_config.get("ReleaseDate", [9, 11, 1989])
	world_config.release_date = {
		"day": release_date[0],
		"month": release_date[1],
		"year": release_date[2]
	}

	var new_file = current_track_path.plus_file(current_track_name) + "_config.tres"
	if ResourceSaver.save(new_file, world_config) != OK:
		Logger.err("Failed to save world config %s" % new_file, self)


func _port_v1_to_v2_chunks() -> void:
	var save_file := current_track_path.plus_file(current_track_name) + ".save"
	var dir := Directory.new()
	if dir.file_exists(save_file):
		return
	if world.get_meta("chunk_version", 1) >= 2:
		return

	randomize()

	# We mess with the chunk manager internals so yeah
	var chunk_manager: ChunkManager = world.chunk_manager
	chunk_manager.pause_chunking()
	chunk_manager.loader._loaded_chunks.clear()
	chunk_manager.loader._chunks_to_load.clear()
	for chunk in world.get_node("Chunks").get_children():
		chunk.get_parent().remove_child(chunk)
		chunk.free()

	# Load all chunks
	var chunks := {} # chunk pos, chunk nodes
	var buildings := []
	var track_objects := []

	var err := dir.open(current_track_path.plus_file("chunks"))
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name in [".", ".."]:
			file_name = dir.get_next()
			continue

		var chunk_name := file_name.get_file().get_basename()

		# Load all chunks and ensure they don't fail
		var chunk = chunk_manager._force_load_chunk_name_immediately(chunk_name) as Chunk
		chunk.name = str(randi())

		var correct_position := chunk_manager.position_to_chunk(chunk.global_transform.origin)
		if not (correct_position in chunks):
			chunks[correct_position] = []

		chunks[correct_position].push_back(chunk)

		track_objects.append_array(chunk.get_node("TrackObjects").get_children())
		buildings.append_array(chunk.get_node("Buildings").get_children())

		dir.remove(file_name)
		file_name = dir.get_next()

	# Again ensure the internal list is clear as we merge and move chunks now.
	chunk_manager.loader._loaded_chunks.clear()

	# Fix rail chunk assignments
	for rail in world.get_node("Rails").get_children():
		rail.set_meta("chunk_pos", world.chunk_manager.position_to_chunk( \
				rail.global_transform.origin))

	# Merge possible duplicates
	for chunk_position in chunks:
		if chunks[chunk_position].size() == 1:
			chunks[chunk_position][0].name = ChunkManager.chunk_to_string(chunk_position)
			chunk_manager.loader._loaded_chunks.append(chunks[chunk_position][0].name)
			continue

		var best_fit: int = 0
		for i in range(chunks[chunk_position].size()):
			if not chunks[chunk_position][i].is_empty:
				best_fit = i
				break

		var best: Chunk = chunks[chunk_position][best_fit]
		chunks[chunk_position][best_fit] = chunks[chunk_position][0]
		chunks[chunk_position][0] = best

		var building_parent := best.get_node("Buildings")
		var track_object_parent := best.get_node("TrackObjects")

		for i in range(1, chunks[chunk_position].size()):
			var local_chunk: Chunk = chunks[chunk_position][i]

			var local_buildings: Spatial = local_chunk.get_node("Buildings")
			for building in local_buildings.get_children():
				var xform: Transform = building.global_transform
				local_buildings.remove_child(building)
				building_parent.add_child(building)
				building.global_transform = xform

			var local_track_objects: Spatial = local_chunk.get_node("TrackObjects")
			for track_object in local_track_objects.get_children():
				var xform: Transform = track_object.global_transform
				local_track_objects.remove_child(track_object)
				track_object_parent.add_child(track_object)
				track_object.global_transform = xform

			local_chunk.get_parent().remove_child(local_chunk)
			local_chunk.free()

		best.name = ChunkManager.chunk_to_string(chunk_position)
		chunk_manager.loader._loaded_chunks.append(best.name)

	# Move buildings
	for building in buildings:
		var xform = building.global_transform
		var chunk := chunk_manager.position_to_chunk(xform.origin)
		if not (chunk in chunks):
			chunks[chunk] = [chunk_manager._force_load_chunk_immediately(chunk)]

		building.get_parent().remove_child(building)
		chunks[chunk][0].get_node("Buildings").add_child(building)
		building.global_transform = xform
		building.owner = chunks[chunk][0]

	# Create rail look-up table to not go into O(n^2) territory
	var rails := {} # rail name (ask the track object), chunk
	for rail in world.get_node("Rails").get_children():
		rails[rail.name] = chunk_manager.position_to_chunk(rail.global_transform.origin)

	# Move track objects
	for track_object in track_objects:
		if not track_object.attached_rail in rails:
			Logger.err("Rail %s was not found in %s." % \
					[track_object.attached_rail, track_object], self)
			continue
		var chunk = rails[track_object.attached_rail]
		if not (chunk in chunks):
			chunks[chunk] = [chunk_manager._force_load_chunk_immediately(chunk)]

		track_object.get_parent().remove_child(track_object)
		chunks[chunk][0].get_node("TrackObjects").add_child(track_object)
		track_object.owner = chunks[chunk][0]
		track_object.update()

	# Save (Resume chunking)
	world.set_meta("chunk_version", 2)
	save_world(false)
	#chunk_manager.resume_chunking()
	send_message("World was converted to v2 chunks. Please reload the world")



func _port_to_new_chunk_system() -> void:
	var save_file = current_track_path.plus_file(current_track_name) + ".save"
	var dir = Directory.new()
	if not dir.file_exists(save_file):
		return

	# convert degrees to radians and fix track object positions
	for rail in $World/Rails.get_children():
		rail.start_rot = deg2rad(rail.start_rot)
		rail.end_rot = deg2rad(rail.end_rot)
		# fixes rail and track object positions
		rail.visible = true
		rail.update()
	for logic in $World/Signals.get_children():
		logic.set_to_rail()

	dir.make_dir_recursive(current_track_path.plus_file("chunks"))

	var jsavemodule = jSaveModule.new()
	jsavemodule.set_save_path(save_file)
	var keys = jsavemodule._config.get_section_keys("Main")

	for key in keys:
		if not "," in key:
			continue
		var old_chunk = jsavemodule.get_value(key, {})
		if old_chunk.empty():
			continue

		var new_chunk = preload("res://Data/Modules/chunk_prefab.tscn").instance()
		new_chunk.name = ChunkManager.chunk_to_string(old_chunk.position)
		new_chunk.chunk_position = old_chunk.position
		new_chunk.rails = old_chunk.Rails

		var buildings_data: Dictionary = old_chunk.Buildings
		for building_data in buildings_data:
			var mesh_instance := MeshInstance.new()
			mesh_instance.name = buildings_data[building_data].name
			mesh_instance.set_mesh(load(buildings_data[building_data].mesh_path))
			mesh_instance.transform = buildings_data[building_data].transform
			var surfaceArr: Array = buildings_data[building_data].surfaceArr
			if surfaceArr == null:
				surfaceArr = []
			for i in range (surfaceArr.size()):
				mesh_instance.set_surface_material(i, surfaceArr[i])

			new_chunk.get_node("Buildings").add_child(mesh_instance)
			mesh_instance.owner = new_chunk

		var track_objects: Dictionary = old_chunk.TrackObjects
		var to_prefab = preload("res://Data/Modules/TrackObjects.tscn")
		for to_key in track_objects:
			var track_obj = track_objects[to_key]
			track_obj.data.mesh = load(track_obj.data.objectPath)
			track_obj.data.materials = []
			for path in track_obj.data.materialPaths:
				track_obj.data.materials.append(load(path))

			var to_instance = to_prefab.instance()
			to_instance.name = track_obj.name
			to_instance.multimesh = MultiMesh.new()
			to_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
			to_instance.materials = []
			to_instance.transform = track_obj.transform
			to_instance.set_data(track_obj.data, true)  # true = convert degrees to radians

			new_chunk.get_node("TrackObjects").add_child(to_instance)
			to_instance.owner = new_chunk

			# correctly position the track object before saving
			# if we don't do this, user must click on every rail individually to fix it
			to_instance.world = $World
			to_instance.update()

		if len(new_chunk.rails) > 0 \
				or new_chunk.get_node("Buildings").get_child_count() > 0 \
				or new_chunk.get_node("TrackObjects").get_child_count() > 0:
			new_chunk.is_empty = false
			new_chunk._prepare_saving()
			var packed_chunk := PackedScene.new()
			packed_chunk.pack(new_chunk)
			var path: String = current_track_path.plus_file("chunks").plus_file(ChunkManager.chunk_to_string(old_chunk.position)) + ".tscn"
			ResourceSaver.save(path, packed_chunk)

		dir.remove(save_file)
		new_chunk.queue_free()

	# remove track object references, they have been freed
	for rail in $World/Rails.get_children():
		rail.track_objects = []

	send_message("Chunks were ported to a new version, please save, close and reload the track.")


func _port_to_new_scenario_system():
	var path = current_track_path.plus_file("scenarios")
	var dir = Directory.new()
	if dir.open(path) != OK:
		Logger.err("Track has no scenarios folder!", self)
		return

	var files_to_remove := []

	# convert .scenario to scenario.tscn files
	dir.list_dir_begin(true, true)
	filename = dir.get_next()
	while filename != "":
		if filename.ends_with(".scenario"):
			_convert_scenario(path.plus_file(filename))
			files_to_remove.append(filename)
		filename = dir.get_next()

	# remove old .scenario files
	for file in files_to_remove:
		dir.remove(file)


func _convert_scenario(filename):
	var jsavemodule = jSaveModule.new()
	jsavemodule.set_save_path(filename)

	var rail_logic_settings = jsavemodule.get_value("rail_logic_settings")
	var routes = jsavemodule.get_value("routes")
	if not is_instance_valid(routes):
		routes = {}  # prevent for loop crashing if routes is null

	var new_scenario = TrackScenario.new()
	new_scenario.rail_logic_settings = _convert_rail_logic_settings(rail_logic_settings)

	for route_name in routes:
		var new_route = ScenarioRoute.new()
		new_route.activate_only_at_specific_routes = routes[route_name]["general_settings"]["activate_only_at_specific_routes"]
		new_route.description = routes[route_name]["general_settings"]["description"]
		new_route.interval = routes[route_name]["general_settings"]["interval"]
		new_route.interval_end = routes[route_name]["general_settings"]["interval_end"]
		new_route.interval_start = routes[route_name]["general_settings"]["interval_start"]
		new_route.is_playable = routes[route_name]["general_settings"]["player_can_drive_this_route"]
		new_route.specific_routes = routes[route_name]["general_settings"]["specific_routes"]
		new_route.train_name = routes[route_name]["general_settings"]["train_name"]
		if routes[route_name].has("rail_logic_settings"):
			new_route.rail_logic_settings = _convert_rail_logic_settings(routes[route_name]["rail_logic_settings"])

		# there is a bug here, where route points from previous routes
		# get added to the new route as well. No idea.
		for route_point in routes[route_name]["route_points"]:
			var new_route_point: RoutePoint = _convert_route_point(route_point)
			if is_instance_valid(new_route_point):
				new_route.route_points.append(new_route_point)

		new_scenario.routes[route_name] = new_route

	var new_file = filename.get_basename() + ".tres"
	var err = ResourceSaver.save(new_file, new_scenario)
	if err != OK:
		Logger.err("Failed to save new scenario at %s. Reason %s" % [new_file, err], self)


func _convert_rail_logic_settings(old_settings) -> Dictionary:
	if not is_instance_valid(old_settings):
		return {}

	var new_settings := {}
	for logic_name in old_settings:
		var new_logic

		if old_settings[logic_name].has("affected_signal"):
			new_logic = ContactPointSettings.new()
			new_logic.enabled = old_settings[logic_name]["enabled"]
			new_logic.affected_signal = old_settings[logic_name]["affected_signal"]
			new_logic.affect_time = old_settings[logic_name]["affect_time"]
			new_logic.new_speed_limit = old_settings[logic_name]["new_speed_limit"]
			new_logic.new_status = old_settings[logic_name]["new_status"]
			new_logic.enable_for_all_trains = old_settings[logic_name]["enable_for_all_trains"]
			new_logic.specific_train = old_settings[logic_name]["specific_train"]

		elif old_settings[logic_name].has("operation_mode"):
			new_logic = SignalSettings.new()
			new_logic.operation_mode = old_settings[logic_name]["operation_mode"]
			new_logic.signal_free_time = old_settings[logic_name]["signal_free_time"]
			new_logic.speed = old_settings[logic_name]["speed"]
			new_logic.status = old_settings[logic_name]["status"]

		elif old_settings[logic_name].has("assigned_signal"):
			new_logic = StationSettings.new()
			new_logic.assigned_signal_name = old_settings[logic_name]["assigned_signal"]
			new_logic.enable_person_system = old_settings[logic_name]["enable_person_system"]
			new_logic.overwrite = old_settings[logic_name]["overwrite"]

		new_settings[logic_name] = new_logic
	return new_settings


func _convert_route_point(old_point: Dictionary) -> RoutePoint:
	if not old_point.has("type"):
		return null

	var new_point: RoutePoint
	match old_point["type"]:
		0:
			new_point = RoutePointStation.new()
			new_point.station_node_name = old_point["node_name"]
			new_point.station_name = old_point["station_name"]
			new_point.stop_type = old_point["stop_type"]
			new_point.duration_since_last_station = old_point["duration_since_station_before"]
			new_point.minimum_halt_time = old_point["minimal_halt_time"]
			new_point.planned_halt_time = old_point["planned_halt_time"]
			new_point.signal_time = old_point["signal_time"]
			new_point.approach_sound_path = old_point["approach_sound_path"]
			new_point.arrival_sound_path = old_point["arrival_sound_path"]
			new_point.departure_sound_path = old_point["departure_sound_path"]
			new_point.leaving_persons = old_point["leaving_persons"]
			new_point.waiting_persons = old_point["waiting_persons"]
		1:
			new_point = RoutePointWayPoint.new()
			new_point.rail_name = old_point["rail_name"]
		2:
			new_point = RoutePointSpawnPoint.new()
			new_point.rail_name = old_point["rail_name"]
			new_point.distance_on_rail = old_point["distance"]
			new_point.initial_speed = old_point["initial_speed"]
			new_point.initial_speed_limit = old_point["initial_speed_limit"]
		3:
			new_point = RoutePointDespawnPoint.new()
			new_point.rail_name = old_point["rail_name"]
			new_point.distance_on_rail = old_point["distance"]

	return new_point


func _port_very_old_scenarios():
	var old_file = current_track_path.plus_file(current_track_name) + "-scenarios.cfg"
	var dir = Directory.new()
	if not dir.file_exists(old_file):
		return

	if not dir.dir_exists(current_track_path.plus_file("scenarios")):
		dir.make_dir_recursive(current_track_path.plus_file("scenarios"))

	var jsavemodule = jSaveModule.new()
	jsavemodule.set_save_path(old_file)

	var scenario_list = jsavemodule.get_value("scenario_list", [])
	var scenario_data = jsavemodule.get_value("scenario_data", {})
	for scenario in scenario_list:
		var data = scenario_data[scenario]

		var new_scenario = TrackScenario.new()
		new_scenario.title = scenario
		new_scenario.description = data.get("Description", "")
		new_scenario.duration = data.get("Duration", "")

		var hour = data.get("TimeH", 12)
		var minute = data.get("TimeM", 0)
		var second = data.get("TimeS", 0)
		new_scenario.time = Math.time_to_seconds([hour, minute, second])

		var signal_infos = data.get("Signals", {})
		for signal_name in signal_infos:
			var info = signal_infos[signal_name]
			if info == null:
				continue
			elif info.has("affectTime"):
				var settings = ContactPointSettings.new()
				settings.affect_time = info["affectTime"]
				settings.affected_signal = info["affectedSignal"]
				settings.enabled = true
				if info["bySpecificTrain"] != "":
					settings.enable_for_all_trains = false
					settings.specific_train = info["bySpecificTrain"]
				settings.new_status = info.get("newStatus", 1)
				settings.new_speed_limit = info.get("newSpeed", -1)
				new_scenario.rail_logic_settings[signal_name] = settings
			elif info.has("is_block_signal"):
				var settings = SignalSettings.new()
				if info["is_block_signal"] == true:
					settings.operation_mode = SignalOperationMode.BLOCK
				else:
					settings.operation_mode = SignalOperationMode.MANUAL
				settings.speed = info["speed"]
				settings.status = info["status"]
				var _hour = info["set_pass_at_h"]
				var _minute = info["set_pass_at_m"]
				var _second = info["set_pass_at_s"]
				settings.signal_free_time = Math.time_to_seconds([_hour, _minute, _second])
				new_scenario.rail_logic_settings[signal_name] = settings

		var trains = data.get("Trains", {})
		for train_name in trains:
			var info = trains[train_name]
			var route = ScenarioRoute.new()
			if train_name == "Player":
				route.is_playable = true
			route.train_name = info["PreferredTrain"]

			var spawn_point = RoutePointSpawnPoint.new()
			spawn_point.rail_name = info["StartRail"]
			spawn_point.forward = bool(info["Direction"])
			spawn_point.distance_on_rail = info["StartRailPosition"]
			spawn_point.initial_speed = info["InitialSpeed"]
			spawn_point.initial_speed_limit = info["InitialSpeedLimit"]
			route.route_points.append(spawn_point)

			var stations = info["Stations"]
			for i in range(len(stations["nodeName"])):
				var point = RoutePointStation.new()
				point.station_node_name = stations["nodeName"][i]
				point.station_name = stations["stationName"][i]
				point.approach_sound_path = stations["approachAnnouncePath"][i]
				point.arrival_sound_path = stations["arrivalAnnouncePath"][i]
				point.departure_sound_path = stations["departureAnnouncePath"][i]
				point.planned_halt_time = stations["haltTime"][i]
				point.leaving_persons = stations["leavingPersons"][i]
				point.waiting_persons = stations["waitingPersons"][i]
				point.stop_type = stations["stopType"][i]
				if i > 0:
					var last_depart = Math.time_to_seconds(stations["departureTime"][i-1])
					var arrival = Math.time_to_seconds(stations["arrivalTime"][i])
					point.duration_since_last_station = arrival - last_depart
				route.route_points.append(point)

			if info["DespawnRail"] != "":
				var despawn_point = RoutePointDespawnPoint.new()
				despawn_point.rail_name = info["DespawnRail"]
				route.route_points.append(despawn_point)

			new_scenario.routes[train_name] = route

		var path = current_track_path.plus_file("scenarios")
		var new_file = path.plus_file(scenario) + ".tres"
		var err = ResourceSaver.save(new_file, new_scenario)
		if err != OK:
			Logger.err("Failed to save new scenario at %s. Reason %s" % [new_file, err], self)

	dir.remove(old_file)



func _enter_tree() -> void:
	Root.Editor = true


func _exit_tree() -> void:
	if is_instance_valid($World) and is_instance_valid($World.chunk_manager):
		$World.chunk_manager.cleanup()
	Root.Editor = false


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == BUTTON_LEFT and mb.pressed:
		select_object_under_mouse()

	if Input.is_action_just_pressed("save"):
		save_world()

	if Input.is_action_just_pressed("delete"):
		delete_selected_object()

	if Input.is_action_just_pressed("ui_accept") and $EditorHUD/Message.visible:
		_on_MessageClose_pressed()


func _input(event) -> void:
	if event is InputEventMouseButton and not event.pressed and drag_mode:
		end_drag_mode()

	if event is InputEventMouseMotion and drag_mode:
		handle_drag_mode()


var drag_mode: bool = false
func begin_drag_mode() -> void:
	drag_mode = true
	#print("DRAG MODE START")


func end_drag_mode() -> void:
	drag_mode = false
	#print("DRAG MODE END")


var _last_connected_signal: String = ""
func handle_drag_mode() -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var plane := Plane(Vector3(0,1,0), selected_object.start_pos.y)
	var mouse_pos_3d := plane.intersects_ray(camera.project_ray_origin(mouse_pos), camera.project_ray_normal(mouse_pos))
	if mouse_pos_3d != null:
		selected_object.calculate_from_start_end(mouse_pos_3d)  # update rail
		provide_settings_for_selected_object()  # update ui

	# wait for update of overlapping areas, else we can never un-snap
	# yes, this really needs idle_frame, won't work otherwise
	yield(get_tree(), "idle_frame")

	if not is_instance_valid(selected_object):
		return

	# lazy snapping done via collision areas
	var snapped_object: Node = null
	var snapped_start: bool = false
	var overlaps: Array = selected_object.get_node("Ending").get_overlapping_areas()
	if not overlaps.empty():
		for area in overlaps:
			if get_type_of_object(area.get_parent()) == "Rail" and area.get_parent() != selected_object:
				selected_object.calculate_from_start_end(area.global_transform.origin)
				snapped_object = area.get_parent()
				snapped_start = (area.name == "Beginning")
				break

	# multi-segment snapping (subdivide rail to make angles fit together)
	if snapped_object != null:
		var start_rot: float = selected_object.start_rot
		var end_rot: float = selected_object.end_rot
		var snap_rot: float
		var snap_pos: Vector3
		if snapped_start:
			snap_rot = snapped_object.start_rot
			snap_pos = snapped_object.start_pos
		else:
			snap_rot = snapped_object.end_rot - PI
			snap_pos = snapped_object.end_pos

		if Math.angle_distance_rad(end_rot, snap_rot) < deg2rad(1):
			# angles snapped correctly, we can leave this as is :)
			pass
		elif Math.angle_distance_rad(start_rot, snap_rot) < deg2rad(1):
			if _local_x_distance(start_rot, selected_object.start_pos, snap_pos) < 20:
				return
			if not $EditorHUD/SnapDialog.is_connected("confirmed", self, "_snap_simple_connector"):
				$EditorHUD/SnapDialog.dialog_text = tr("EDITOR_SNAP_CONNECTOR")
				$EditorHUD/SnapDialog.popup_centered()
				_last_connected_signal = "_snap_simple_connector"
				$EditorHUD/SnapDialog.connect("confirmed", self, "_snap_simple_connector", [snap_pos, snap_rot], CONNECT_ONESHOT)
		elif abs(Math.angle_distance_rad(start_rot, snap_rot) - (0.5*PI)) < deg2rad(1):
			# right angle, can be done with straight rail + 90deg curve
			if not $EditorHUD/SnapDialog.is_connected("confirmed", self, "_snap_90deg_connector"):
				$EditorHUD/SnapDialog.dialog_text = tr("EDITOR_SNAP_CONNECTOR")
				$EditorHUD/SnapDialog.popup_centered()
				_last_connected_signal = "_snap_90deg_connector"
				$EditorHUD/SnapDialog.connect("confirmed", self, "_snap_90deg_connector", [snap_pos, snap_rot], CONNECT_ONESHOT)
		else:
			# complicated snapping I don't know how to do yet
			if not $EditorHUD/SnapDialog.is_connected("confirmed", self, "_snap_complex_connector"):
				$EditorHUD/SnapDialog.dialog_text = tr("EDITOR_SNAP_CONNECTOR_TODO")
				$EditorHUD/SnapDialog.popup_centered()
				_last_connected_signal = "_snap_complex_connector"
				$EditorHUD/SnapDialog.connect("confirmed", self, "_snap_complex_connector", [snap_pos, snap_rot], CONNECT_ONESHOT)
	else:
		if _last_connected_signal != "" and $EditorHUD/SnapDialog.is_connected("confirmed", self, _last_connected_signal):
			$EditorHUD/SnapDialog.disconnect("confirmed", self, _last_connected_signal)
		$EditorHUD/SnapDialog.hide()


func _local_x_distance(rot: float, a: Vector3, b: Vector3) -> float:
	var dir := Vector3(1,0,0).rotated(Vector3.UP, rot).normalized()
	return dir.dot(b - a)


func _local_z_distance(rot: float, a: Vector3, b: Vector3) -> float:
	var dir := Vector3(0,0,1).rotated(Vector3.UP, rot).normalized()
	return dir.dot(b - a)


func _snap_90deg_connector(snap_pos: Vector3, snap_rot: float) -> void:
	var start_pos: Vector3 = selected_object.start_pos
	var start_rot: float = selected_object.start_rot

	var start_dir := Vector3(1,0,0).rotated(Vector3.UP, selected_object.start_rot).normalized()
	var ortho_dir := Vector3(0,0,1).rotated(Vector3.UP, selected_object.start_rot).normalized()

	var x_length: float = abs(start_dir.dot(snap_pos - start_pos))
	var y_length: float = ortho_dir.dot(snap_pos - start_pos)
	var y_sign: float = sign(y_length)
	y_length = abs(y_length)

	if abs(x_length - y_length) < 1:
		var new_end: Vector3 = start_pos + Vector3(x_length, 0, y_sign * y_length).rotated(Vector3.UP, start_rot)
		selected_object.calculate_from_start_end(new_end)

	elif x_length > y_length:
		selected_object.radius = 0
		selected_object.length = x_length - y_length
		selected_object.update()

		var rail2: Node = _spawn_rail()
		rail2.translation = selected_object.end_pos
		rail2.start_pos = selected_object.end_pos
		rail2.rotation.y = selected_object.end_rot
		rail2.start_rot = selected_object.end_rot
		var new_end = rail2.start_pos + Vector3(y_length, 0, y_sign * y_length).rotated(Vector3.UP, start_rot)
		rail2.calculate_from_start_end(new_end)

	else:
		var new_end: Vector3 = start_pos + Vector3(x_length, 0, y_sign * x_length).rotated(Vector3.UP, start_rot)
		selected_object.calculate_from_start_end(new_end)

		var rail2: Node = _spawn_rail()
		rail2.translation = selected_object.end_pos
		rail2.start_pos = selected_object.end_pos
		rail2.rotation.y = selected_object.end_rot
		rail2.start_rot = selected_object.end_rot
		rail2.radius = 0
		rail2.length = y_length - x_length
		rail2.update()


func _snap_simple_connector(snap_pos: Vector3, snap_rot: float) -> void:
	# can easily connect with 2 segments
	# this is basically the old rail connector for switches
	var rail1_end: Vector3 = 0.5 * (selected_object.start_pos + snap_pos)
	selected_object.calculate_from_start_end(rail1_end)

	var rail2: Node = _spawn_rail()
	rail2.translation = rail1_end
	rail2.start_pos = rail1_end
	rail2.rotation.y = selected_object.end_rot
	rail2.start_rot = selected_object.end_rot
	rail2.calculate_from_start_end(snap_pos)

	assert(Math.angle_distance_rad(rail2.end_rot, snap_rot) < deg2rad(1))

	drag_mode = false


func _snap_complex_connector(snap_pos: Vector3, snap_rot: float) -> void:
	# TODO: I don't know how to do it yet
	pass


func select_object_under_mouse() -> void:
	# Return early if we currently have an active gizmo
	if object_has_active_gizmo(selected_object):
		return

	var ray_length: float = 1000
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mouse_pos)
	var to: Vector3 = from + camera.project_ray_normal(mouse_pos) * ray_length

	var space_state = get_world().get_direct_space_state()
	# use global coordinates, not local to node
	var result = space_state.intersect_ray(from, to, [  ], 0x7FFFFFFF, true, true)
	var obj_to_select: Spatial = null
	if result.has("collider"):
		obj_to_select = result["collider"].get_parent_spatial()
	else:
		clear_selected_object()
		return

	while not (obj_to_select is WorldObject or obj_to_select is MeshInstance):
		Logger.vlog("Trying to find object", obj_to_select)
		obj_to_select = obj_to_select.get_parent_spatial()
		if obj_to_select == self or obj_to_select == null:
			Logger.vlog("No object found", result["collider"])
			clear_selected_object()
			return

	if get_type_of_object(obj_to_select) == "Rail" and result.collider.name == "Ending":
		begin_drag_mode()

	set_selected_object(obj_to_select)
	Logger.vlog("selected!", obj_to_select)


func clear_selected_object() -> void:
	Logger.vlog("Deselect object", selected_object)
	if is_instance_valid(selected_object):
		var vis = get_children_of_type_recursive(selected_object, VisualInstance)
		for vi in vis:
			vi.set_layer_mask_bit(1, false)

		if selected_object_type == "Building":
			$EditorHUD/Settings/TabContainer/BuildingSettings.set_mesh(null)
		if selected_object_type in ["Building", "Rail"]:
			$EditorHUD.hide_current_object_transform()
			for child in selected_object.get_children():
				if child.is_in_group("Gizmo"):
					child.queue_free()
		if selected_object_type == "Signal":
			$EditorHUD/Settings/TabContainer/RailLogic._on_selected_rail_logic_deleted()

		emit_signal("selected_object_changed", null, "")

	selected_object = null
	selected_object_type = ""
	$EditorHUD.clear_current_object_name()


func get_type_of_object(object: Node) -> String:
	if object.is_in_group("Rail"):
		return "Rail"
	if object.is_in_group("Signal"):
		return "Signal"
	if object.get_parent().name == "Buildings":
		return "Building"
	else:
		Logger.warn("Unknown object type encountered!", object)
		return "Unknown"


func object_has_active_gizmo(object: Node) -> bool:
	# Return early if object is null
	if not is_instance_valid(object):
		return false

	# Iterate over children and return true if an ACTIVE gizmo is found
	for node in object.get_children():
		if node.is_in_group("Gizmo"):
			if node.any_axis_active():
				return true
	return false


func provide_settings_for_selected_object() -> void:
	match selected_object_type:
		"Rail":
			$EditorHUD/Settings/TabContainer/RailAttachments.update_selected_rail(selected_object)
			$EditorHUD/Settings/TabContainer/RailBuilder.update_selected_rail(selected_object)
			$EditorHUD.show_rail_settings()
		"Building":
			var children := get_children_of_type_recursive(selected_object, MeshInstance)
			var mesh: ArrayMesh = children[0].mesh as ArrayMesh if children.size() > 0 else null
			$EditorHUD/Settings/TabContainer/BuildingSettings.set_mesh(mesh, children[0])
			$EditorHUD.show_building_settings()
		"Signal":
			$EditorHUD/Settings/TabContainer/RailLogic.set_rail_logic(selected_object)
			$EditorHUD.show_signal_settings()
		_:
			$EditorHUD/Settings/TabContainer/RailAttachments.update_selected_rail(null)
			$EditorHUD/Settings/TabContainer/RailBuilder.update_selected_rail(null)
	$EditorHUD.update_ShowSettingsButton()


## Should be used, if world is loaded into scene.
func load_world() -> bool:
	editor_directory = jSaveManager.get_setting("editor_directory_path", "user://editor/")
	var path := current_track_path.plus_file(current_track_name) + ".tscn"
	var world_resource: PackedScene = load(path)
	if world_resource == null:
		send_message("World data could not be loaded! Is your .tscn file corrupt?\nIs every resource available?")
		return false

	world = world_resource.instance() as LTSWorld
	if !world:
		send_message("Failed to load world. World is not an LTSWorld.")
		return false

	editor_info = load(current_track_path.plus_file("editor_info.tres"))
	if !editor_info:
		editor_info = EditorInfo.new()
	$EditorHUD/Objects.editor_info = editor_info

	world.FileName = current_track_name
	add_child(world)
	world.owner = self

	$EditorHUD/Settings/TabContainer/RailBuilder.world = $World
	$EditorHUD/Settings/TabContainer/RailAttachments.world = $World

	## Load Camera Position
	var last_editor_camera_transforms = jSaveManager.get_value("last_editor_camera_transforms", {})
	if last_editor_camera_transforms.has(current_track_name):
		camera.load_from_transform(last_editor_camera_transforms[current_track_name])

	return true


func save_world(send_message: bool = true) -> void:
	## Save Camera Position
	var last_editor_camera_transforms: Dictionary = jSaveManager.get_value("last_editor_camera_transforms", {})
	last_editor_camera_transforms[current_track_name] = camera.transform
	jSaveManager.save_value("last_editor_camera_transforms", last_editor_camera_transforms)

	$World.chunk_manager.pause_chunking()

	# move newly created buildings from world to chunks
	for building in $World/Buildings.get_children():
		var chunk_pos = $World.chunk_manager.position_to_chunk(building.global_transform.origin)
		var chunk_name = $World.chunk_manager.chunk_to_string(chunk_pos)

		var chunk = $World/Chunks.find_node(chunk_name)
		if not is_instance_valid(chunk):
			chunk = $World.chunk_manager._force_load_chunk_immediately(chunk_pos)

		$World/Buildings.remove_child(building)
		chunk.get_node("Buildings").add_child(building)
		building.owner = chunk

	$World.chunk_manager.save_and_unload_all_chunks()
	assert($World/Chunks.get_child_count() == 0)

	# We only want to keep the _temp files if the editor crashes or the user didn't save until now.
	# When the user saves the whole world and nothing crashed until here we can now safely delete our _temp files.
	$World.chunk_manager.cleanup()

	var packed_scene = PackedScene.new()
	var result = packed_scene.pack($World)
	if result == OK:
		var error = ResourceSaver.save(current_track_path.plus_file(current_track_name) + ".tscn", packed_scene)
		if error != OK:
			send_message("An error occurred while saving the scene to disk.")
			return


	if ResourceSaver.save(current_track_path.plus_file("editor_info.tres"), editor_info) != OK:
		Logger.warn("Failed to save editor info meta data.", self)

	$World.chunk_manager.active_chunk = $World.chunk_manager.position_to_chunk(camera.global_transform.origin)
	$World.chunk_manager.resume_chunking()

	if send_message:
		send_message("World successfully saved!")


func _on_SaveWorldButton_pressed() -> void:
	save_world()


func rename_selected_object(new_name: String) -> void:
	Root.name_node_appropriate(selected_object, new_name, selected_object.get_parent())
	$EditorHUD.set_current_object_name(selected_object.name)
	provide_settings_for_selected_object()


func delete_selected_object() -> void:
	if selected_object_type == "Rail":
		$World.chunk_manager.remove_rail(selected_object)

	selected_object.queue_free()
	clear_selected_object()


func get_rail(name: String) -> Node:
	return $World/Rails.get_node_or_null(name)


func set_selected_object(object: Node) -> void:
	clear_selected_object()

	var vis = get_children_of_type_recursive(object, VisualInstance)
	for vi in vis:
		vi.set_layer_mask_bit(1, true)

	selected_object = object
	$EditorHUD.set_current_object_name(selected_object.name)
	selected_object_type = get_type_of_object(selected_object)

	if selected_object_type == "Building":
		selected_object.add_child(preload("res://Editor/Modules/Gizmo.tscn").instance())
		$EditorHUD.show_current_object_transform()
	if selected_object_type == "Rail":
		if selected_object.manual_moving:
			selected_object.add_child(preload("res://Editor/Modules/Gizmo.tscn").instance())
			$EditorHUD.show_current_object_transform()

	provide_settings_for_selected_object()
	emit_signal("selected_object_changed", object, selected_object_type)


func _spawn_rail() -> Node:
	var rail_instance: Node = rail_res.instance()
	rail_instance.name = Root.name_node_appropriate(rail_instance, "Rail", $World/Rails)
	$World/Rails.add_child(rail_instance)
	rail_instance.set_owner($World)
	#rail_instance._update()

	if rail_instance.has_overhead_line:
		_spawn_poles_for_rail(rail_instance)

	return rail_instance


func _spawn_poles_for_rail(rail: Node) -> void:
	var track_object = preload("res://Data/Modules/TrackObjects.tscn").instance()
	track_object.sides = 2
	track_object.rows = 1
	track_object.wholeRail = true
	track_object.placeLast = true
	track_object.mesh = load("res://Resources/Objects/Pole1.obj")
	track_object.materials = [
		load("res://Resources/Materials/Beton.tres"),
		load("res://Resources/Materials/Metal_Green.tres"),
		load("res://Resources/Materials/Metal.tres"),
		load("res://Resources/Materials/Metal_Brown.tres")
	]
	track_object.attached_rail = rail.name
	track_object.length = rail.length
	track_object.distanceLength = 50
	track_object.rotationObjects = -(0.5 * PI)
	track_object.name = rail.name + " Poles"
	track_object.description = "Poles"

	rail.track_objects.append(track_object)

	var chunk_pos = $World.chunk_manager.position_to_chunk(rail.global_transform.origin)
	var chunk_name = $World.chunk_manager.chunk_to_string(chunk_pos)
	var chunk = $World/Chunks.get_node(chunk_name)

	chunk.get_node("TrackObjects").add_child(track_object)
	track_object.owner = chunk

	track_object.update()
	rail.update()


func add_rail() -> void:
	var rail_instance: Node = _spawn_rail()
	rail_instance.translation = get_current_ground_position()

	$World.chunk_manager.add_rail(rail_instance)

	set_selected_object(rail_instance)


func get_current_ground_position() -> Vector3:
	var position: Vector3 = camera.translation
	position.y = $World.get_terrain_height_at(Vector2(position.x, position.z))
	return position


func test_track() -> void:
	if ContentLoader.get_scenarios_for_track(current_track_path).size() == 0:
		send_message("Cannot test the track! Please create a scenario using the scenario editor.")
		return

	save_world(false)

	$EditorHUD/PlayMenu.show_scenario_selector( \
		current_track_path.plus_file(current_track_name + ".tscn")
	)


func export_mod() -> void:
	if ContentLoader.get_scenarios_for_track(current_track_path).size() == 0:
		send_message("No scenario found! Please create a scenario in the scenario editor to enable track exporting.")
		return

	save_world(false)
	var mod_name = current_track_path.get_file().get_basename()
	var export_path = "user://addons/"
	send_message(ExportTrack.export_editor_track(mod_name, export_path))
	return


func _on_ExportTrack_pressed() -> void:
	export_mod()


func _on_TestTrack_pressed() -> void:
	test_track()


func send_message(message: String) -> void:
	if !$EditorHUD/Message/RichTextLabel.text.empty():
		return
	Logger.log("Editor sends message: " + message)
	$EditorHUD/Message/RichTextLabel.text = message
	$EditorHUD/Message.show()


func _on_MessageClose_pressed() -> void:
	$EditorHUD/Message/RichTextLabel.text = ""
	$EditorHUD/Message.hide()
	if not has_node("World"):
		LoadingScreen.load_main_menu()


func duplicate_selected_object() -> void:
	Logger.vlog(selected_object_type)
	if selected_object_type != "Building":
		return
	else:
		Logger.vlog("Duplicating " + selected_object.name + " ...")
		var new_object: Node = selected_object.duplicate()
		Root.name_node_appropriate(new_object, new_object.name, $World/Buildings)
		$World/Buildings.add_child(new_object)
		new_object.set_owner($World)
		set_selected_object(new_object)


func add_signal_to_selected_rail() -> void:
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var signal_res: PackedScene = preload("res://Data/Modules/Signal.tscn")
	var signal_ins: Node = signal_res.instance()
	Root.name_node_appropriate(signal_ins, "Signal", $World/Signals)
	$World/Signals.add_child(signal_ins)
	signal_ins.set_owner($World)
	signal_ins.attached_rail = selected_object.name
	signal_ins.set_to_rail()
	set_selected_object(signal_ins)


func add_station_to_selected_rail() -> void:
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var station_res: PackedScene = preload("res://Data/Modules/Station.tscn")
	var station_ins: Node = station_res.instance()
	Root.name_node_appropriate(station_ins, "Station", $World/Signals)
	$World/Signals.add_child(station_ins)
	station_ins.set_owner($World)
	station_ins.attached_rail = selected_object.name
	station_ins.set_to_rail()
	set_selected_object(station_ins)


func add_speed_limit_to_selected_rail() -> void:
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var speed_limit_res: PackedScene = preload("res://Data/Modules/SpeedLimit_Lf7.tscn")
	var speed_limit_ins: Node = speed_limit_res.instance()
	Root.name_node_appropriate(speed_limit_ins, "SpeedLimit", $World/Signals)
	$World/Signals.add_child(speed_limit_ins)
	speed_limit_ins.set_owner($World)
	speed_limit_ins.attached_rail = selected_object.name
	speed_limit_ins.set_to_rail()
	set_selected_object(speed_limit_ins)


func add_warn_speed_limit_to_selected_rail() -> void:
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var war_speed_limit_res: PackedScene = preload("res://Data/Modules/WarnSpeedLimit_Lf6.tscn")
	var warn_speed_limit_ins: Node = war_speed_limit_res.instance()
	Root.name_node_appropriate(warn_speed_limit_ins, "SpeedLimit", $World/Signals)
	$World/Signals.add_child(warn_speed_limit_ins)
	warn_speed_limit_ins.set_owner($World)
	warn_speed_limit_ins.attached_rail = selected_object.name
	warn_speed_limit_ins.set_to_rail()
	set_selected_object(warn_speed_limit_ins)


func add_contact_point_to_selected_rail() -> void:
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var contact_point_res: PackedScene = preload("res://Data/Modules/ContactPoint.tscn")
	var contact_point_ins: Node = contact_point_res.instance()
	Root.name_node_appropriate(contact_point_ins, "ContactPoint", $World/Signals)
	$World/Signals.add_child(contact_point_ins)
	contact_point_ins.set_owner($World)
	contact_point_ins.attached_rail = selected_object.name
	contact_point_ins.set_to_rail()
	set_selected_object(contact_point_ins)


func get_all_station_node_names_in_world() -> Array:
	var station_node_names := []
	for signal_node in $World/Signals.get_children():
		if signal_node.type == "Station":
			station_node_names.append(signal_node.name)
	return station_node_names


func jump_to_station(station_node_name: String) -> void:
	var station_node: Node = $World/Signals.get_node(station_node_name)
	if station_node == null:
		Logger.err("Station not found:" + station_node_name, self)
		return
	camera.transform = station_node.transform.translated(Vector3(0, 5, 0))
	camera.rotation.y -= (0.5 * PI)
	camera.load_from_transform(camera.transform)


func get_imported_cache_file_path_of_import_file(file_path: String) -> Array:
	var config := ConfigFile.new()
	if config.load(file_path) != OK:
		Logger.warn("No cached import file found (%s)" % file_path, self)
		return []
	var return_values := []
	var value = config.get_value("remap", "path")
	if value == "" || value == null:
		return_values.append(config.get_value("remap", "path.s3tc"))
		return_values.append(config.get_value("remap", "path.etc2"))
		Logger.warn("No cached import file found (%s)" % file_path, self)
		return []
	return_values.append(value)
	return return_values


func get_children_of_type_recursive(node: Node, type) -> Array:
	var children = []
	var stack = [node]

	if node is type:
		children.append(node)

	while not stack.empty():
		var parent = stack.pop_front()
		for child in parent.get_children():
			if child is type:
				children.append(child)
			stack.append(child)

	return children


func set_current_track_path(path: String) -> void:
	current_track_path = path.get_base_dir()
	current_track_name = path.get_file()


func _on_Pause_save_requested() -> void:
	save_world(false)


func _on_world_origin_shifted(delta: Vector3):
	$World/Buildings.translation += delta


func _on_object_added(object: Spatial, position: Vector3) -> void:
	world.get_node("Buildings").add_child(object)
	object.global_translation = position
	object.set_owner(world)

	var old_script = object.get_script()
	object.set_script(preload("res://Data/Scripts/aabb_to_collider.gd"))
	object.target = NodePath(".")
	object.generate_collider()
	object.set_script(old_script)

	yield(get_tree(), "idle_frame")
	set_selected_object(object)
