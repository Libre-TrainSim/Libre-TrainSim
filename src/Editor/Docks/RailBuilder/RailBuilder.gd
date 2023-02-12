extends Control

onready var editor: Node = find_parent("Editor")
var world: Node
var currentRail: Node
var editor_selection # Editor Selection


onready var conntected_rails: CustomItemList = $ConntectedRails
onready var start_position: LineEdit = $RotationHeight/StartPosition
onready var end_position: LineEdit = $RotationHeight/EndPosition



func _process(_delta: float) -> void:
	if editor:
		visible = is_instance_valid(currentRail) and get_parent().current_tab == 0


func update_selected_rail(node: Node) -> void:
	conntected_rails.clear_items()
	if is_instance_valid(node) and node.is_in_group("Rail"):
		currentRail = node
		$CurrentRail/Name.text = node.name
		$ManualMoving.pressed = currentRail.manual_moving
		currentRail.update()
		$S.visible = true
		$RotationHeight.visible = true
		update_RotationHeightData()
		update_generalInformation()
		if currentRail.parallel_rail_name != "":
			$S/Settings.hide()
			$S/General/ParallelRail.show()
			return
		$S/Settings.show()
		$S/General/ParallelRail.hide()
		$S/Settings/Length/LineEdit.text = String(node.length)
		$S/Settings/Radius/LineEdit.text = String(node.radius)
		$S/Settings/Angle/LineEdit.text =  String(rad2deg(currentRail.end_rot - currentRail.start_rot))
		self.set_tendSlopeData(currentRail.get_tendSlopeData())
		for rail in currentRail.get_connected_rails(true):
			conntected_rails.add_item(rail.name)
		for rail in currentRail.get_connected_rails(false):
			conntected_rails.add_item(rail.name)
	else:
		currentRail = null
		$CurrentRail/Name.text = ""
		$RotationHeight.visible = false
		$S.visible = false


func _on_OptionButton_item_selected(id: int) -> void:
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


func _on_Update_pressed() -> void:
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)
	if currentRail == null:
		return

	currentRail.rail_type_path = $S/General/RailType/LineEdit.text
	currentRail.distance_to_parallel_rail = float($S/General/ParallelRail/ParallelDistance.text)
	if $S/Settings.visible:
		var radius: float
		var length: float

		if $S/Settings/OptionButton.selected == 0: ## Radius - Length
			radius = float($S/Settings/Radius/LineEdit.text)
			length = float($S/Settings/Length/LineEdit.text)
		elif $S/Settings/OptionButton.selected == 1: ## Radius - Angle
			radius = float($S/Settings/Radius/LineEdit.text)
			var angle: float = float($S/Settings/Angle/LineEdit.text)
			length = deg2rad(radius * angle)
		elif $S/Settings/OptionButton.selected == 2: ## Length Angle
			length = float($S/Settings/Length/LineEdit.text)
			var angle: float = float($S/Settings/Angle/LineEdit.text)
			if angle == 0:
				radius = 0
			else:
				radius = length / deg2rad(angle)
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


func _on_AddRail_pressed() -> void:
	if currentRail == null:
		return
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)
	if $AddRail/Mode.selected == 0: ## After Rail
		var newRail: Node = editor._spawn_rail()
		Logger.vlog(newRail.name)
		newRail.translation = currentRail.end_pos
		newRail.rotation.y = currentRail.end_rot
		newRail.length = float($S/Settings/Length/LineEdit.text)
		newRail.radius = float($S/Settings/Radius/LineEdit.text)
		newRail.rail_type_path = $S/General/RailType/LineEdit.text
		newRail.start_tend = currentRail.end_tend
		newRail.end_tend = currentRail.end_tend
		newRail.start_slope = currentRail.end_slope
		newRail.end_slope =  currentRail.end_slope
		update_selected_rail(newRail)
		if editor_selection != null:
			editor_selection.clear()
			editor_selection.add_node(newRail)
	if $AddRail/Mode.selected == 1: ## Parallel Rail
		var RailParent: Node = currentRail.get_parent()
		var newRail: Node = editor._spawn_rail()
		Root.name_node_appropriate(newRail, currentRail.name + "P", RailParent)
		Logger.vlog(newRail.name)
		newRail.parallel_rail_name = currentRail.name
		newRail.distance_to_parallel_rail = float($AddRail/ParallelDistance/LineEdit.text)
		update_selected_rail(newRail)
		if editor_selection != null:
			editor_selection.clear()
			editor_selection.add_node(newRail)
	if $AddRail/Mode.selected == 2: ## Before Rail
		var newRail: Node = editor._spawn_rail()
		Logger.vlog(newRail.name)
		newRail.translation = currentRail.translation
		newRail.rotation.y = currentRail.rotation.y + PI
		newRail.length = float($S/Settings/Length/LineEdit.text)
		newRail.radius = float($S/Settings/Radius/LineEdit.text)
		newRail.rail_type_path = $S/General/RailType/LineEdit.text
		newRail.start_tend = -currentRail.start_tend
		newRail.end_tend = -currentRail.start_tend
		newRail.start_slope = -currentRail.start_slope
		newRail.end_slope = -currentRail.start_slope
		update_selected_rail(newRail)
		if editor_selection != null:
			editor_selection.clear()
			editor_selection.add_node(newRail)

	editor.set_selected_object(currentRail)
	Logger.log("Rail added.")


