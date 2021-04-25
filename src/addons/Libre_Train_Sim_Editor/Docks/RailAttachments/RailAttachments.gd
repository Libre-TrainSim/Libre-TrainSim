tool
extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var world
var currentRail
var copyRail
var copyTO
var copyTOArray
var currentTO
var eds # Editor Selection
var pluginRoot

var track_object_resource = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Tab/TrackObjects/Settings.visible = currentTO != null
	pass




func update_selected_rail(node):
	if node.is_in_group("Rail"):
		currentRail = node
		$CurrentRail/Name.text = node.name
		$Tab.visible = true
		var track_object_name = ""
		if is_instance_valid(currentTO):
			track_object_name = currentTO.description
		else:
			currentTO = null
		update_itemList()
		update_Materials()
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

func update_itemList():
	$Tab/TrackObjects/jListTrackObjects.clear()
	var track_objects = currentRail.trackObjects
	for x in range(track_objects.size()):
		if track_objects[x].description == null:
			track_objects[x].queue_free()
		else:
			$Tab/TrackObjects/jListTrackObjects.add_entry(track_objects[x].description)


#func _on_ClearTOs_pressed():
#	var tos = currentRail.trackObjects
#	for x in range(tos.size()):
#		tos[x].queue_free()
#	currentRail.trackObjects.clear()
#	update_itemList()
#	update_Materials()
#	update_positioning()
#	update_Position()
#	print("Cleared TrackObjects")
	

func _on_jListTrackObjects_user_removed_entries(entry_names):
	for entry_name in entry_names:
		var track_object = currentRail.get_track_object(entry_name)
		var track_object_name = track_object.name
		track_object.queue_free()
		currentRail.trackObjects.erase(track_object)
		print("TrackObject " + track_object_name + " deleted")
	update_itemList()


#func _on_NewTO_pressed():
#	if $Tab/TrackObjects/HBoxContainer/LineEdit.text != "":
#		clear_Materials_View()
#		var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
#		var to = TO_object.instance()
#		to.description = $Tab/TrackObjects/HBoxContainer/LineEdit.text
#		to.name = currentRail.name + " " + $Tab/TrackObjects/HBoxContainer/LineEdit.text
#		to.attachedRail = currentRail.name
#		to.materialPaths = []
#		world.get_node("TrackObjects").add_child(to)
#		to.set_owner(world)
#
#		update_selected_rail(currentRail)
#		print("Created TrackObject: "+to.name)
		


func _on_jListTrackObjects_user_added_entry(entry_name):
	print(entry_name)
	clear_Materials_View()
	var track_object = track_object_resource.instance()
	track_object.description = entry_name
	track_object.name = currentRail.name + " " + entry_name
	track_object.attachedRail = currentRail.name
	track_object.materialPaths = []
	world.get_node("TrackObjects").add_child(track_object)
	track_object.set_owner(world)
	
	print("Created track object " + track_object.name)

#func _on_RenameTO_pressed():
#	if $Tab/TrackObjects/HBoxContainer/LineEdit.text != "":
#		currentRail.trackObjects[$Tab/TrackObjects/ItemList.get_selected_items()[0]].description = $Tab/TrackObjects/HBoxContainer/LineEdit.text
#		currentRail.trackObjects[$Tab/TrackObjects/ItemList.get_selected_items()[0]].name = currentRail.name + " " + $Tab/TrackObjects/HBoxContainer/LineEdit.text
#	update_itemList()
#	print("TrackObject renamed: "+ currentRail.trackObjects[$Tab/TrackObjects/ItemList.get_selected_items()[0]].name)

func _on_jListTrackObjects_user_renamed_entry(old_name, new_name):
	var track_object = currentRail.get_track_object(old_name)
	track_object.description = new_name
	track_object.name = currentRail.name + " " + new_name
	print("TrackObject renamed from "+ old_name + " to " + new_name)

#
#func _on_DuplicateTO_pressed():
#	var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
#	var to = TO_object.instance()
#	var data = currentTO.get_data()
#	to.set_data(data)
#	to.description = currentTO.description + " (Duplicate)"
#	to.name = currentTO.name + " (Duplicate)"
#	to.attachedRail = currentRail.name
#	world.get_node("TrackObjects").add_child(to)
#	to.set_owner(world)
#	update_selected_rail(currentRail)
#	to._update(true)
#	print("TrackObject " + to.name + " duplicated")
	
func _on_jListTrackObjects_user_duplicated_entries(source_entry_names, duplicated_entry_names):
	for i in range(source_entry_names.size()):
		var source_entry_name = source_entry_names[i]
		var duplicated_entry_name = duplicated_entry_names[i]
		var source_track_object = currentRail.get_track_object(source_entry_name)
		copy_track_object_to_current_rail(source_track_object, duplicated_entry_name)
		print("TrackObject " +  source_entry_name + " duplicated.")
	pass # Replace with function body.

