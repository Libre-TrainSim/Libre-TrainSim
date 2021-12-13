extends Spatial

var editor_directory: String = ""
var content: ModContentDefinition
var authors: Authors
## Track path without file extension
var current_track_path := "" setget set_current_track_path
## Track name is the string after the last /
var current_track_name := ""
## Base path of the mod that contains the world
var mod_path := ""

var selected_object: Node = null
var selected_object_type: String = ""

var rail_res: PackedScene = preload("res://Data/Modules/Rail.tscn")


onready var camera := $Camera as EditorCamera


func _ready() -> void:
	if !load_world():
		return


func _enter_tree() -> void:
	Root.Editor = true


func _exit_tree() -> void:
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
	var plane := Plane(Vector3(0,1,0), selected_object.startpos.y)
	var mouse_pos_3d: Vector3 = plane.intersects_ray(camera.project_ray_origin(mouse_pos), camera.project_ray_normal(mouse_pos))
	if mouse_pos_3d != null:
		selected_object.calculate_from_start_end(mouse_pos_3d)  # update rail
		provide_settings_for_selected_object()  # update ui

	# wait for update of overlapping areas, else we can never un-snap
	# yes, this really needs idle_frame, won't work otherwise
	yield(get_tree(), "idle_frame")

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
		var startrot: float = selected_object.startrot
		var endrot: float = selected_object.endrot
		var snap_rot: float
		var snap_pos: Vector3
		if snapped_start:
			snap_rot = snapped_object.startrot
			snap_pos = snapped_object.startpos
		else:
			snap_rot = snapped_object.endrot
			snap_pos = snapped_object.endpos

		if Math.angle_distance_deg(endrot, snap_rot) < 1:
			# angles snapped correctly, we can leave this as is :)
			pass
		elif Math.angle_distance_deg(startrot, snap_rot) < 1:
			if _local_x_distance(startrot, selected_object.startpos, snap_pos) < 20:
				return
			if not $EditorHUD/SnapDialog.is_connected("confirmed", self, "_snap_simple_connector"):
				$EditorHUD/SnapDialog.dialog_text = tr("EDITOR_SNAP_CONNECTOR")
				$EditorHUD/SnapDialog.popup_centered()
				_last_connected_signal = "_snap_simple_connector"
				$EditorHUD/SnapDialog.connect("confirmed", self, "_snap_simple_connector", [snap_pos, snap_rot], CONNECT_ONESHOT)
		elif abs(Math.angle_distance_deg(startrot, snap_rot) - 90) < 1:
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
	var dir := Vector3(1,0,0).rotated(Vector3.UP, deg2rad(rot)).normalized()
	return dir.dot(b - a)


func _local_z_distance(rot: float, a: Vector3, b: Vector3) -> float:
	var dir := Vector3(0,0,1).rotated(Vector3.UP, deg2rad(rot)).normalized()
	return dir.dot(b - a)


func _snap_90deg_connector(snap_pos: Vector3, snap_rot: float) -> void:
	var startpos: Vector3 = selected_object.startpos
	var startrot: float = selected_object.startrot

	var start_dir := Vector3(1,0,0).rotated(Vector3.UP, deg2rad(selected_object.startrot)).normalized()
	var ortho_dir := Vector3(0,0,1).rotated(Vector3.UP, deg2rad(selected_object.startrot)).normalized()

	var x_length: float = abs(start_dir.dot(snap_pos - startpos))
	var y_length: float = ortho_dir.dot(snap_pos - startpos)
	var y_sign: float = sign(y_length)
	y_length = abs(y_length)

	if abs(x_length - y_length) < 1:
		var new_end: Vector3 = startpos + Vector3(x_length, 0, y_sign * y_length).rotated(Vector3.UP, deg2rad(startrot))
		selected_object.calculate_from_start_end(new_end)

	elif x_length > y_length:
		selected_object.radius = 0
		selected_object.length = x_length - y_length
		selected_object.update()

		var rail2: Node = _spawn_rail()
		rail2.translation = selected_object.endpos
		rail2.startpos = selected_object.endpos
		rail2.rotation_degrees.y = selected_object.endrot
		rail2.startrot = selected_object.endrot
		var new_end = rail2.startpos + Vector3(y_length, 0, y_sign * y_length).rotated(Vector3.UP, deg2rad(startrot))
		rail2.calculate_from_start_end(new_end)

	else:
		var new_end: Vector3 = startpos + Vector3(x_length, 0, y_sign * x_length).rotated(Vector3.UP, deg2rad(startrot))
		selected_object.calculate_from_start_end(new_end)

		var rail2: Node = _spawn_rail()
		rail2.translation = selected_object.endpos
		rail2.startpos = selected_object.endpos
		rail2.rotation_degrees.y = selected_object.endrot
		rail2.startrot = selected_object.endrot
		rail2.radius = 0
		rail2.length = y_length - x_length
		rail2.update()


