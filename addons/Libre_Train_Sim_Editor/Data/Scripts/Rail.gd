tool
extends Spatial


export (String) var railType = "Rail"
export (float) var length 
export (float) var radius 
export (float) var buildDistance = 1
export (int) var visibleSegments
# warning-ignore:unused_class_variable
export (bool) var update setget _update

var trackObjects = []

var MAX_LENGTH = 1000 

var Math = self ## TODO

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

var attachedSignals = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	_update(false)
	if not Engine.is_editor_hint():
		$Beginning.queue_free()
		$Ending.queue_free()
		$Types.hide()
	pass # Replace with function body.

#var test = false
#var testtimer = 0
#func _process(delta):
#	testtimer += delta
#	if testtimer > 2:
#		print("PLING")
#		if test:
#			unload_visible_Instance()
#		else: 
#			load_visible_Instance()
#		test = !test
#		testtimer = 0

# warning-ignore:unused_argument
func _update(newvar):
	if $Types.get_node(railType) == null:
		railType = "Rail"
	buildDistance = $Types.get_node(railType).buildDistance
	
	if length > MAX_LENGTH:
		length = MAX_LENGTH
		print(self.name + ": The max length is " + String(MAX_LENGTH) + ". Shrinking the length to maximal length.")
	startrot = self.rotation_degrees.y
	endrot = Math.getNextDeg(radius, 0, length) + self.rotation_degrees.y
	startpos = self.get_translation()
	endpos = startpos + Math.getNextPos(radius, Vector3(0,0,0), self.rotation_degrees.y, length)
	visibleSegments = length / buildDistance +1
	buildRail()
	if Engine.is_editor_hint():
		$Ending.translation = getNextPos(radius, Vector3(0,0,0), 0, length-1)

func buildRail():
	var distance = 0
	var currentrot = 0
	var currentpos = Vector3(0,0,0)
	if get_node("MultiMeshInstance") == null:
		return
	get_node("MultiMeshInstance").set_multimesh(get_node("MultiMeshInstance").multimesh.duplicate(false))
	var multimesh = get_node("MultiMeshInstance").multimesh
	multimesh.mesh = $Types.get_node(railType).mesh.duplicate(true)
	var idx = 0
	multimesh.instance_count = length / buildDistance + 1
	multimesh.visible_instance_count = visibleSegments
	while distance < length:
		multimesh.set_instance_transform(idx, Transform(Basis().rotated(Vector3(0,1,0), deg2rad(currentrot)), currentpos))
		currentpos = Math.getNextPos(radius, currentpos, currentrot, buildDistance)
		currentrot = Math.getNextDeg(radius, currentrot, buildDistance)
		distance += buildDistance
		idx += 1
		
###################################################################################
## Circle:
# warning-ignore:shadowed_variable
func getNextPos(radius, pos, worldRot, distance):#  Vector3 position, float worldRot, float distance):
	# Straigt
	if radius == 0:
		return pos + Vector3(cos(deg2rad(worldRot))*distance, 0, -sin(deg2rad(worldRot))*distance) ##!!!!
	# Curve
	var extend = radius * 2.0 * PI
	var degree = distance / extend * 360    + worldRot
	return degreeToCoordinate(radius, pos, degree, worldRot)

# warning-ignore:shadowed_variable
func getNextDeg(radius, worldRot, distance):
	# Straight:
	if radius == 0: 
		return worldRot
	# Curve:
	var extend = radius * 2.0 * PI
	return distance / extend * 360    + worldRot


# warning-ignore:shadowed_variable
func degreeToCoordinate(radius, pos, degree, worldRot):
	degree = float(degree)
	var mittelpunkt = pos - Vector3(sin(deg2rad(worldRot)) * radius,0,cos(deg2rad(worldRot)) * radius)
	var a = cos(deg2rad(degree)) * radius
	var b = sin(deg2rad(degree)) * radius
	return mittelpunkt + Vector3(b, 0, a)
	
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
	return getNextPos(radius, self.translation, self.rotation_degrees.y, distance)

func get_deg_at_RailDistance(distance):
	return getNextDeg(radius, rotation_degrees.y, distance)
	
func get_shifted_pos_at_RailDistance(distance, shift):
	var railpos = get_pos_at_RailDistance(distance)
	return railpos + (Vector3(1, 0, 0).rotated(Vector3(0,1,0), deg2rad(get_deg_at_RailDistance(distance)+90))*shift)
	
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
	
