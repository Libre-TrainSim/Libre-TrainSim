extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var world
var currentRail
var eds # Editor Selection
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var editor = find_parent("Editor")
	if editor:
		visible = is_instance_valid(currentRail) and get_parent().current_tab == 1
	pass


func update_selected_rail(node):
	if node.is_in_group("Rail"):
		currentRail = node
		$CurrentRail/Name.text = node.name
		$ManualMoving.pressed = currentRail.manualMoving
		currentRail.update()
		$S.visible = true
		$RotationHeight.visible = true
		update_RotationHeightData()
		update_generalInformation()
		if currentRail.parallelRail != "":
			$S/Settings.hide()
			$S/General/ParallelRail.show()
			return
		$S/Settings.show()
		$S/General/ParallelRail.hide()
		$S/Settings/Length/LineEdit.text = String(node.length)
		$S/Settings/Radius/LineEdit.text = String(node.radius)
		$S/Settings/Angle/LineEdit.text =  String(currentRail.endrot - currentRail.startrot)


		self.set_tendSlopeData(currentRail.get_tendSlopeData())
	else:
		currentRail = null
		$CurrentRail/Name.text = ""
		$RotationHeight.visible = false
		$S.visible = false



func _on_OptionButton_item_selected(id):
	if id == 0: # Length Radius
		$S/Settings/Length.visible = true
		$S/Settings/Radius.visible = true
		$S/Settings/Angle.visible = false
	if id == 1: # Radius Angle
		$S/Settings/Length.visible = false
		$S/Settings/Radius.visible = true
		$S/Settings/Angle.visible = true
	if id == 2: # Length Angle
		$S/Settings/Length.visible = true
		$S/Settings/Radius.visible = false
		$S/Settings/Angle.visible = true

func _on_Update_pressed():
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)
	if currentRail == null: return

	currentRail.railTypePath = $S/General/RailType/LineEdit.text
	currentRail.distanceToParallelRail = float($S/General/ParallelRail/ParallelDistance.text)
	if $S/Settings.visible:
		var radius
		var length

		if $S/Settings/OptionButton.selected == 0: ## Radius - Length
			radius = float($S/Settings/Radius/LineEdit.text)
			length = float($S/Settings/Length/LineEdit.text)
		elif $S/Settings/OptionButton.selected == 1: ## Radius - Angle
			radius = float($S/Settings/Radius/LineEdit.text)
			var angle = float($S/Settings/Angle/LineEdit.text)
			length = (radius * 2.0 * PI) * angle/360.0
		elif $S/Settings/OptionButton.selected == 2: ## Length Angle
			length = float($S/Settings/Length/LineEdit.text)
			var angle = float($S/Settings/Angle/LineEdit.text)
			if angle == 0:
				radius = 0
			else:
				radius = length / ((angle/360.0)*2.0*PI)
			Logger.vlog(radius)

		if length > 1000:
			Logger.log("MaxRailLength of 1000 exceedet! Canceling..", self)
			return
		if length != 0:
			currentRail.length = length
			currentRail.radius = radius
		currentRail.set_tendSlopeData(self.get_tendSlopeData())

	currentRail.update()
	update_selected_rail(currentRail)
	Logger.log("Rail updated.")
	pass # Replace with function body.


func _on_AddRail_pressed():
	if currentRail == null: return
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)
	if $AddRail/Mode.selected == 0: ## After Rail
		var RailParent = world.get_node("Rails")
		var RailNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var newRail = RailNode.instance()
		Logger.vlog(Root.name_node_appropriate(newRail, currentRail.name, RailParent))
		newRail.translation = currentRail.endpos
		newRail.rotation_degrees.y = currentRail.endrot
		newRail.length = float($S/Settings/Length/LineEdit.text)
		newRail.radius = float($S/Settings/Radius/LineEdit.text)
		newRail.railTypePath = $S/General/RailType/LineEdit.text
		newRail.startTend = currentRail.endTend
		newRail.endTend = currentRail.endTend
		newRail.startSlope = currentRail.endSlope
		newRail.endSlope =  currentRail.endSlope
		RailParent.add_child(newRail)
		newRail.set_owner(currentRail.find_parent("World"))
		update_selected_rail(newRail)
		if eds != null:
			eds.clear()
			eds.add_node(newRail)
	if $AddRail/Mode.selected == 1: ## Parallel Rail
		var RailParent = currentRail.get_parent()
		var RailNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var newRail = RailNode.instance()
		Logger.vlog(Root.name_node_appropriate(newRail, currentRail.name + "P", RailParent))
		newRail.parallelRail = currentRail.name
		newRail.distanceToParallelRail = float($AddRail/ParallelDistance/LineEdit.text)