func _snap_simple_connector(snap_pos: Vector3, snap_rot: float) -> void:
	# can easily connect with 2 segments
	# this is basically the old rail connector for switches
	var rail1_end: Vector3 = 0.5 * (selected_object.startpos + snap_pos)
	selected_object.calculate_from_start_end(rail1_end)

	var rail2: Node = _spawn_rail()
	rail2.translation = rail1_end
	rail2.startpos = rail1_end
	rail2.rotation_degrees.y = selected_object.endrot
	rail2.startrot = selected_object.endrot
	rail2.calculate_from_start_end(snap_pos)

	assert(Math.angle_distance_deg(rail2.endrot, snap_rot) < 1)

	drag_mode = false


func _snap_complex_connector(snap_pos: Vector3, snap_rot: float) -> void:
	# TODO: I don't know how to do it yet
	pass


func select_object_under_mouse() -> void:
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

	while !(obj_to_select is WorldObject or obj_to_select is MeshInstance):
		Logger.vlog("Trying to find object", obj_to_select)
		obj_to_select = obj_to_select.get_parent_spatial()
		if obj_to_select == self or obj_to_select == null:
			Logger.vlog("No object found", result["collider"])
			clear_selected_object()
			return

	if get_type_of_object(obj_to_select) == "Rail" and result.collider.name == "Ending":
		begin_drag_mode()

	set_selected_object(obj_to_select)
	provide_settings_for_selected_object()
	Logger.vlog("selected!", obj_to_select)


func clear_selected_object() -> void:
	Logger.vlog("Deselect object", selected_object)
	if is_instance_valid(selected_object):
		var vis = get_children_of_type_recursive(selected_object, VisualInstance)
		for vi in vis:
			vi.set_layer_mask_bit(1, false)

		if selected_object_type == "Building":
			selected_object.get_child(1).queue_free()
			$EditorHUD.hide_current_object_transform()
		if selected_object_type == "Rail":
			$EditorHUD.hide_current_object_transform()
			for child in selected_object.get_children():
				if child.is_in_group("Gizmo"):
					child.queue_free()

	selected_object = null
	selected_object_type = ""
	$EditorHUD.clear_current_object_name()


func get_type_of_object(object: Node) -> String:
	if object is MeshInstance:
		return "Building"
	if object.is_in_group("Rail"):
		return "Rail"
	if object.is_in_group("Signal"):
		return "Signal"
	else:
		Logger.warn("Unknown object type encountered!", object)
		return "Unknown"


func provide_settings_for_selected_object() -> void:
	if selected_object_type == "Rail":
		$EditorHUD/Settings/TabContainer/RailAttachments.update_selected_rail(selected_object)
		$EditorHUD/Settings/TabContainer/RailBuilder.update_selected_rail(selected_object)
		$EditorHUD.ensure_rail_settings()
	else:
		$EditorHUD/Settings/TabContainer/RailAttachments.update_selected_rail(null)
		$EditorHUD/Settings/TabContainer/RailBuilder.update_selected_rail(null)
	if selected_object_type == "Building":
		$EditorHUD/Settings/TabContainer/BuildingSettings.set_mesh(selected_object)
		$EditorHUD.show_building_settings()
	if selected_object_type == "Signal":
		$EditorHUD/Settings/TabContainer/RailLogic.set_rail_logic(selected_object)
		$EditorHUD.show_signal_settings()
	$EditorHUD.update_ShowSettingsButton()


## Should be used, if world is loaded into scene.
func load_world() -> bool:
	editor_directory = jSaveManager.get_setting("editor_directory_path", "user://editor/")
	var path := current_track_path + ".tscn"
	var world_resource: PackedScene = load(path)
	if world_resource == null:
		send_message("World data could not be loaded! Is your .tscn file corrupt?\nIs every resource available?")
		return false

	var world: Node = world_resource.instance()
	world.FileName = current_track_name
	world.get_node("jSaveModule").save_path = current_track_path + ".save"
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

	$World.chunk_manager.save_and_unload_all_chunks()

	var packed_scene = PackedScene.new()
	var result = packed_scene.pack($World)
	if result == OK:
		var error = ResourceSaver.save(current_track_path + ".tscn", packed_scene)
		if error != OK:
			send_message("An error occurred while saving the scene to disk.")
			return

	$EditorHUD/Settings/TabContainer/Configuration.save_everything()
	$World/jSaveModule.write_to_disk()

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
		if selected_object.manualMoving:
			selected_object.add_child(preload("res://Editor/Modules/Gizmo.tscn").instance())
			$EditorHUD.show_current_object_transform()

	provide_settings_for_selected_object()


