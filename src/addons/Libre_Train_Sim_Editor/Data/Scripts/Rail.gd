tool
extends Spatial

## Documentation Notes:
# Please be aware of the parallel Mode:
# If 'parallelRail != ""' All local train Settings apart from 'railType' and 'distanceToParallelRail' are deprecated. The Rail gets the rest information from parallel rail.


export (String) var railType = "Rail"
export (float) var length 
export (float) var radius 
export (float) var buildDistance = 1
export (int) var visibleSegments
# warning-ignore:unused_class_variable
export (bool) var update setget _update

export (bool) var manualMoving = false
var fixedTransform

var trackObjects = []


var MAX_LENGTH = 1000 

export (float) var startrot 
export (float) var endrot
export (Vector3) var startpos
export (Vector3) var endpos 

export (float) var othersDistance = -4.5
export (float) var otherRadius 
export (float) var otherLength
# warning-ignore:unused_class_variable
export (bool) var calculate setget calcParallelRail

export (float) var InShift = 2.25
# warning-ignore:unused_class_variable
export (float) var InRadius = 400
export (float) var Outlength
# warning-ignore:unused_class_variable
export (bool) var calculateShift setget calcShift

## Steep
export (float) var startSlope = 0 # Degree
export (float) var endSlope = 0 # Degree

export (float) var startTend = 0
export (float) var tend1Pos = -1
export (float) var tend1 = 0
export (float) var tend2Pos = 0
export (float) var tend2 = 0
export (float) var endTend
export (float) var automaticTendency = false

export (String) var parallelRail = ""
export (float) var distanceToParallelRail = 0
var parRail

onready var world = find_parent("World")
onready var buildings = world.get_node("Buildings")


var attachedSignals = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	manualMoving = false
	_update(false)
	if not Engine.is_editor_hint():
		$Beginning.queue_free()
		$Ending.queue_free()
		$Types.hide()
	pass # Replace with function body.

var EditorUpdateTimer = 0
func _process(delta):
	if Engine.is_editor_hint():
		EditorUpdateTimer += delta
		if EditorUpdateTimer < 0.25:
			return
		EditorUpdateTimer = 0
		## Disable moving in editor, if manual Moving is false:
		if fixedTransform == null:
			fixedTransform = transform
		if not manualMoving:
			transform = fixedTransform
		else:
			fixedTransform = transform
		
		if name.match(" "):
			name = name.replace(" ", "_")
		
		
		## Move Buildings to the Buildings Node
		for child in get_children():
			if child.is_class("MeshInstance") and not (child.name == "Beginning" or child.name == "Ending"):
				remove_child(child)
				buildings.add_child(child)
				child.owner = world

func _update(newvar):
	world = find_parent("World")
	if world == null: return
	if parallelRail == "":
		updateAutomaticTendency()
	if parallelRail != "":
		parRail = world.get_node("Rails").get_node(parallelRail)
		if parRail == null:
			print("Cant find parallel rail. Updating Rail canceled..")
			return
		
		if parRail.radius == 0:
			radius = 0
			length = parRail.length
		else:
			radius = parRail.radius + distanceToParallelRail
			length = parRail.length * ((radius)/(parRail.radius))
		translation = parRail.get_shifted_pos_at_RailDistance(0, distanceToParallelRail) ## Hier verstehe ich das minus nicht
		rotation_degrees.y = parRail.rotation_degrees.y
		fixedTransform = transform
			
	if $Types.get_node(railType) == null:
		railType = "Rail"
	buildDistance = $Types.get_node(railType).buildDistance
	
	if length > MAX_LENGTH:
		length = MAX_LENGTH
		print(self.name + ": The max length is " + String(MAX_LENGTH) + ". Shrinking the length to maximal length.")
	startpos = self.get_translation()
	startrot = self.rotation_degrees.y
	endrot = get_deg_at_RailDistance(length)
	endpos = get_pos_at_RailDistance(length)
	visibleSegments = length / buildDistance +1
	if not world.editorAllObjectsUnloaded or not Engine.is_editor_hint():
		buildRail()
	else:
		if self.has_node("MultiMeshInstance"):
			$MultiMeshInstance.queue_free()
			
	if Engine.is_editor_hint():
		$Ending.translation = get_local_transform_at_rail_distance(length).origin
	$Types.hide()

