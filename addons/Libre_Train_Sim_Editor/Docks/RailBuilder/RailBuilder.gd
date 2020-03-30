tool
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
	pass


func update_selected_rail(node):
	if node.is_in_group("Rail"):
		currentRail = node
		$CurrentRail/Name.text = node.name
		currentRail._update(true)
		$Settings.visible = true
		$Rotations.visible = true
		$"Rotations/StartRotation".text = String(currentRail.startrot)
		$"Rotations/EndRotation".text = String(currentRail.endrot)
		$Settings/Length/LineEdit.text = String(node.length)
		$Settings/Radius/LineEdit.text = String(node.radius)
		$Settings/Angle/LineEdit.text =  String(currentRail.endrot - currentRail.startrot)
		$Settings/RailType/LineEdit.text = currentRail.railType
	else:
		currentRail = null
		$CurrentRail/Name.text = ""
		$Rotations.visible = false
		$Settings.visible = false
		


func _on_OptionButton_item_selected(id):
	if id == 0: # Length Radius
		$Settings/Length.visible = true
		$Settings/Radius.visible = true
		$Settings/Angle.visible = false
	if id == 1: # Radius Angle
		$Settings/Length.visible = false
		$Settings/Radius.visible = true
		$Settings/Angle.visible = true
	if id == 2: # Length Angle
		$Settings/Length.visible = true
		$Settings/Radius.visible = false
		$Settings/Angle.visible = true

func _on_Update_pressed():
	if $CurrentRail/Name.text != currentRail.name: 
		currentRail = null
		update_selected_rail(self)
	if currentRail == null: return
	
	var radius
	var length
	
	if $Settings/OptionButton.selected == 0: ## Radius - Length
		radius = float($Settings/Radius/LineEdit.text)
		length = float($Settings/Length/LineEdit.text)
	elif $Settings/OptionButton.selected == 1: ## Radius - Angle
		radius = float($Settings/Radius/LineEdit.text)
		var angle = float($Settings/Angle/LineEdit.text)
		length = (radius * 2.0 * PI) * angle/360.0
	elif $Settings/OptionButton.selected == 2: ## Length Angle
		length = float($Settings/Length/LineEdit.text)
		var angle = float($Settings/Angle/LineEdit.text)
		if angle == 0:
			radius = 0
		else: 
			radius = length / ((angle/360.0)*2.0*PI)
		print(radius)
	
	if length > 1000:
		print("MaxRailLength of 1000 exceedet! Canceling..")
		return
	if length != 0:
		currentRail.length = length
		currentRail.radius = radius
	currentRail.railType = $Settings/RailType/LineEdit.text
	currentRail._update(true)
	update_selected_rail(currentRail)
	pass # Replace with function body.


func _on_AddRail_pressed():
	if currentRail == null: return
	if $CurrentRail/Name.text != currentRail.name: 
		currentRail = null
		update_selected_rail(self)
	if $AddRail2/Mode.selected == 0: ## After Rail
		var RailParent = world.get_node("Rails")
		var RailNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var newRail = RailNode.instance()
		newRail.name = currentRail.name
		newRail.translation = currentRail.endpos
		newRail.rotation_degrees.y = currentRail.endrot
		newRail.length = float($Settings/Length/LineEdit.text)
		newRail.radius = float($Settings/Radius/LineEdit.text)
		newRail.railType = $Settings/RailType/LineEdit.text
		RailParent.add_child(newRail)
		newRail.set_owner(currentRail.find_parent("World"))
		update_selected_rail(newRail)
		eds.clear()
		eds.add_node(newRail)
	if $AddRail2/Mode.selected == 1: ## Parallel Rail
		var RailParent = currentRail.get_parent()
		var RailNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var newRail = RailNode.instance()
		newRail.name = currentRail.name + "P"
		currentRail.othersDistance = float($ParallelDistance/LineEdit.text)
		currentRail.calcParallelRail(true)
		newRail.translation = currentRail.translation + (Vector3(1, 0, 0).rotated(Vector3(0,1,0), deg2rad(currentRail.rotation_degrees.y-90))*float($ParallelDistance/LineEdit.text))
		newRail.rotation_degrees.y = currentRail.rotation_degrees.y
		newRail.length = currentRail.otherLength
		newRail.radius = currentRail.otherRadius
		newRail.railType = $Settings/RailType/LineEdit.text
		RailParent.add_child(newRail)
		newRail.set_owner(currentRail.find_parent("World"))
		update_selected_rail(newRail)
		eds.clear()
		eds.add_node(newRail)
	if $AddRail2/Mode.selected == 2: ## Before Rail
		var RailParent = currentRail.get_parent()
		var RailNode = preload("res://addons/Libre_Train_Sim_Editor/Data/Modules/Rail.tscn")
		var newRail = RailNode.instance()
		newRail.name = currentRail.name
		newRail.translation = currentRail.translation
		newRail.rotation_degrees.y = currentRail.rotation_degrees.y + 180
		newRail.length = float($Settings/Length/LineEdit.text)
		newRail.radius = float($Settings/Radius/LineEdit.text)
		newRail.railType = $Settings/RailType/LineEdit.text
		RailParent.add_child(newRail)
		newRail.set_owner(currentRail.find_parent("World"))
		update_selected_rail(newRail)
		eds.clear()
		eds.add_node(newRail)
		
		
		

	pass # Replace with function body.


func _on_Rename_pressed():
	if currentRail == null: return
	currentRail.name = $CurrentRail/Name.text
	update_selected_rail(currentRail)
	pass # Replace with function body.


func _on_Delete_pressed():
	currentRail.free()
	currentRail = null
	update_selected_rail(self)
	pass # Replace with function body.


func _on_Mode_item_selected(id):
	$ParallelDistance.visible = (id == 1)


func _on_ShiftButton_pressed():
	if currentRail == null: return
	if $CurrentRail/Name.text != currentRail.name: 
		currentRail = null
		update_selected_rail(self)
	
	currentRail.radius = float($Settings/Shift/Radius/LineEdit.text)
	currentRail.InShift = float($Settings/Shift/Shift/LineEdit.text)
	if currentRail.radius < 0 and currentRail.InShift > 0:
		currentRail.InShift = currentRail.InShift*-1
	currentRail.calcShift(true)
	if currentRail.Outlength > 1000:
		print("MaxRailLength of 1000 exceedet! Canceling..")
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
		
	var data = calc_shift(float($Settings/Shift2/LengthForward/LineEdit.text), float($Settings/Shift2/Shift/LineEdit.text))
	if data[1] > 1000:
		print("MaxRailLength of 1000 exceedet! Canceling..")
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
		print("Some Rail not found. Check your spelling!")
		return
	
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
	print(vector)
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