func copy_track_object_to_current_rail(source_track_object : Node, new_description : String, mirror : bool  = false):
	var new_track_object = track_object_resource.instance()
	var data = source_track_object.get_data()
	new_track_object.set_data(data)
	new_track_object.name = currentRail.name + " " + new_description
	new_track_object.description = new_description
	new_track_object.attachedRail = currentRail.name
	world.get_node("TrackObjects").add_child(new_track_object)
	if mirror:
		new_track_object.rotationObjects = source_track_object.rotationObjects + 180.0
		if source_track_object.sides == 1:
			new_track_object.sides = 2
		elif source_track_object.sides == 2:
			new_track_object.sides = 1
	new_track_object.set_owner(world)
	new_track_object._update(true)


#func _on_DeleteTO_pressed():
#	if currentTO == null: return
#	var id = $Tab/TrackObjects/ItemList.get_selected_items()[0]
#	if id == null:
#		return
#	var to = currentRail.trackObjects[id]
#	var n = to.name
#	to.queue_free()
#	currentRail.trackObjects.erase(to)
#	currentTO = null
#	update_itemList()
#	print("TrackObject " + n + " deleted")


#func _on_ItemListTO_item_selected(index):	
#	currentTO = currentRail.trackObjects[$Tab/TrackObjects/ItemList.get_selected_items()[0]]
#	if currentTO == null:
#		$"Tab/TrackObjects/Settings".visible = false
#		return
#	else:
#		$"Tab/TrackObjects/Settings".visible = true
#	update_Materials()
#	update_positioning()
#	update_Position()
#	$Tab/TrackObjects/HBoxContainer/LineEdit.text = currentTO.description
	
func _on_jListTrackObjects_user_selected_entry(entry_name):
	currentTO = currentRail.get_track_object(entry_name)
	if currentTO == null:
		$"Tab/TrackObjects/Settings".visible = false
		return
	else:
		$"Tab/TrackObjects/Settings".visible = true
	update_Materials()
	update_positioning()
	update_Position()
	pass # Replace with function body.
	

func get_materials(): ## Prepare the View of the Materials-Table
	var materials = currentTO.materialPaths.duplicate()
	for x in range(currentTO.materialPaths.size()):
		var entry = $"Tab/TrackObjects/Settings/Tab/Object/GridContainer/Material 0".duplicate()
		$Tab/TrackObjects/Settings/Tab/Object/GridContainer.add_child(entry)
		entry.get_node("Label").text = "Material " + String(x+1)
		entry.get_node("LineEdit").text =  currentTO.materialPaths[x]
		entry.visible = true


func _on_AddMaterial_pressed():
	var entry = $"Tab/TrackObjects/Settings/Tab/Object/GridContainer/Material 0".duplicate()
	entry.set_script(load("res://addons/Libre_Train_Sim_Editor/Docks/RailAttachments/MaterialSelection.gd"))
	$Tab/TrackObjects/Settings/Tab/Object/GridContainer.add_child(entry)
	entry.get_node("Label").text = entry.name
	entry.visible = true
	print("Material Added")



func _on_SaveMaterials_pressed(): ## The object path is saved too here
	if currentTO == null:
		$"Tab/TrackObjects/Settings".visible = false
		return
	else:
		$"Tab/TrackObjects/Settings".visible = true
	currentTO.objectPath = $Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text
	var childs = $Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children()
	currentTO.materialPaths.clear()
	for child in childs:
		if child.get_node("LineEdit") != null and child.name != "Material 0":
			currentTO.materialPaths.append(child.get_node("LineEdit").text)
	print("Materials Saved")
	update_current_rail_attachment()

func clear_Materials_View():
	var childs = $Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children()
	for child in childs:
		if child.name != "Material 0" and child.find_parent("Material 0") == null:
			child.queue_free()
		
func update_Materials():
	clear_Materials_View()
	$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = ""
	if currentTO:
		var objectPath = currentTO.objectPath
		if not objectPath:
			objectPath = ""
		$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = objectPath
		get_materials()
		
func update_Position():
	if currentTO == null: return
	$Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed = currentTO.wholeRail
	
	$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = currentTO.onRailPosition
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = currentTO.onRailPosition + currentTO.length
	_on_AssignWholeRail_pressed()


func _on_AssignWholeRail_pressed():
	$Tab/TrackObjects/Settings/Tab/Position/StartPos.visible = not $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition.visible = not $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed
	
	$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = currentTO.onRailPosition
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = currentTO.onRailPosition + currentTO.length
	
	_on_SavePosition_pressed()
	update_current_rail_attachment()
	


func _on_SavePosition_pressed():
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
	currentTO.onRailPosition = $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	currentTO.length = $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value - $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	currentTO._update(true)
	print("Position Saved")