#		currentRail.othersDistance = float($AddRail/ParallelDistance/LineEdit.text)
#		currentRail.calcParallelRail(true)
#		newRail.translation = currentRail.translation + (Vector3(1, 0, 0).rotated(Vector3(0,1,0), deg2rad(currentRail.rotation_degrees.y-90))*float($AddRail/ParallelDistance/LineEdit.text))
#		newRail.rotation_degrees.y = currentRail.rotation_degrees.y
#		newRail.length = currentRail.otherLength
#		newRail.radius = currentRail.otherRadius
#		newRail.railType = $S/General/RailType/LineEdit.text
#		newRail.set_tendSlopeData(currentRail.get_tendSlopeData())
		RailParent.add_child(newRail)
		newRail.set_owner(currentRail.find_parent("World"))
		update_selected_rail(newRail)
		if eds != null:
			eds.clear()
			eds.add_node(newRail)
	if $AddRail/Mode.selected == 2: ## Before Rail
		var RailParent = currentRail.get_parent()
		var RailNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var newRail = RailNode.instance()
		Logger.vlog(Root.name_node_appropriate(newRail, currentRail.name, RailParent))
		newRail.translation = currentRail.translation
		newRail.rotation_degrees.y = currentRail.rotation_degrees.y + 180
		newRail.length = float($S/Settings/Length/LineEdit.text)
		newRail.radius = float($S/Settings/Radius/LineEdit.text)
		newRail.railTypePath = $S/General/RailType/LineEdit.text
		newRail.startTend = -currentRail.startTend
		newRail.endTend = -currentRail.startTend
		newRail.startSlope = -currentRail.startSlope
		newRail.endSlope = -currentRail.startSlope
		RailParent.add_child(newRail)
		newRail.set_owner(currentRail.find_parent("World"))
		update_selected_rail(newRail)
		if eds != null:
			eds.clear()
			eds.add_node(newRail)



	var editor = find_parent("Editor")
	if editor != null:
		editor.set_selected_object(currentRail)
	Logger.log("Rail added.")
	pass # Replace with function body.


func _on_Rename_pressed():
	if currentRail == null: return
	$CurrentRail/Name.text = $CurrentRail/Name.text.replace(" ", "_")
	currentRail.rename($CurrentRail/Name.text)
	update_selected_rail(currentRail)
	var editor = find_parent("Editor")
	if editor:
		editor.set_selected_object(currentRail)
	Logger.log("Rail renamed.")
	pass # Replace with function body.


func _on_Delete_pressed():
	currentRail.free()
	currentRail = null
	update_selected_rail(self)
	Logger.log("Rail deleted.")
	pass # Replace with function body.


func _on_Mode_item_selected(id):
	$AddRail/ParallelDistance.visible = (id == 1)


func _on_ShiftButton_pressed():
	if currentRail == null: return
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)

	currentRail.radius = float($S/Settings/Shift/Radius/LineEdit.text)
	currentRail.InShift = float($S/Settings/Shift/Shift/LineEdit.text)
	if currentRail.radius < 0 and currentRail.InShift > 0:
		currentRail.InShift = currentRail.InShift*-1
	currentRail.calcShift(true)
	if currentRail.Outlength > 1000:
		Logger.err("MaxRailLength of 1000 exceedet! Canceling..", self)
		return
	currentRail.length = currentRail.Outlength
	currentRail._update(true)
	update_selected_rail(currentRail)
	pass # Replace with function body.


