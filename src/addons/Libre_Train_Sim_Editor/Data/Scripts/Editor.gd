extends Spatial

onready var camera = get_node("FreeCamera")
var editor_directory = ""

var selected_object = null
var selected_object_type = ""



# Called when the node enters the scene tree for the first time.
func _ready():
	load_world()
	pass # Replace with function body.

var bouncing_timer = 0
func _process(delta):

	
	## Bouncing Effect at selected object
	if is_instance_valid(selected_object):
		bouncing_timer += delta
		if selected_object_type == "Building":
			var bounce_factor = 1 + 0.02 * sin(bouncing_timer*5.0) + 0.02
			selected_object.scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
		if selected_object_type == "Rail":
			var bounce_factor = 1 + 0.2 * sin(bouncing_timer*5.0) + 0.2
			selected_object.get_node("Ending").scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
			selected_object.get_node("Mid").scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
			selected_object.get_node("Beginning").scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
		if selected_object_type == "Signal":
			var bounce_factor = 1 + 0.1 * sin(bouncing_timer*5.0)
			selected_object.scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
	else:
		clear_selected_object()
		

func _enter_tree():
	Root.Editor = true

func _exit_tree():
	Root.Editor = false

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed == false and not $EditorHUD.mouse_over_ui:
		select_object_under_mouse()
	
	if Input.is_action_just_pressed("save"):
		save_world()
	
	if Input.is_action_just_pressed("delete"):
		delete_selected_object()
	
	if Input.is_action_just_pressed("ui_accept") and $EditorHUD/Message.visible:
		_on_MessageClose_pressed()



func select_object_under_mouse():
	
	var ray_length = 1000
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	var space_state = get_world().get_direct_space_state()
	# use global coordinates, not local to node
	var result = space_state.intersect_ray( from, to)
	if result.has("collider"):
		set_selected_object(result["collider"].get_parent())
		provide_settings_for_selected_object()
		print("selected!")
		

func clear_selected_object():
	# Reset scale of current object because of editor "bouncing"
	if is_instance_valid(selected_object):
		if selected_object_type == "Building":
			selected_object.scale = Vector3(1,1,1)
			selected_object.get_node("SelectCollider").show()
			selected_object.get_child(1).queue_free()
			$EditorHUD.hide_current_object_transform()
		if selected_object_type == "Rail":
			selected_object.get_node("Ending").scale = Vector3(1,1,1)
			selected_object.get_node("Mid").scale = Vector3(1,1,1)
			selected_object.get_node("Beginning").scale = Vector3(1,1,1)
			$EditorHUD.hide_current_object_transform()
			for child in selected_object.get_children():
				if child.is_in_group("Gizmo"):
					child.queue_free()
		if selected_object_type == "Signal":
			selected_object.scale = Vector3(1,1,1)
			
	
	selected_object = null
	selected_object_type = ""
	$EditorHUD.clear_current_object_name()

func get_type_of_object(object):
	if object is MeshInstance:
		return "Building"
	if object.is_in_group("Rail"):
		return "Rail"
	if object.is_in_group("Signal"):
		return "Signal"
	else:
		return "Unknown"

func provide_settings_for_selected_object():
	if selected_object_type == "Rail":
		$EditorHUD/Settings/TabContainer/RailAttachments.update_selected_rail(selected_object)
		$EditorHUD/Settings/TabContainer/RailBuilder.update_selected_rail(selected_object)
		$EditorHUD.ensure_rail_settings()
	if selected_object_type == "Building":
		$EditorHUD/Settings/TabContainer/BuildingSettings.set_mesh(selected_object)
		$EditorHUD.show_building_settings()
	if selected_object_type == "Signal":
		$EditorHUD/Settings/TabContainer/RailLogic.set_rail_logic(selected_object)
		$EditorHUD.show_signal_settings()
	$EditorHUD.update_ShowSettingsButton()