func _on_SavePositioning_pressed():
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
	currentTO.rotationObjects = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rotation".value
	currentTO.placeLast = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/PlaceLast".pressed
	currentTO.applySlopeRotation = $"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/applySlopeRotation".pressed
	print("Positioning Saved")
	update_current_rail_attachment()

func update_positioning():
	if currentTO == null: return
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
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/Rotation".value = currentTO.rotationObjects
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/PlaceLast".pressed = currentTO.placeLast
	$"Tab/TrackObjects/Settings/Tab/Object Positioning/GridContainer/applySlopeRotation".pressed = currentTO.applySlopeRotation
	print("Updating...")



func update_current_rail_attachment(): ## UPDATE
	print("Updating...")
	currentTO._update(true)
	if currentTO.description.begins_with("Pole"):
		currentRail.updateOverheadLine()


#func _on_CopyTO_pressed():
#	copyTOArray = []
#	for i in $Tab/TrackObjects/ItemList.get_selected_items():
#		copyTOArray.append (currentRail.trackObjects[i])
#	if copyTOArray == []:
#		$"Tab/TrackObjects/Settings".visible = false
#		return
#	else:
#		$"Tab/TrackObjects/Settings".visible = true
#	print("TrackObject(s) copied. Please don't delete the TrackObject(s), until you pasted a copy of it/them.")
	

func _on_jListTrackObjects_user_copied_entries(entry_names):
	if entry_names.size() == 0:
		$"Tab/TrackObjects/Settings".visible = false
		return
	copyTOArray = []
	for entry_name in entry_names:
		copyTOArray.append(currentRail.get_track_object(entry_name))
	$"Tab/TrackObjects/Settings".visible = true
	print("TrackObject(s) copied. Please don't delete the TrackObject(s), until you pasted a copy of it/them.")





#func _on_PasteTO_pressed():
#	for TO in copyTOArray:
#		duplicate_newTO(TO)
#	print("TrackObject(s) pasted")
	

func _on_jListTrackObjects_user_pasted_entries(source_entry_names, source_jList_id, pasted_entry_names):
	assert(pasted_entry_names.size() == copyTOArray.size())
	for i in range (pasted_entry_names.size()):
		copy_track_object_to_current_rail(copyTOArray[i], pasted_entry_names[i], $Tab/TrackObjects/MirrorPastedObjects.pressed)
			



#func duplicate_newTO(set):
#	if set != null:
#			var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
#			var to = TO_object.instance()
#			var data = set.get_data()
#			update_Position()
#			to.set_data(data)
#			to.description = set.description
#			to.name = set.name
#			to.attachedRail = currentRail.name
#			world.get_node("TrackObjects").add_child(to)
#			to.set_owner(world)
#			update_selected_rail(currentRail)
#			currentTO = to
#			_on_SavePosition_pressed()
#			_on_Button_pressed()
#			update_itemList()
#			print("Track Object pasted")

#		var to = set.duplicate()
#		to.materialPaths = set.materialPaths.duplicate()
#		to.attachedRail = currentRail.name
#		to.name = currentRail.name + " " + to.description
#		world.get_node("TrackObjects").add_child(to)
#		to.set_owner(world)
#		currentTO = to
#		_on_SavePosition_pressed() ## Apply Positions and update the the Mesh Instance
#		_on_Button_pressed()
#		update_itemList()
#		print("Track Object pasted")
#

#
#func _on_CopyTrack_pressed():
#	copyRail = currentRail
#	print("Track Objects copied")

#
#func _on_PasteRail_pressed():
#	print("Pasting Track Objects..")
#	for to in copyRail.trackObjects:
#		duplicate_newTO(to)
	


func _on_PickObject_pressed():
	$FileDialogObjects.popup_centered()
	


func _on_FileDialog_onject_selected(path):
	$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = path
	_on_SaveMaterials_pressed()
	update_current_rail_attachment() # update


var currentMaterial = 0
func _on_FileDialogMaterials_file_selected(path):
	if currentMaterial != 0:
		get_node("Tab/TrackObjects/Settings/Tab/Object/GridContainer/Material " + String(currentMaterial) + "/LineEdit").text = path
		_on_SaveMaterials_pressed()
		update_current_rail_attachment() # update


func _on_PickMaterial_pressed(): ## Called by material select script.
	$FileDialogMaterials.popup_centered()


#func _on_ItemList_multi_selected(index, selected):
#	_on_ItemListTO_item_selected(index)


func _on_MaterialRemove_pressed():
	var materialRow = $Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children().back()
	if materialRow.name != "Material 0":
		$Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children().back().queue_free()
	pass # Replace with function body.


func _on_Randomize_pressed():
	currentTO.newSeed()
	update_current_rail_attachment() # update