func buildRail():
	if get_node("MultiMeshInstance") == null:
		return
	get_node("MultiMeshInstance").set_multimesh(get_node("MultiMeshInstance").multimesh.duplicate(false))
	var multimesh = get_node("MultiMeshInstance").multimesh
	multimesh.mesh = $Types.get_node(railType).mesh.duplicate(true)
	
	multimesh.instance_count = length / buildDistance + 1
	multimesh.visible_instance_count = visibleSegments
	var distance = 0
	for i in range(0, multimesh.visible_instance_count):
		multimesh.set_instance_transform(i, get_local_transform_at_rail_distance(distance))
		distance += buildDistance

func get_transform_at_rail_distance(distance):
	var locTransform = get_local_transform_at_rail_distance(distance)
	return Transform(locTransform.basis.rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)) ,translation + locTransform.origin.rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)))
func get_local_transform_at_rail_distance(distance):
	if parallelRail == "":
		return Transform(Basis().rotated(Vector3(1,0,0),deg2rad(get_tend_at_rail_distance(distance))).rotated(Vector3(0,0,1), deg2rad(get_heightRot(distance))).rotated(Vector3(0,1,0), deg2rad(circle_get_deg(radius, distance))), get_local_pos_at_RailDistance(distance) ) 
	else:
		var parDistance = distance/length * parRail.length
		return Transform(Basis().rotated(Vector3(1,0,0),deg2rad(parRail.get_tend_at_rail_distance(parDistance))).rotated(Vector3(0,0,1), deg2rad(parRail.get_heightRot(parDistance))).rotated(Vector3(0,1,0), deg2rad(parRail.circle_get_deg(parRail.radius, parDistance))), parRail.get_shifted_local_pos_at_RailDistance(parDistance, distanceToParallelRail)+ ((parRail.startpos-startpos).rotated(Vector3(0,1,0), deg2rad(-rotation_degrees.y))))#+(-translation+parRail.translation).rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)) )
	
func speedToKmH(speed):
	return speed*3.6
	
# warning-ignore:unused_argument
func calcParallelRail(newvar):
	_update(true)
	if radius == 0:
		otherRadius = 0
		otherLength = length
		return
	var U = 2.0* PI * radius
	otherRadius = radius + othersDistance
	if U == 0:
		otherLength = length
	else:
		otherLength = (length / U) * (2.0 * PI * otherRadius)
	
# warning-ignore:unused_argument
func calcShift(newvar):
	_update(true)
	if radius == 0:
		Outlength = length
		return
	var angle = rad2deg(acos((radius-InShift)/radius))

	if String(angle) == "nan":
		Outlength = length
		return
	Outlength = 2.0 * PI * radius * angle / 360.0

func register_signal(name, distance):
	attachedSignals[name] = distance
	
func get_pos_at_RailDistance(distance):
	var circlePos = circle_get_pos(radius, distance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y)).rotated(Vector3(0,1,0), deg2rad(startrot))+startpos

func get_local_pos_at_RailDistance(distance):
	var circlePos = circle_get_pos(radius, distance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y))
	
func get_deg_at_RailDistance(distance):
	return circle_get_deg(radius, distance) + startrot
func get_local_deg_at_RailDistance(distance):
	return circle_get_deg(radius, distance)
	
func get_shifted_pos_at_RailDistance(distance, shift):
	return get_shifted_local_pos_at_RailDistance(distance, shift).rotated(Vector3(0,1,0),deg2rad(rotation_degrees.y)) + startpos
#	var railpos = get_pos_at_RailDistance(distance)
#	return railpos + (Vector3(1, 0, 0).rotated(Vector3(0,1,0), deg2rad(get_deg_at_RailDistance(distance)+90))*shift)

func get_shifted_local_pos_at_RailDistance(distance, shift):
	var newRadius = radius + shift
	if radius == 0:
		newRadius = 0
	var newDistance = distance
	if radius != 0:
		newDistance = distance * ((newRadius)/(radius))
	var circlePos = circle_get_pos(newRadius, newDistance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y+shift))  
	
func unload_visible_Instance():
	
	print("Unloading visible Instance for Rail "+name)
	$MultiMeshInstance.queue_free()

