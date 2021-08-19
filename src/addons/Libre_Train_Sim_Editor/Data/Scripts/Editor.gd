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
		var bounce_factor = 1 + 0.02 * sin(bouncing_timer*5.0) + 0.02
		if selected_object_type == "Building":
			selected_object.scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
		if selected_object_type == "Rail":
			bounce_factor = 1 + 0.2 * sin(bouncing_timer*5.0) + 0.2
			selected_object.get_node("Ending").scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
			selected_object.get_node("Mid").scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
			selected_object.get_node("Beginning").scale = Vector3(bounce_factor, bounce_factor, bounce_factor)
	else:
		clear_selected_object()
		

func _enter_tree():
	Root.Editor = true

func _exit_tree():
	Root.Editor = false

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed == false:
		select_object_under_mouse()
	
	if Input.is_action_just_pressed("save"):
		save_world()
	
	if Input.is_action_just_pressed("delete"):
		delete_selected_object()



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
			
	
	selected_object = null
	selected_object_type = ""
	$EditorHUD.clear_current_object_name()

func get_type_of_object(object):
	if object is MeshInstance:
		return "Building"
	if object.is_in_group("Rail"):
		return "Rail"
	else:
		return "Unknown"

func provide_settings_for_selected_object():
	if selected_object_type == "Rail":
		$EditorHUD/Settings/TabContainer/RailAttachments.update_selected_rail(selected_object)
		$EditorHUD/Settings/TabContainer/RailBuilder.update_selected_rail(selected_object)
	if selected_object_type == "Building":
		$EditorHUD/Settings/TabContainer/BuildingSettings.set_mesh(selected_object)

## Should be used, if world is loaded into scene.
func load_world():
	editor_directory = jSaveManager.get_setting("editor_directory_path")
	var world_resource = load(editor_directory + "Worlds/" + Root.current_editor_track + "/" + Root.current_editor_track + ".tscn")
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
			push_error("An error occurred while saving the scene to disk.")



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
	clear_selected_object()