func _on_Shift2Button_pressed():
	if currentRail == null: return
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)

	var data = calc_shift(float($S/Settings/Shift2/LengthForward/LineEdit.text), float($S/Settings/Shift2/Shift/LineEdit.text))
	if data[1] > 1000:
		Logger.err("MaxRailLength of 1000 exceedet! Canceling..", self)
		return
	currentRail.length = data[1]
	currentRail.radius = data[0]
	currentRail._update(true)

	pass # Replace with function body.

## Calculate the shift of an Rail, given with relational length and shift
func calc_shift(x, y): ## This is 2 dimensional
	if y == 0:
		return [0, x]
	var delta = rad2deg(atan(y/x))
	var gamma = 90 - delta
	var beta = 180-90-gamma  ## Angle of "Rail Circle"
	#print(beta)
	var b = sqrt((x*x) + (y*y)) ## Shortest length between beginning and end of the rail

	var a = (b / cos(deg2rad(gamma)))/2 ## Radius of "Rail Circle"


	var length = (beta*2)/360 * 2*PI*a ## Lenght of the rail
	return [a, length]


## Connect two Rails:
func _on_Connect_pressed():
	var RailParent = world.get_node("Rails")
	var firstRail = RailParent.get_node($RailConnector/FirstRail/LineEdit.text)
	var secondRail = RailParent.get_node($RailConnector/SecondRail/LineEdit.text)
	if not (firstRail.is_in_group("Rail") and secondRail.is_in_group("Rail")) :
		Logger.err("Some Rail not found. Check your spelling!", "%s, %s" % [firstRail, secondRail])
		return
	Logger.log("Rails connected.")

	firstRail._update(true)
	secondRail._update(true)
	var pos1
	var rot1
	if $RailConnector/FirstRail/OptionButton.selected == 0:
		pos1 = firstRail.translation
		rot1 = firstRail.rotation_degrees.y + 180
	else:
		pos1 = firstRail.endpos
		rot1 = firstRail.endrot

	var pos2
	var rot2
	if $RailConnector/SecondRail/OptionButton.selected == 0:
		pos2 = secondRail.translation
		rot2 = secondRail.rotation_degrees.y +180
	else:
		pos2 = secondRail.endpos
		rot2 = secondRail.endrot

	var vector = (pos2 - pos1)/2
	Logger.vlog(vector)
	vector = vector.rotated(Vector3(0,1,0), -deg2rad(rot1))

	var RailNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")

	## Rail 1:
	var newRail = RailNode.instance()
	newRail.name = firstRail.name + "Connector"
	newRail.translation = pos1
	newRail.rotation_degrees.y = rot1
	var data = calc_shift(vector.x, -vector.z)
	newRail.length = data[1]
	newRail.radius = data[0]
	RailParent.add_child(newRail)
	newRail.set_owner(currentRail.find_parent("World"))
	pos2 = newRail.endpos
	rot2 = newRail.endrot

	## Rail 2:
	newRail = RailNode.instance()
	newRail.name = secondRail.name + "Connector"
	newRail.translation = pos2
	newRail.rotation_degrees.y = rot2
	data = calc_shift(vector.x, -vector.z)
	newRail.length = data[1]
	newRail.radius = -data[0]
	RailParent.add_child(newRail)
	newRail.set_owner(currentRail.find_parent("World"))

	pass # Replace with function body.



func _on_Select_FirstRail_pressed():
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)
	if currentRail == null: return
	$RailConnector/FirstRail/LineEdit.text = currentRail.name


func _on_Select_SecondRail_pressed():
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)
	if currentRail == null: return
	$RailConnector/SecondRail/LineEdit.text = currentRail.name





func _on_ShowHideTendency_pressed():
	if $S/Settings/Tendency/S.visible:
		$S/Settings/Tendency/ShowHideTendency.text = "Show Tendency"
		$S/Settings/Tendency/S.visible = false
		$S/Settings/Tendency/S2.visible = false
		$S/Settings/Tendency/automaticTendency.hide()
	else:
		$S/Settings/Tendency/ShowHideTendency.text = "Hide Tendency"
		$S/Settings/Tendency/S.visible = true
		$S/Settings/Tendency/S2.visible = true
		$S/Settings/Tendency/automaticTendency.show()