func load_visible_Instance():
	if get_node("MultiMeshInstance") != null: return
	print("Loading visible Instance for Rail "+name)
	var multimeshI = MultiMeshInstance.new()#
	multimeshI.multimesh = MultiMesh.new().duplicate(true)
	multimeshI.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimeshI.name = "MultiMeshInstance"
	add_child(multimeshI)
	multimeshI.owner = self
	_update(true)


################################################### Easy Circle Functions:
func circle_get_pos(radius, distance):
	if radius == 0:
		return Vector2(distance, 0)
	## Calculate: Coordinate:
	var degree = circle_get_deg(radius, distance)
	var middleOfCircle = Vector2(0, radius)
	var a = cos(deg2rad(degree)) * radius
	var b = sin(deg2rad(degree)) * radius
	return middleOfCircle + Vector2(b, -a)  ## See HowACircleIsCalculated.pdf in github repository


func circle_get_deg(radius, distance):
	if radius == 0:
		return 0

	# Calculate needed degree:
	var extend = radius * 2.0 * PI
	return float(distance / extend * 360)

#### Height Functions:
func get_height(distance):
	if parRail != null:
		var newRadius = radius - distanceToParallelRail
		if radius == 0:
			newRadius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * ((newRadius)/(radius))
		return parRail.get_height(newDistance)
	var startGradient = rad2deg(atan(startSlope/100))
	var endGradient = rad2deg(atan(endSlope/100))
	
	var basicHeight = float(tan(deg2rad(startGradient)) * distance)
	if endGradient - startGradient == 0:
		return basicHeight
	var heightRadius = (360*length)/(2*PI*(endGradient - startGradient))
	return circle_get_pos(heightRadius, distance).y + basicHeight

func get_heightRot(distance): ## Get Slope
	if parRail != null:
		var newRadius = radius - distanceToParallelRail
		if radius == 0: 
			newRadius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * ((newRadius)/(radius))
		return parRail.get_heightRot(newDistance)
	var startGradient = rad2deg(atan(startSlope/100))
	var endGradient = rad2deg(atan(endSlope/100))
	
	var basicRot = startGradient
	if endGradient - startGradient == 0:
		return basicRot
	var heightRadius = (360*length)/(2*PI*(endGradient - startGradient))
	return circle_get_deg(heightRadius, distance) + basicRot


func get_tend_at_rail_distance(distance):
	if parRail != null:
		var newRadius = radius - distanceToParallelRail
		if radius == 0: 
			newRadius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * ((newRadius)/(radius))
		return parRail.get_tend_at_rail_distance(newDistance)
	if distance >= tend1Pos and distance < tend2Pos:
		return -(tend1 + (tend2-tend1) * (distance - tend1Pos)/(tend2Pos - tend1Pos))
	if distance <= tend1Pos:
		return -(startTend + (tend1-startTend) * (distance)/(tend1Pos))
	if tend2Pos > 0 and distance >= tend2Pos:
		return -(tend2 + (endTend-tend2) * (distance -tend2Pos)/(length-tend2Pos))
	return -(startTend + (endTend-startTend) * (distance/length))
	return 0
	
func get_tendSlopeData():
	var d = {}
	var s = self
	d.startSlope = s.startSlope
	d.endSlope = s.endSlope
	d.startTend = s.startTend
	d.endTend = s.endTend
	d.tend1Pos = s.tend1Pos
	d.tend1 = s.tend1
	d.tend2Pos = s.tend2Pos
	d.tend2 = s.tend2
	d.automaticTendency = s.automaticTendency
	return d

func set_tendSlopeData(data):
	var d = self
	var s = data
	d.startSlope = s.startSlope
	d.endSlope = s.endSlope
	d.startTend = s.startTend
	d.endTend = s.endTend
	d.tend1Pos = s.tend1Pos
	d.tend1 = s.tend1
	d.tend2Pos = s.tend2Pos
	d.tend2 = s.tend2
	d.automaticTendency = s.automaticTendency

var automaticPointDistance = 50
func updateAutomaticTendency(): 
	if automaticTendency and radius != 0 and length > 3*automaticPointDistance:
		tend1Pos = automaticPointDistance
		tend2Pos = length -automaticPointDistance
		var tendency = 300/radius * 5
		tend1 = tendency
		tend2 = tendency
	elif automaticTendency and radius == 0:
		tend1 = 0
		tend2 = 0