func _spawn_rail() -> Node:
	var rail_instance: Node = rail_res.instance()
	rail_instance.name = Root.name_node_appropriate(rail_instance, "Rail", $World/Rails)
	$World/Rails.add_child(rail_instance)
	rail_instance.set_owner($World)
	#rail_instance._update()

	if rail_instance.overheadLine:
		_spawn_poles_for_rail(rail_instance)

	return rail_instance


func _spawn_poles_for_rail(rail: Node) -> void:
	var track_object = preload("res://Data/Modules/TrackObjects.tscn").instance()
	track_object.sides = 2
	track_object.rows = 1
	track_object.wholeRail = true
	track_object.placeLast = true
	track_object.objectPath = "res://Resources/Objects/Pole1.obj"
	track_object.materialPaths = [ "res://Resources/Materials/Beton.tres", "res://Resources/Materials/Metal_Green.tres", "res://Resources/Materials/Metal.tres", "res://Resources/Materials/Metal_Brown.tres" ]
	track_object.attached_rail = rail.name
	track_object.length = rail.length
	track_object.distanceLength = 50
	track_object.rotationObjects = -90.0
	track_object.name = rail.name + " Poles"
	track_object.description = "Poles"

	rail.trackObjects.append(track_object)

	$World/TrackObjects.add_child(track_object)
	track_object.set_owner($World/TrackObjects)

	track_object.update()
	rail.update()


func add_rail() -> void:
	var rail_instance: Node = _spawn_rail()
	rail_instance.translation = get_current_ground_position()
	set_selected_object(rail_instance)


func get_current_ground_position() -> Vector3:
	var position: Vector3 = camera.translation
	position.y = $World.get_terrain_height_at(Vector2(position.x, position.z))
	return position


func add_object(complete_path: String) -> void:
	var position: Vector3 = get_current_ground_position()
	var obj_res: Mesh = load(complete_path)
	var mesh_instance := MeshInstance.new()
	mesh_instance.mesh = obj_res
	var mesh_name: String = complete_path.get_file().get_basename() + "_"
	mesh_instance.name = Root.name_node_appropriate(mesh_instance, mesh_name, $World/Buildings)
	mesh_instance.translation = position
	$World/Buildings.add_child(mesh_instance)
	mesh_instance.set_owner($World)
	mesh_instance.add_child(preload("res://Data/Modules/SelectCollider.tscn").instance())
	set_selected_object(mesh_instance)


func test_track_pck() -> void:
	if OS.has_feature("editor"):
		send_message("Can't test tracks if runs Libre TrainSim using the Godot Editor. " \
				+ "Please use a build of Libre TrainSim to test tracks. ")
		return
	export_mod()

	if !ProjectSettings.load_resource_pack("user://addons/%s/%s.pck" % [content.unique_name, content.unique_name]):
		Logger.warn("Can't load content pack!", self)
		send_message("Can't load content pack!")
		return
	ContentLoader.append_content_to_global_repo(content)
	Root.start_menu_in_play_menu = true
	LoadingScreen.load_main_menu()


func export_mod() -> void:
	save_world()
	var mod_name = content.unique_name
	var export_path = "user://addons/".plus_file(mod_name)

	var dir := Directory.new()
	if dir.open("user://") != OK:
		Logger.err("Can't open user directory.", self)
		return
	if dir.make_dir_recursive(export_path) != OK:
		Logger.warn("Can't create mod folder.", self)
	if ResourceSaver.save("user://addons/%s/content.tres" % content.unique_name, content) != OK:
		Logger.err("Can't save content.tres. Aborting export.", self)
		send_message("Can't save content.tres. Aborting export.")
		return

	dir.change_dir(export_path)

	var packer = PCKPacker.new()
	var ok = packer.pck_start(export_path.plus_file(mod_name) + ".pck")
	if ok != OK:
		Logger.err("Error creating %s!" % export_path.plus_file(mod_name) + ".pck", self)
		send_message("Error creating %s!" % export_path.plus_file(mod_name) + ".pck")
		return

	var files = get_files_in_directory(mod_path)
	for file in files:
		ok = packer.add_file(file.replace(editor_directory, "res://Mods/"), file)
		if ok != OK:
			Logger.err("Could not add file %s to pck!" % file, self)

	ok = packer.flush(true)
	if ok != OK:
		send_message("Could not flush pck!")
		Logger.err("Could not flush pck!", self)
	send_message("Track successfully exported.")


func get_files_in_directory(path: String) -> Array:
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			files.append_array(get_files_in_directory(path.plus_file(file_name)))
		else:
			files.append(path.plus_file(file_name))
		file_name = dir.get_next()
	return files



func _on_ExportTrack_pressed() -> void:
	export_mod()


func _on_TestTrack_pressed() -> void:
	test_track_pck()


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
	camera.rotation_degrees.y -= 90
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
	current_track_path = path
	current_track_name = path.get_file()