func _on_Rename_pressed() -> void:
	if currentRail == null:
		return
	$CurrentRail/Name.text = $CurrentRail/Name.text.replace(" ", "_")
	currentRail.rename($CurrentRail/Name.text)
	update_selected_rail(currentRail)
	editor.set_selected_object(currentRail)
	Logger.log("Rail renamed.")


func _on_Delete_pressed() -> void:
	currentRail.queue_free()
	currentRail = null
	update_selected_rail(self)
	Logger.log("Rail deleted.")


func _on_Mode_item_selected(id: int) -> void:
	$AddRail/ParallelDistance.visible = (id == 1)


func _on_ShiftButton_pressed() -> void:
	if currentRail == null:
		return
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


func _on_Shift2Button_pressed() -> void:
	if currentRail == null:
		return
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)

	var data: Array = calc_shift(float($S/Settings/Shift2/LengthForward/LineEdit.text), float($S/Settings/Shift2/Shift/LineEdit.text))
	if data[1] > 1000:
		Logger.err("MaxRailLength of 1000 exceedet! Canceling..", self)
		return
	currentRail.length = data[1]
	currentRail.radius = data[0]
	currentRail._update(true)


## Calculate the shift of an Rail, given with relational length and shift
func calc_shift(x: float, y: float) -> Array: ## This is 2 dimensional
	if y == 0:
		return [0, x]
	var delta: float = atan(y/x)
	var gamma: float = (PI*0.5) - delta
	var beta: float = (PI*0.5) - gamma  ## Angle of "Rail Circle"
	#print(beta)
	var b: float = sqrt((x*x) + (y*y)) ## Shortest length between beginning and end of the rail
	var a: float = (b / cos(gamma))/2 ## Radius of "Rail Circle"
	var length: float = (beta*2) * a ## Lenght of the rail
	return [a, length]


## Connect two Rails:
func _on_Connect_pressed() -> void:
	var RailParent: Node = world.get_node("Rails")
	var firstRail: Node = RailParent.get_node($RailConnector/FirstRail/LineEdit.text)
	var secondRail: Node = RailParent.get_node($RailConnector/SecondRail/LineEdit.text)
	if not (firstRail.is_in_group("Rail") and secondRail.is_in_group("Rail")) :
		Logger.err("Some Rail not found. Check your spelling!", "%s, %s" % [firstRail, secondRail])
		return
	Logger.log("Rails connected.")

	firstRail._update(true)
	secondRail._update(true)
	var pos1: Vector3
	var rot1: float
	if $RailConnector/FirstRail/OptionButton.selected == 0:
		pos1 = firstRail.translation
		rot1 = firstRail.rotation.y + PI
	else:
		pos1 = firstRail.end_pos
		rot1 = firstRail.end_rot

	var pos2: Vector3
	var rot2: Vector3
	if $RailConnector/SecondRail/OptionButton.selected == 0:
		pos2 = secondRail.translation
		rot2 = secondRail.rotation.y + PI
	else:
		pos2 = secondRail.end_pos
		rot2 = secondRail.end_rot

	var vector: Vector3 = (pos2 - pos1)/2
	Logger.vlog(vector)
	vector = vector.rotated(Vector3(0,1,0), -rot1)

	## Rail 1:
	var newRail: Node = editor._spawn_rail()
	newRail.name = firstRail.name + "Connector"
	newRail.translation = pos1
	newRail.rotation.y = rot1
	var data: Array = calc_shift(vector.x, -vector.z)
	newRail.length = data[1]
	newRail.radius = data[0]
	RailParent.add_child(newRail)
	newRail.set_owner(currentRail.find_parent("World"))
	pos2 = newRail.end_pos
	rot2 = newRail.end_rot

	## Rail 2:
	newRail = editor._spawn_rail()
	newRail.name = secondRail.name + "Connector"
	newRail.translation = pos2
	newRail.rotation.y = rot2
	data = calc_shift(vector.x, -vector.z)
	newRail.length = data[1]
	newRail.radius = -data[0]
	RailParent.add_child(newRail)
	newRail.set_owner(currentRail.find_parent("World"))


