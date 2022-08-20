extends Control

var world: Node
var currentRail: Node
var copyRail
var copyTO
var copyTOArray: Array
var currentTO: Node
var editor_selection # Editor Selection
var pluginRoot

var track_object_resource: PackedScene = preload("res://Data/Modules/TrackObjects.tscn")


func _process(_delta: float) -> void:
	$Tab/TrackObjects/Settings.visible = is_instance_valid(currentTO)


func update_selected_rail(node: Node) -> void:
	if is_instance_valid(node) and node.is_in_group("Rail"):
		currentRail = node
		$CurrentRail/Name.text = node.name
		$Tab.visible = true
		var track_object_name := ""
		if is_instance_valid(currentTO):
			track_object_name = currentTO.description
		else:
			currentTO = null
		update_itemList()
		update_object_tab()
		update_positioning()

		# if jList has description, select this one..
		if $Tab/TrackObjects/jListTrackObjects.has_entry(track_object_name):
			$Tab/TrackObjects/jListTrackObjects.select_entry(track_object_name)
			_on_jListTrackObjects_user_selected_entry(track_object_name)
		else:
			currentTO = null
	else:
		currentRail = null
		$CurrentRail/Name.text = ""
		$Tab.visible = false


func update_itemList() -> void:
	$Tab/TrackObjects/jListTrackObjects.clear()
	var track_objects: Array = currentRail.track_objects
	Logger.vlog(track_objects)
	for x in range(track_objects.size()):
		if track_objects[x].description == null:
			track_objects[x].queue_free()
		else:
			$Tab/TrackObjects/jListTrackObjects.add_entry(track_objects[x].description)


func _on_jListTrackObjects_user_removed_entries(entry_names: Array) -> void:
	Logger.vlog(currentRail.track_objects)
	for entry_name in entry_names:
		var track_object: Node = currentRail.get_track_object(entry_name)
		var track_object_name: String = track_object.name
		track_object.queue_free()
		currentRail.track_objects.erase(track_object)
		Logger.log("TrackObject " + track_object_name + " deleted")
	update_itemList()


func _on_jListTrackObjects_user_added_entry(entry_name: String) -> void:
	Logger.vlog(entry_name)
	var track_object: Node = track_object_resource.instance()
	track_object.description = entry_name
	track_object.name = currentRail.name + " " + entry_name
	track_object.attached_rail = currentRail.name
	track_object.materials = []
	world.get_node("TrackObjects").add_child(track_object)
	track_object.set_owner(world)
	track_object.attach_to_rail(currentRail)
	Logger.log("Created track object " + track_object.name)
	update_object_tab()


func _on_jListTrackObjects_user_renamed_entry(old_name: String, new_name: String) -> void:
	var track_object: Node = currentRail.get_track_object(old_name)
	track_object.description = new_name
	track_object.name = currentRail.name + " " + new_name
	Logger.log("TrackObject renamed from "+ old_name + " to " + new_name)


func _on_jListTrackObjects_user_duplicated_entries(source_entry_names: Array, duplicated_entry_names: Array) -> void:
	for i in range(source_entry_names.size()):
		var source_entry_name: String = source_entry_names[i]
		var duplicated_entry_name: String = duplicated_entry_names[i]
		var source_track_object: Node = currentRail.get_track_object(source_entry_name)
		copy_track_object_to_current_rail(source_track_object, duplicated_entry_name)
		Logger.log("TrackObject " +  source_entry_name + " duplicated.")


func copy_track_object_to_current_rail(source_track_object: Node, new_description: String, mirror: bool = false) -> void:
	if source_track_object == null:
		return
	var new_track_object: Node = track_object_resource.instance()
	var data: Dictionary = source_track_object.get_data()
	new_track_object.set_data(data)
	new_track_object.name = currentRail.name + " " + new_description
	new_track_object.description = new_description
	new_track_object.attached_rail = currentRail.name
	world.get_node("TrackObjects").add_child(new_track_object)
	if mirror:
		new_track_object.rotationObjects = source_track_object.rotationObjects + PI
		if source_track_object.sides == 1:
			new_track_object.sides = 2
		elif source_track_object.sides == 2:
			new_track_object.sides = 1
	new_track_object.set_owner(world)
	new_track_object.update()



