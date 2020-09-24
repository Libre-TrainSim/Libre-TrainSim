tool
extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var world
var currentRail
var copyRail
var copyTO
var currentTO
var eds # Editor Selection
var pluginRoot
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
		currentTO = null
		update_itemList()
		update_Materials()
		update_positioning()
		
	else:
		currentRail = null
		$CurrentRail/Name.text = ""
		$Tab.visible = false

func update_itemList():
	$Tab/TrackObjects/ItemList.clear()
	var tos = currentRail.trackObjects
	for x in range(tos.size()):
		if tos[x].description == null:
			tos[x].queue_free()
		else:
			$Tab/TrackObjects/ItemList.add_item(tos[x].description)


func _on_ClearTOs_pressed():
	var tos = currentRail.trackObjects
	for x in range(tos.size()):
		tos[x].queue_free()
	currentRail.trackObjects.clear()
	update_itemList()
	update_Materials()
	update_positioning()
	update_Position()


func _on_NewTO_pressed():
	if $Tab/TrackObjects/HBoxContainer/LineEdit.text != "":
		var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
		var to = TO_object.instance()
		to.description = $Tab/TrackObjects/HBoxContainer/LineEdit.text
		to.name = currentRail.name + " " + $Tab/TrackObjects/HBoxContainer/LineEdit.text
		to.attachedRail = currentRail.name
		world.get_node("TrackObjects").add_child(to)
		to.set_owner(world)
		update_selected_rail(currentRail)


func _on_RenameTO_pressed():
	if $Tab/TrackObjects/HBoxContainer/LineEdit.text != "":
		currentRail.trackObjects[$Tab/TrackObjects/ItemList.get_selected_items()[0]].description = $Tab/TrackObjects/HBoxContainer/LineEdit.text
		currentRail.trackObjects[$Tab/TrackObjects/ItemList.get_selected_items()[0]].name = currentRail.name + " " + $Tab/TrackObjects/HBoxContainer/LineEdit.text
	update_itemList()
	pass # Replace with function body.


func _on_DuplicateTO_pressed():
	var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
	var to = TO_object.instance()
	var data = currentTO.get_data()
	to.set_data(data)
	to.description = currentTO.description + " (Duplicate)"
	to.name = currentTO.name + " (Duplicate)"
	to.attachedRail = currentRail.name
	world.get_node("TrackObjects").add_child(to)
	to.set_owner(world)
	update_selected_rail(currentRail)
	to._update(true)


func _on_DeleteTO_pressed():
	if currentTO == null: return
	var id = $Tab/TrackObjects/ItemList.get_selected_items()[0]
	if id == null:
		return
	var to = currentRail.trackObjects[id]
	to.queue_free()
	currentRail.trackObjects.erase(to)
	currentTO = null
	#currentRail.trackObjects.append(to)
	
	update_itemList()


func _on_ItemListTO_item_selected(index):	
	currentTO = currentRail.trackObjects[$Tab/TrackObjects/ItemList.get_selected_items()[0]]
	if currentTO == null:
		$"Tab/TrackObjects/Settings".visible = false
		return
	else:
		$"Tab/TrackObjects/Settings".visible = true
	update_Materials()
	update_positioning()
	update_Position()
	$Tab/TrackObjects/HBoxContainer/LineEdit.text = currentTO.description
	

func get_materials():
	var materials = currentTO.materialPaths
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
	currentTO._update(true)
	
		
func update_Materials():
	var childs = $Tab/TrackObjects/Settings/Tab/Object/GridContainer.get_children()
	for child in childs:
		if child.name != "Material 0" and child.find_parent("Material 0") == null:
			child.queue_free()
			
	$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = ""
	if currentTO:
		var objectPath = currentTO.objectPath
		if not objectPath:
			objectPath = ""
		$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = objectPath
		get_materials()
		
func update_Position():
	if currentTO == null: return
	$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = currentTO.onRailPosition
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = currentTO.onRailPosition + currentTO.length


func _on_AssignWholeRail_pressed():
	$Tab/TrackObjects/Settings/Tab/Position/StartPos.visible = not $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed
	$Tab/TrackObjects/Settings/Tab/Position/EndPosition.visible = not $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed


func _on_SavePosition_pressed():
	if $Tab/TrackObjects/Settings/Tab/Position/WholeRail.pressed:
		currentTO.wholeRail = true
		return
	if $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value > currentRail.length:
		$Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value = currentRail.length
	if $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value > currentRail.length:
		$Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value = currentRail.length
	currentTO.wholeRail = false
	currentTO.onRailPosition = $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	currentTO.length = $Tab/TrackObjects/Settings/Tab/Position/EndPosition/SpinBox.value - $Tab/TrackObjects/Settings/Tab/Position/StartPos/SpinBox.value
	currentTO._update(true)



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
	print("Saving..")

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



func _on_Button_pressed(): ## UPDATE
	print("Updating...")
	currentTO.meshSet = false
	currentTO._update(true)


func _on_CopyTO_pressed():
	copyTO = currentTO


func _on_PasteTO_pressed():
	duplicate_newTO(copyTO)
	pass # Replace with function body.

func duplicate_newTO(set):
	if set != null:
			var TO_object = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/TrackObjects.tscn")
			var to = TO_object.instance()
			var data = copyTO.get_data()
			update_Position()
			to.set_data(data)
			to.description = copyTO.description
			to.name = copyTO.name
			to.attachedRail = currentRail.name
			world.get_node("TrackObjects").add_child(to)
			to.set_owner(world)
			update_selected_rail(currentRail)
			currentTO = to
			_on_SavePosition_pressed()
			_on_Button_pressed()
			update_itemList()
			print("Track Object pasted")

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


func _on_CopyTrack_pressed():
	copyRail = currentRail
	print("Track Objects copied")


func _on_PasteRail_pressed():
	print("Pasting Track Objects..")
	for to in copyRail.trackObjects:
		duplicate_newTO(to)
	


func _on_PickObject_pressed():
	$FileDialogObjects.popup_centered()
	


func _on_FileDialog_onject_selected(path):
	$Tab/TrackObjects/Settings/Tab/Object/HBoxContainer/LineEdit.text = path
	_on_SaveMaterials_pressed()
	_on_Button_pressed() # update


var currentMaterial = 0
func _on_FileDialogMaterials_file_selected(path):
	if currentMaterial != 0:
		get_node("Tab/TrackObjects/Settings/Tab/Object/GridContainer/Material " + String(currentMaterial) + "/LineEdit").text = path
		_on_SaveMaterials_pressed()
		_on_Button_pressed() # update


func _on_PickMaterial_pressed(): ## Called by material select script.
	$FileDialogMaterials.popup_centered()