## Should be used, if world is loaded into scene.
func load_world():
	editor_directory = jSaveManager.get_setting("editor_directory_path")
	var world_resource = load(editor_directory + "Worlds/" + Root.current_editor_track + "/" + Root.current_editor_track + ".tscn")
	if world_resource == null:
		send_message("World data could not be loaded! Is your .tscn file corrupt?\nIs every resource available?")
		return
	var world = world_resource.instance()
	world.owner = self
	world.FileName = Root.current_editor_track
	add_child(world)

	$EditorHUD/Settings/TabContainer/RailBuilder.world = $World
	$EditorHUD/Settings/TabContainer/RailAttachments.world = $World
	$EditorHUD/Settings/TabContainer/Configuration.world = $World

	## Load Camera Position
	var last_editor_camera_transforms = jSaveManager.get_value("last_editor_camera_transforms", {})
	if last_editor_camera_transforms.has(Root.current_editor_track):
		$FreeCamera.transform = last_editor_camera_transforms[Root.current_editor_track]

	## Add Colliding Boxes to Buildings:
	for building in $World/Buildings.get_children():
		building.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SelectCollider.tscn").instance())
	for signal_ins in $World/Signals.get_children():
#		if signal_ins.type == "Signal":
		signal_ins.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SelectCollider.tscn").instance())
	
	$World/Grass.hide()
	generate_grass_panes()
	 
	
func save_world():
	## Save Camera Position
	var last_editor_camera_transforms = jSaveManager.get_value("last_editor_camera_transforms", {})
	last_editor_camera_transforms[Root.current_editor_track] = $FreeCamera.transform
	jSaveManager.save_value("last_editor_camera_transforms", last_editor_camera_transforms)

	var packed_scene = PackedScene.new()
	var result = packed_scene.pack($World)
	if result == OK:
		var error = ResourceSaver.save(editor_directory + "Worlds/" + Root.current_editor_track + "/" + Root.current_editor_track + ".tscn", packed_scene) 
		if error != OK:
			send_message("An error occurred while saving the scene to disk.")
			return
	
	$EditorHUD/Settings/TabContainer/Configuration.save_everything()
	send_message("World successfully saved!")
	
	generate_grass_panes()



func _on_SaveWorldButton_pressed():
	save_world()

func rename_selected_object(new_name):
	Root.name_node_appropriate(selected_object, new_name, selected_object.get_parent())
	$EditorHUD.set_current_object_name(selected_object.name)
	provide_settings_for_selected_object()

func delete_selected_object():
	selected_object.queue_free()
	clear_selected_object()
	
func get_rail(name : String):
	return $World/Rails.get_node_or_null(name)
	
func set_selected_object(object):
	clear_selected_object()
	
	selected_object = object
	$EditorHUD.set_current_object_name(selected_object.name)
	selected_object_type = get_type_of_object(selected_object)
	
	if selected_object_type == "Building":
		selected_object.get_node("SelectCollider").hide()
		selected_object.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Gizmo.tscn").instance())
		$EditorHUD.show_current_object_transform()
	if selected_object_type == "Rail":
		if selected_object.manualMoving:
			selected_object.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Gizmo.tscn").instance())
			$EditorHUD.show_current_object_transform()
	
	provide_settings_for_selected_object()

func add_rail():
	var position = get_current_ground_position()
	var rail_res = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
	var rail_instance = rail_res.instance()
	rail_instance.name = Root.name_node_appropriate(rail_instance, "Rail", $World/Rails)
	rail_instance.translation = position
	$World/Rails.add_child(rail_instance)
	rail_instance.set_owner($World)
#	rail_instance._update()
	set_selected_object(rail_instance)

func get_current_ground_position() -> Vector3:
	var position = $FreeCamera.translation 
	position.y = $World.get_terrain_height_at(Vector2(position.x, position.z))
	return position

func add_object(complete_path : String):
	var position = get_current_ground_position()
	var obj_res = load(complete_path)
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = obj_res
	var mesh_name = complete_path.get_file().get_basename() + "_"
	mesh_instance.name = Root.name_node_appropriate(mesh_instance, mesh_name, $World/Buildings)
	mesh_instance.translation = position
	$World/Buildings.add_child(mesh_instance)
	mesh_instance.set_owner($World)
	mesh_instance.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SelectCollider.tscn").instance())
	set_selected_object(mesh_instance)
	


func _on_FreeCamera_single_rightclick():
	if not $EditorHUD.mouse_over_ui:
		clear_selected_object()