func _on_ShowHideSlope_pressed():
	if $S/Settings/Slope/SlopeGrid.visible:
		$S/Settings/Slope/ShowHideSlope.text = "Show Slope"
		$S/Settings/Slope/SlopeGrid.visible = false
	else:
		$S/Settings/Slope/ShowHideSlope.text = "Hide Slope"
		$S/Settings/Slope/SlopeGrid.visible = true


func get_tendSlopeData():
	var d = {}
	d.startSlope = $S/Settings/Slope/SlopeGrid/StartSlope.value
	d.endSlope = $S/Settings/Slope/SlopeGrid/EndSlope.value
	d.startTend = $S/Settings/Tendency/S/StartTend.value
	d.endTend = $S/Settings/Tendency/S/EndTend.value
	d.tend1Pos = $S/Settings/Tendency/S2/Tend1Pos.value
	d.tend1 = $S/Settings/Tendency/S2/Tend1.value
	d.tend2Pos = $S/Settings/Tendency/S2/Tend2Pos.value
	d.tend2 = $S/Settings/Tendency/S2/Tend2.value
	d.automaticTendency = $S/Settings/Tendency/automaticTendency.pressed
	return d

func set_tendSlopeData(data):
	var s = data
	$S/Settings/Slope/SlopeGrid/StartSlope.value = s.startSlope
	$S/Settings/Slope/SlopeGrid/EndSlope.value = s.endSlope
	$S/Settings/Tendency/S/StartTend.value = s.startTend
	$S/Settings/Tendency/S/EndTend.value = s.endTend
	$S/Settings/Tendency/S2/Tend1Pos.value = s.tend1Pos
	$S/Settings/Tendency/S2/Tend1.value = s.tend1
	$S/Settings/Tendency/S2/Tend2Pos.value = s.tend2Pos
	$S/Settings/Tendency/S2/Tend2.value = s.tend2
	$S/Settings/Tendency/automaticTendency.pressed = s.automaticTendency
	$S/Settings/Tendency/S2/Tend1Pos.editable = !s.automaticTendency
	$S/Settings/Tendency/S2/Tend1.editable = !s.automaticTendency
	$S/Settings/Tendency/S2/Tend2Pos.editable = !s.automaticTendency
	$S/Settings/Tendency/S2/Tend2.editable = !s.automaticTendency



func update_RotationHeightData():
	$RotationHeight/StartRotation.text = String(currentRail.startrot)
	$RotationHeight/EndRotation.text =String( currentRail.endrot)
	$RotationHeight/StartHeight.text = String(currentRail.startpos.y)
	$RotationHeight/EndHeight.text = String(currentRail.endpos.y)

func update_generalInformation():
	$S/General/RailType/LineEdit.text = currentRail.railTypePath
	$S/General/OverheadLine.pressed = currentRail.overheadLine
	$S/General/ParallelRail/ParallelRail.text = currentRail.parallelRail
	$S/General/ParallelRail/ParallelDistance.text = String(currentRail.distanceToParallelRail)



func _on_ManualMoving_pressed():
	currentRail.manualMoving = $ManualMoving.pressed
	var editor = find_parent("Editor")
	if editor:
		editor.set_selected_object(currentRail)



func _on_automaticTendency_pressed():
	currentRail.automaticTendency = $S/Settings/Tendency/automaticTendency.pressed
	currentRail.updateAutomaticTendency()
	set_tendSlopeData(currentRail.get_tendSlopeData())
	currentRail._update(true)






func _on_OverheadLine_pressed():
	currentRail.overheadLine = $S/General/OverheadLine.pressed
	currentRail.updateOverheadLine()


func _on_LineEdit_text_entered(new_text):
	_on_Update_pressed()


func _on_RenameLine_text_entered(new_text):
	_on_Rename_pressed()