func _on_jListTrackObjects_user_selected_entry(entry_name: String):
	currentTO = currentRail.get_track_object(entry_name)
	if currentTO == null:
		$"Tab/TrackObjects/Settings".visible = false
		return
	else:
		$"Tab/TrackObjects/Settings".visible = true
	update_object_tab()
	update_positioning()
	update_Position()


func update_Position() -> void:
	if currentTO == null:
		return
	$Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed = currentTO.wholeRail

	$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = currentTO.on_rail_position
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = currentTO.on_rail_position + currentTO.length
	_on_AssignWholeRail_pressed()


func _on_AssignWholeRail_pressed() -> void:
	$Tab/TrackObjects/Settings/Tab/Position/StartPos.visible = not $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition.visible = not $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed

	$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = currentTO.on_rail_position
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = currentTO.on_rail_position + currentTO.length

	_on_SavePosition_pressed()
	update_current_rail_attachment()



func _on_SavePosition_pressed() -> void:
	if $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed:
		currentTO.wholeRail = true
		return
	if $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value > currentRail.length:
		$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = currentRail.length
	if $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value > currentRail.length:
		$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = currentRail.length
	if $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value < $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value:
		$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	currentTO.wholeRail = false
	currentTO.on_rail_position = $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	currentTO.length = $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value - $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	currentTO.update()
	Logger.log("Position Saved")


func _on_SavePositioning_pressed() -> void:
	currentTO.sides = $"Tab/TrackObjects/Settings/Tab/Object Positioning/OptionButton".selected
	currentTO.distanceLength = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Straight".value
	currentTO.distanceRows = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/LeftRight".value
	currentTO.shift = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Shift".value
	currentTO.spawnRate = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/SpawnRate".value
	currentTO.rows = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rows".value
	currentTO.height = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Height".value
	currentTO.randomLocation = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRandLoc".pressed
	currentTO.randomLocationFactor = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/RandomLocation".value
	currentTO.randomRotation = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRandRot".pressed
	currentTO.randomScale = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRadScal".pressed
	currentTO.randomScaleFactor = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/RandomScale".value
	currentTO.rotationObjects = deg2rad($"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rotation".value)
	currentTO.placeLast = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/PlaceLast".pressed
	currentTO.applySlopeRotation = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/applySlopeRotation".pressed
	Logger.log("Positioning Saved")
	update_current_rail_attachment()


func update_positioning() -> void:
	if currentTO == null:
		return
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/OptionButton".select(currentTO.sides)
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Straight".value = currentTO.distanceLength
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/LeftRight".value = currentTO.distanceRows
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Shift".value = currentTO.shift
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/SpawnRate".value = currentTO.spawnRate
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rows".value = currentTO.rows
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Height".value = currentTO.height
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRandLoc".pressed = currentTO.randomLocation
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/RandomLocation".value = currentTO.randomLocationFactor
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRandRot".pressed = currentTO.randomRotation
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/CheckBoxRadScal".pressed = currentTO.randomScale
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer2/RandomScale".value = currentTO.randomScaleFactor
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rotation".value = rad2deg(currentTO.rotationObjects)
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/PlaceLast".pressed = currentTO.placeLast
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/applySlopeRotation".pressed = currentTO.applySlopeRotation
	Logger.log("Updating...")


func update_current_rail_attachment() -> void: ## UPDATE
	Logger.log("Updating...")
	currentTO.update()
	if currentTO.description.begins_with("Pole"):
		currentRail.update()


func _on_jListTrackObjects_user_copied_entries(entry_names: Array) -> void:
	if entry_names.size() == 0:
		$"Tab/TrackObjects/Settings".visible = false
		return
	copyTOArray = []
	for entry_name in entry_names:
		copyTOArray.append(currentRail.get_track_object(entry_name).duplicate(DUPLICATE_SCRIPTS))
	$"Tab/TrackObjects/Settings".visible = true
	Logger.log("TrackObject(s) copied. Please don't delete the TrackObject(s), until you pasted a copy of it/them.")