func _on_Select_FirstRail_pressed() -> void:
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)
	if currentRail == null:
		return
	$RailConnector/FirstRail/LineEdit.text = currentRail.name


func _on_Select_SecondRail_pressed() -> void:
	if $CurrentRail/Name.text != currentRail.name:
		currentRail = null
		update_selected_rail(self)
	if currentRail == null:
		return
	$RailConnector/SecondRail/LineEdit.text = currentRail.name


func _on_ShowHideTendency_pressed() -> void:
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


func _on_ShowHideSlope_pressed() -> void:
	if $S/Settings/Slope/SlopeGrid.visible:
		$S/Settings/Slope/ShowHideSlope.text = "Show Slope"
		$S/Settings/Slope/SlopeGrid.visible = false
	else:
		$S/Settings/Slope/ShowHideSlope.text = "Hide Slope"
		$S/Settings/Slope/SlopeGrid.visible = true


func get_tendSlopeData() -> Dictionary:
	var d := {}
	d.start_slope = $S/Settings/Slope/SlopeGrid/StartSlope.value
	d.end_slope = $S/Settings/Slope/SlopeGrid/EndSlope.value
	d.start_tend = $S/Settings/Tendency/S/StartTend.value
	d.end_tend = $S/Settings/Tendency/S/EndTend.value
	d.tend1_pos = $S/Settings/Tendency/S2/Tend1Pos.value
	d.tend1 = $S/Settings/Tendency/S2/Tend1.value
	d.tend2_pos = $S/Settings/Tendency/S2/Tend2Pos.value
	d.tend2 = $S/Settings/Tendency/S2/Tend2.value
	d.automatic_tend = $S/Settings/Tendency/automaticTendency.pressed
	return d


func set_tendSlopeData(data: Dictionary) -> void:
	var s := data
	$S/Settings/Slope/SlopeGrid/StartSlope.value = s.start_slope
	$S/Settings/Slope/SlopeGrid/EndSlope.value = s.end_slope
	$S/Settings/Tendency/S/StartTend.value = s.start_tend
	$S/Settings/Tendency/S/EndTend.value = s.end_tend
	$S/Settings/Tendency/S2/Tend1Pos.value = s.tend1_pos
	$S/Settings/Tendency/S2/Tend1.value = s.tend1
	$S/Settings/Tendency/S2/Tend2Pos.value = s.tend2_pos
	$S/Settings/Tendency/S2/Tend2.value = s.tend2
	$S/Settings/Tendency/automaticTendency.pressed = s.automatic_tend
	$S/Settings/Tendency/S2/Tend1Pos.editable = !s.automatic_tend
	$S/Settings/Tendency/S2/Tend1.editable = !s.automatic_tend
	$S/Settings/Tendency/S2/Tend2Pos.editable = !s.automatic_tend
	$S/Settings/Tendency/S2/Tend2.editable = !s.automatic_tend


func update_RotationHeightData() -> void:
	start_position.text = String(currentRail.start_pos)
	end_position.text = String(currentRail.end_pos)
	$RotationHeight/StartRotation.text = String(rad2deg(currentRail.start_rot))
	$RotationHeight/EndRotation.text = String(rad2deg(currentRail.end_rot))
	$RotationHeight/StartHeight.text = String(currentRail.start_pos.y)
	$RotationHeight/EndHeight.text = String(currentRail.end_pos.y)


func update_generalInformation() -> void:
	$S/General/RailType/LineEdit.text = currentRail.rail_type_path
	$S/General/OverheadLine.pressed = currentRail.has_overhead_line
	$S/General/ParallelRail/ParallelRail.text = currentRail.parallel_rail_name
	$S/General/ParallelRail/ParallelDistance.text = String(currentRail.distance_to_parallel_rail)


func _on_ManualMoving_pressed() -> void:
	currentRail.manual_moving = $ManualMoving.pressed
	editor.set_selected_object(currentRail)


func _on_automaticTendency_pressed() -> void:
	currentRail.automatic_tend = $S/Settings/Tendency/automaticTendency.pressed
	currentRail.update_automatic_tend()
	set_tendSlopeData(currentRail.get_tendSlopeData())
	currentRail.update()


func _on_OverheadLine_pressed() -> void:
	currentRail.has_overhead_line = $S/General/OverheadLine.pressed
	if not $S/General/OverheadLine.pressed:
		currentRail.update_overhead_line(null)
		if world.get_node("TrackObjects").has_node(currentRail.name + " Poles"):
			world.get_node("TrackObjects") \
				.get_node(currentRail.name + " Poles") \
				.queue_free()
	else:
		editor._spawn_poles_for_rail(currentRail)
	currentRail.update()


func _on_LineEdit_text_entered(_new_text: String) -> void:
	_on_Update_pressed()


func _on_RenameLine_text_entered(_new_text: String) -> void:
	_on_Rename_pressed()