func test_track_pck():
	var dir = Directory.new()
	dir.make_dir_recursive(editor_directory + "/.cache/")
	var pck_path = editor_directory + "/.cache/" + Root.current_editor_track + ".pck"
	var packer = PCKPacker.new()
	packer.pck_start(pck_path)
	
	packer.add_file("res://Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".tscn", editor_directory + "/Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".tscn")
	packer.add_file("res://Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".save", editor_directory + "/Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".save")
	packer.add_file("res://Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+"-scenarios.cfg", editor_directory + "/Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+"-scenarios.cfg")
	packer.flush()

	if ProjectSettings.load_resource_pack(pck_path, true):
		print("Loading Content Pack "+ pck_path+" successfully finished")
	Root.start_menu_in_play_menu = true
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")

func export_track_pck(export_path):
	var track_name = Root.current_editor_track
	export_path += "/" + track_name + ".pck"
	$World.force_load_all_chunks()
	var packer = PCKPacker.new()
	packer.pck_start(export_path)
	
	## Handle dependencies
	var dependencies_raw = ResourceLoader.get_dependencies(editor_directory + "/Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".tscn")

	$World/jSaveModuleScenarios.set_save_path(editor_directory + "/Worlds/" + track_name + "/" + track_name + "-scenarios.cfg")
	var scenario_data = $World/jSaveModuleScenarios.get_value("scenario_data")
	for scenario in scenario_data:
		for train in scenario_data[scenario]["Trains"]:
			if not scenario_data[scenario]["Trains"][train].has("approachAnnouncePath"): continue
			for path in scenario_data[scenario]["Trains"][train]["approachAnnouncePath"]:
				dependencies_raw.append(path)
			for path in scenario_data[scenario]["Trains"][train]["arrivalAnnouncePath"]:
				dependencies_raw.append(path)
			for path in scenario_data[scenario]["Trains"][train]["departureAnnouncePath"]:
				dependencies_raw.append(path)
				
		
	
	
	dependencies_raw = jEssentials.remove_duplicates(dependencies_raw)
	var dependencies_export = []
	print("Dependencies: " + String(dependencies_raw))
	for dependence in dependencies_raw:
		if not dependence.begins_with("res://addons/") and ResourceLoader.exists(dependence):
			dependencies_export.append(dependence)
	for dependence in dependencies_export:
		print(dependence)
		packer.add_file(dependence, dependence)
	
	$World.unload_and_save_all_chunks()
	save_world()
	
	packer.add_file("res://Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".tscn", editor_directory + "/Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".tscn")
	packer.add_file("res://Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".save", editor_directory + "/Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+".save")
	packer.add_file("res://Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+"-scenarios.cfg", editor_directory + "/Worlds/"+Root.current_editor_track+"/"+Root.current_editor_track+"-scenarios.cfg")
	packer.add_file("res://Worlds/"+Root.current_editor_track+"/screenshot.png", editor_directory + "/Worlds/"+Root.current_editor_track+"/screenshot.png")
	
	packer.flush()
	send_message("Track successfully exported to: " + export_path)
	$EditorHUD/ExportDialog.hide()
	
	save_world()
	
	
func _on_ExportTrack_pressed():
	$EditorHUD/ExportDialog.show_up(editor_directory)
	
	



func _on_TestTrack_pressed():
	test_track_pck()


func _on_ExportDialog_export_confirmed(path):
	export_track_pck(path)

func send_message(message):
	print("Editor sends message: " + message)
	$EditorHUD/Message/RichTextLabel.text = message
	$EditorHUD/Message.show()

func _on_MessageClose_pressed():
	$EditorHUD/Message.hide()
	$EditorHUD._on_dialog_closed()
	if not has_node("World"):
		get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")

func duplicate_selected_object():
	print(selected_object_type)
	if selected_object_type != "Building":
		return
	else:
		print("Duplicating " + selected_object.name + " ...")
		var new_object = selected_object.duplicate()
		Root.name_node_appropriate(new_object, new_object.name, $World/Buildings)
		$World/Buildings.add_child(new_object)
		new_object.set_owner($World)
		set_selected_object(new_object)


func add_signal_to_selected_rail():
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var signal_res = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Signal.tscn")
	var signal_ins = signal_res.instance()
	Root.name_node_appropriate(signal_ins, "Signal", $World/Signals)
	$World/Signals.add_child(signal_ins)
	signal_ins.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SelectCollider.tscn").instance())
	signal_ins.set_owner($World)
	signal_ins.attachedRail = selected_object.name
	signal_ins.setToRail(true)
	set_selected_object(signal_ins)
	
func add_station_to_selected_rail():
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var station_res = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Station.tscn")
	var station_ins = station_res.instance()
	Root.name_node_appropriate(station_ins, "Station", $World/Signals)
	$World/Signals.add_child(station_ins)
	station_ins.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SelectCollider.tscn").instance())
	station_ins.set_owner($World)
	station_ins.attachedRail = selected_object.name
	station_ins.setToRail(true)
	set_selected_object(station_ins)

func add_speed_limit_to_selected_rail():
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var speed_limit_res = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SpeedLimit.tscn")
	var speed_limit_ins = speed_limit_res.instance()
	Root.name_node_appropriate(speed_limit_ins, "SpeedLimit", $World/Signals)
	$World/Signals.add_child(speed_limit_ins)
	speed_limit_ins.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SelectCollider.tscn").instance())
	speed_limit_ins.set_owner($World)
	speed_limit_ins.attachedRail = selected_object.name
	speed_limit_ins.setToRail(true)
	set_selected_object(speed_limit_ins)

func add_warn_speed_limit_to_selected_rail():
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var war_speed_limit_res = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/WarnSpeedLimit.tscn")
	var warn_speed_limit_ins = war_speed_limit_res.instance()
	Root.name_node_appropriate(warn_speed_limit_ins, "SpeedLimit", $World/Signals)
	$World/Signals.add_child(warn_speed_limit_ins)
	warn_speed_limit_ins.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SelectCollider.tscn").instance())
	warn_speed_limit_ins.set_owner($World)
	warn_speed_limit_ins.attachedRail = selected_object.name
	warn_speed_limit_ins.setToRail(true)
	set_selected_object(warn_speed_limit_ins)

func add_contact_point_to_selected_rail():
	if selected_object_type != "Rail":
		send_message("Error, you need to select a Rail first, before you add a Rail Logic element")
		return
	var contact_point_res = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/ContactPoint.tscn")
	var contact_point_ins = contact_point_res.instance()
	Root.name_node_appropriate(contact_point_ins, "ContactPoint", $World/Signals)
	$World/Signals.add_child(contact_point_ins)
	contact_point_ins.add_child(preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/SelectCollider.tscn").instance())
	contact_point_ins.set_owner($World)
	contact_point_ins.attachedRail = selected_object.name
	contact_point_ins.setToRail(true)
	set_selected_object(contact_point_ins)


func get_all_station_node_names_in_world():
	var station_node_names = []
	for signal_node in $World/Signals.get_children():
		if signal_node.type == "Station":
			station_node_names.append(signal_node.name)
	return station_node_names


func jump_to_station(station_node_name):
	var station_node = $World/Signals.get_node(station_node_name)
	if station_node == null:
		print_debug("Station not found:" + station_node_name)
	$FreeCamera.transform = station_node.transform.translated(Vector3(0, 5, 0))
	$FreeCamera.rotation_degrees.y -= 90

var all_chunks = []
var GRASS_HEIGHT = -0.5
func generate_grass_panes():
	for child in $Landscape.get_children():
		child.queue_free()
	var all_chunks_new = $World.get_all_chunks_vector3()
	if all_chunks_new.size() == all_chunks.size():
		return
	all_chunks = all_chunks_new
	var mesh_resource = preload("res://Resources/Basic/Objects/grass_square.obj")
	for chunk in all_chunks:
		var mesh_instance = MeshInstance.new()
		mesh_instance.mesh = mesh_resource
		mesh_instance.set_surface_material(0, preload("res://Resources/Basic/Materials/Grass.tres"))
		mesh_instance.translation = (chunk * 1000) + (Vector3(0, GRASS_HEIGHT, 0))
		$Landscape.add_child(mesh_instance)
		mesh_instance.owner = self
	
		