func _on_jListTrackObjects_user_pasted_entries(_source_entry_names: Array, _source_jList_id, pasted_entry_names: Array) -> void:
	assert(pasted_entry_names.size() == copyTOArray.size())
	for i in range (pasted_entry_names.size()):
		copy_track_object_to_current_rail(copyTOArray[i], pasted_entry_names[i], $Tab/TrackObjects/MirrorPastedObjects.pressed)


func _on_Randomize_pressed() -> void:
	currentTO.newSeed()
	update_current_rail_attachment() # update


## Object Tab ##################################################################
var requested_content_selector_id: int = -2
# -2: Not requested
# -1: Requested for obj file
# 0 - ...: Requested for Material Path
func _on_PickObject_pressed() -> void:
	if not Root.Editor:
		$FileDialogObjects.popup_centered()
		return
	var editor: Node = find_parent("Editor")
	var content_selector: Node = editor.get_node("EditorHUD/Content_Selector")
	requested_content_selector_id = -1
	content_selector.set_type(content_selector.OBJECTS)
	content_selector.show()


func _on_Content_Selector_resource_selected(complete_path: String) -> void:
	$Tab/TrackObjects/Settings/Tab/Object/BuildingSettings._on_Content_Selector_resource_selected(complete_path)

	if requested_content_selector_id == -2:
		return
	if requested_content_selector_id == -1: # Obj File
		requested_content_selector_id = -2
		if complete_path == "":
			return
		$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = complete_path
		apply_object_tab()
		update_current_rail_attachment() # update


func _on_FileDialog_onject_selected(path: String) -> void:
	$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = path
	update_current_rail_attachment() # update


func update_object_tab() -> void:
	if not is_instance_valid(currentTO):
		$Tab/TrackObjects/Settings/Tab/Object.hide()
		return
	if $Tab/TrackObjects/Settings/Tab.current_tab == 0:
		$Tab/TrackObjects/Settings/Tab/Object.show()
	$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = currentTO.mesh.resource_path
	update_material_list()


func update_material_list() -> void:
	if not is_instance_valid(currentTO.mesh):
		$Tab/TrackObjects/Settings/Tab/Object/BuildingSettings.set_mesh(null)
		return
	var material_array: Array = currentTO.materials
	for i in range(currentTO.mesh.get_surface_material_count()):
		if i < material_array.size() and ResourceLoader.exists(material_array[i]):
			currentTO.mesh.set_surface_material(i, load(material_array[i]))
	$Tab/TrackObjects/Settings/Tab/Object/BuildingSettings.set_mesh(currentTO.mesh)


func apply_object_tab() -> void:
	currentTO.mesh = load($Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text) as Mesh
	update_material_list()
	var material_array: Array = $Tab/TrackObjects/Settings/Tab/Object/BuildingSettings.get_material_array()
	currentTO.materials = []
	for mat in material_array:
		currentTO.materials.append(load(mat))
	currentTO.update()


func _on_BuildingSettings_updated() -> void:
	# TODO: _on_dialog_closed() does not exist
	# find_parent("EditorHUD")._on_dialog_closed()
	apply_object_tab()


func _on_OptionButton_item_selected(index: int) -> void:
	if currentTO.sides == PlatformSide.LEFT and index == PlatformSide.RIGHT:
		currentTO.rotationObjects += PI
		$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rotation".value = rad2deg(currentTO.rotationObjects)
	elif currentTO.sides == PlatformSide.RIGHT and index == PlatformSide.LEFT:
		currentTO.rotationObjects -= PI
		$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rotation".value = rad2deg(currentTO.rotationObjects)
	currentTO.sides = index
	update_current_rail_attachment()


func _on_ObjectPositioningPlaceLast_pressed():
	currentTO.placeLast = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/PlaceLast".pressed
	update_current_rail_attachment()
