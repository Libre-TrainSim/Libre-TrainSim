extends WorldObject

## Documentation Notes:
# Please be aware of the parallel Mode:
# If 'parallelRail != ""' All local train Settings apart from 'railType' and 'distanceToParallelRail' are deprecated. The Rail gets the rest information from parallel rail.


export (String, FILE, "*.tscn,*.scn") var rail_type_path: String = "res://Resources/RailTypes/Default.tscn"
export (float) var length: float
export (float) var radius: float
export (float) var buildDistance: float = 1
export (int) var visibleSegments: int
# warning-ignore:unused_class_variable
export (bool) var manualMoving: bool = false
var fixedTransform: Transform

var trackObjects: Array = []


const MAX_LENGTH: float = 1000.0

export (float) var startrot: float
export (float) var endrot: float
export (Vector3) var startpos: Vector3
export (Vector3) var endpos: Vector3

#export (float) var othersDistance = -4.5
#export (float) var otherRadius
#export (float) var otherLength
## warning-ignore:unused_class_variable
#
#
#export (float) var InShift = 2.25
## warning-ignore:unused_class_variable
#export (float) var InRadius = 400
#export (float) var Outlength
## warning-ignore:unused_class_variable


## Steep
export (float) var startSlope: float = 0 # Degree
export (float) var endSlope: float = 0 # Degree

export (float) var startTend: float = 0
export (float) var tend1Pos: float = -1
export (float) var tend1: float = 0
export (float) var tend2Pos: float = 0
export (float) var tend2: float = 0
export (float) var endTend: float
export (bool) var automaticTendency: bool = false

export (String) var parallelRail: String = ""
export (float) var distanceToParallelRail: float = 0

export (bool) var overheadLine: bool = true
var overheadLineHeight1: float = 5.3
var overheadLineHeight2: float = 6.85
var overheadLineThinkness: float = 0.02
var line2HeightChangingFactor: float = 0.9
var overheadLineBuilded: bool = false

var parRail: Spatial

onready var world: Node = find_parent("World")
onready var buildings: Spatial = world.get_node("Buildings")

var attachedSignals: Array = []


func _ready() -> void:
	update_parallel_rail_settings()
	manualMoving = false
	_update()
	if not Root.Editor:
		$Beginning.queue_free()
		$Ending.queue_free()
		$Mid.queue_free()


func _exit_tree() -> void:
	for track_object in trackObjects:
		track_object.queue_free()


func rename(new_name: String) -> void:
	var _unused = Root.name_node_appropriate(self, new_name, get_parent())
	for track_object in trackObjects:
		track_object.name = name + " " + track_object.description
		track_object.attached_rail = name


func update_parallel_rail_settings() -> void:
	if parallelRail == "":
		return
	parRail = get_parent().get_node(parallelRail)
	if parRail == null:
		Logger.err("Cant find parallel rail. Updating Rail canceled..", self)
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


func _update() -> void:
	var rail_type_node: Spatial = load(rail_type_path).instance()

	buildDistance = rail_type_node.buildDistance
	overheadLineHeight1 = rail_type_node.overheadLineHeight1
	overheadLineHeight2 = rail_type_node.overheadLineHeight2
	overheadLineThinkness = rail_type_node.overheadLineThinkness
	line2HeightChangingFactor = rail_type_node.line2HeightChangingFactor

	if parallelRail.empty():
		updateAutomaticTendency()
	else:
		update_parallel_rail_settings()

	if length > MAX_LENGTH:
		length = MAX_LENGTH
		Logger.warn(self.name + ": The max length is " + String(MAX_LENGTH) + ". Shrinking the length to maximal length.", self)

	visibleSegments = int(length / buildDistance) + 1

	# Ensure visible Instance:
	visible = true
	var multimeshI: MultiMeshInstance = get_node_or_null("MultiMeshInstance")
	if multimeshI == null:
		multimeshI = MultiMeshInstance.new()
		multimeshI.name = "MultiMeshInstance"
		add_child(multimeshI)
		multimeshI.set_owner(self)

	if multimeshI.multimesh == null or not multimeshI.multimesh.has_meta("is_unique"):
		multimeshI.multimesh = MultiMesh.new()
		multimeshI.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimeshI.multimesh.set_meta("is_unique", true)

	multimeshI.multimesh.instance_count = visibleSegments

	# this is called, but mesh remains null
	if multimeshI.multimesh.mesh == null:
		multimeshI.multimesh.mesh = rail_type_node.get_child(0).mesh
		for i in range(rail_type_node.get_child(0).get_surface_material_count()):
			multimeshI.multimesh.mesh.surface_set_material(i, rail_type_node.get_child(0).get_surface_material(i))

	for i in range(visibleSegments):
		multimeshI.multimesh.set_instance_transform(i, get_local_transform_at_rail_distance(i*buildDistance))

	if overheadLine:
		update_overheadline(calculate_overhadline_mesh())
	else:
		# Fix overhead line being visible on load despite being disabled
		var that_overhead_line = get_node_or_null("OverheadLine")
		if that_overhead_line != null:
			that_overhead_line.queue_free()

	if Root.Editor and visible:
		$Ending.transform = get_local_transform_at_rail_distance(length)
		$Mid.transform = get_local_transform_at_rail_distance(length/2.0)
		update_connection_arrows()
		for track_object in trackObjects:
			track_object.update()

	rail_type_node.queue_free()


func unload_visible_instance() -> void:
	visible = false
	if get_node_or_null("MultiMeshInstance") != null:
		$MultiMeshInstance.queue_free()
	if get_node_or_null("OverheadLine") != null:
		$OverheadLine.queue_free()
	for track_object in trackObjects:
		if is_instance_valid(track_object):
			track_object.queue_free()
	trackObjects.clear()


func update() -> void:
	update_positions_and_rotations()
	if not visible:
		unload_visible_instance()
	else:
		_update()


func get_track_object(track_object_name : String) -> Spatial: # (Searches for the description of track objects
	for track_object in trackObjects:
		if not is_instance_valid(track_object):
			continue
		if track_object.description == track_object_name:
			return track_object
	return null



# local to "Rails" node
func get_transform_at_rail_distance(distance: float) -> Transform:
	var locTransform: Transform = get_local_transform_at_rail_distance(distance)
	return Transform(locTransform.basis.rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)) ,translation + locTransform.origin.rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)))


# completely global
func get_global_transform_at_rail_distance(distance: float) -> Transform:
	var locTransform: Transform = get_local_transform_at_rail_distance(distance)
	var global_rot: Vector3 = global_transform.basis.get_euler()
	var global_pos: Vector3 = global_transform.origin
	return Transform(locTransform.basis.rotated(Vector3(0,1,0), global_rot.y), global_pos + locTransform.origin.rotated(Vector3(0,1,0), global_rot.y))

# local to this rail
func get_local_transform_at_rail_distance(distance: float) -> Transform:
	if parallelRail == "":
		return Transform(Basis().rotated(Vector3(1,0,0),deg2rad(get_tend_at_rail_distance(distance))).rotated(Vector3(0,0,1), deg2rad(get_heightRot(distance))).rotated(Vector3(0,1,0), deg2rad(circle_get_deg(radius, distance))), get_local_pos_at_RailDistance(distance) )
	else:
		if parRail == null:
			update_parallel_rail_settings()
		var parDistance: float = distance/length * parRail.length
		return Transform(Basis().rotated(Vector3(1,0,0),deg2rad(parRail.get_tend_at_rail_distance(parDistance))).rotated(Vector3(0,0,1), deg2rad(parRail.get_heightRot(parDistance))).rotated(Vector3(0,1,0), deg2rad(parRail.circle_get_deg(parRail.radius, parDistance))), parRail.get_shifted_local_pos_at_RailDistance(parDistance, distanceToParallelRail)+ ((parRail.startpos-startpos).rotated(Vector3(0,1,0), deg2rad(-rotation_degrees.y))))#+(-translation+parRail.translation).rotated(Vector3(0,1,0), deg2rad(rotation_degrees.y)) )


# why is this here? this is in Math.gd !!!
func speedToKmH(speed: float) -> float:
	return speed*3.6


## warning-ignore:unused_argument
#func calcParallelRail(newvar):
#	if radius == 0:
#		otherRadius = 0
#		otherLength = length
#		return
#	var U = 2.0* PI * radius
#	otherRadius = radius + othersDistance
#	if U == 0:
#		otherLength = length
#	else:
#		otherLength = (length / U) * (2.0 * PI * otherRadius)

## warning-ignore:unused_argument
#func calcShift(newvar):
#	if radius == 0:
#		Outlength = length
#		return
#	var angle = rad2deg(acos((radius-InShift)/radius))
#
#	if String(angle) == "nan":
#		Outlength = length
#		return
#	Outlength = 2.0 * PI * radius * angle / 360.0

func register_signal(name: String, distance: float) -> void:
	Logger.vlog("Signal " + name + " registered at rail.")
	attachedSignals.append({"name": name, "distance": distance})


func get_pos_at_RailDistance(distance: float) -> Vector3:
	var circlePos: Vector2 = circle_get_pos(radius, distance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y)).rotated(Vector3(0,1,0), deg2rad(startrot))+startpos


func get_local_pos_at_RailDistance(distance: float) -> Vector3:
	var circlePos: Vector2 = circle_get_pos(radius, distance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y))


func get_deg_at_RailDistance(distance: float) -> float:
	return circle_get_deg(radius, distance) + startrot


func get_local_deg_at_RailDistance(distance: float) -> float:
	return circle_get_deg(radius, distance)


# completely global
func get_shifted_global_pos_at_RailDistance(distance: float, shift: float) -> Vector3:
	var local_pos = get_shifted_local_pos_at_RailDistance(distance, shift)
	var global_rot = global_transform.basis.get_euler()
	var global_pos = global_transform.origin
	return global_pos + local_pos.rotated(Vector3(0,1,0), global_rot.y)


# local to "Rails" node
func get_shifted_pos_at_RailDistance(distance: float, shift: float) -> Vector3:
	return get_shifted_local_pos_at_RailDistance(distance, shift).rotated(Vector3(0,1,0),deg2rad(rotation_degrees.y)) + startpos
#	var railpos = get_pos_at_RailDistance(distance)
#	return railpos + (Vector3(1, 0, 0).rotated(Vector3(0,1,0), deg2rad(get_deg_at_RailDistance(distance)+90))*shift)


# local to this rail
func get_shifted_local_pos_at_RailDistance(distance: float, shift: float) -> Vector3:
	var newRadius: float = radius + shift
	if radius == 0:
		newRadius = 0
	var newDistance: float = distance
	if radius != 0:
		newDistance = distance * ((newRadius)/(radius))
	var circlePos: Vector2 = circle_get_pos(newRadius, newDistance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y+shift))




################################################### Easy Circle Functions:
func calculate_from_start_end(new_endpos: Vector3) -> void:
	var end = (new_endpos - startpos).rotated(Vector3.UP, deg2rad(-startrot))
	end.z = -end.z  # fix because in godot -z is forward, not +z
	end.x = max(end.x, 0)  # do not allow negative x, max angle is 180°!

	if abs(end.z) < 0.01:
		radius = 0
		length = end.length()
		update()
		return

	# m = end.z / end.x
	# m2 = - 1 / m
	# b = z - m2 * x
	var b = end.z + (end.x / end.z) * end.x

	radius = b/2
	# minimum radius! TODO: sensible value?
	if radius < 0 and radius > -10:
		radius = -10
	elif radius > 0 and radius < 10:
		radius = 10

	var angle = 2 * asin(end.length() / b) # asin( (len/2) / r )
	length = radius * angle

	endrot = startrot + angle

	update()


func circle_get_pos(r: float, dist: float) -> Vector2:
	if r == 0:
		return Vector2(dist, 0)
	## Calculate: Coordinate:
	var degree = circle_get_deg(r, dist)
	var middleOfCircle = Vector2(0, r)
	var a = cos(deg2rad(degree)) * r
	var b = sin(deg2rad(degree)) * r
	return middleOfCircle + Vector2(b, -a)  ## See HowACircleIsCalculated.pdf in github repository


func circle_get_deg(r: float, distance: float) -> float:
	if r == 0:
		return 0.0

	# Calculate needed degree:
	var extend = r * 2.0 * PI
	return float(distance / extend * 360)


#### Height Functions:
func get_height(distance: float) -> float:
	if is_instance_valid(parRail):
		var newRadius: float = radius - distanceToParallelRail
		if radius == 0:
			newRadius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * ((newRadius)/(radius))
		return parRail.get_height(newDistance)
	var startGradient: float = rad2deg(atan(startSlope/100))
	var endGradient: float = rad2deg(atan(endSlope/100))

	var basicHeight: float = float(tan(deg2rad(startGradient)) * distance)
	if endGradient - startGradient == 0:
		return basicHeight
	var heightRadius: float = (360*length)/(2*PI*(endGradient - startGradient))
	return circle_get_pos(heightRadius, distance).y + basicHeight


func get_heightRot(distance: float) -> float: ## Get Slope
	if is_instance_valid(parRail):
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


func get_tend_at_rail_distance(distance: float) -> float:
	if is_instance_valid(parRail):
		var newRadius: float = radius - distanceToParallelRail
		if radius == 0:
			newRadius = 0
		var newDistance: float = distance
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


func get_tendSlopeData() -> Dictionary:
	var d: Dictionary = {}
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

func set_tendSlopeData(data: Dictionary) -> void:
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


var automaticPointDistance: float = 50
func updateAutomaticTendency() -> void:
	if automaticTendency and radius != 0 and length > 3*automaticPointDistance:
		tend1Pos = automaticPointDistance
		tend2Pos = length -automaticPointDistance
		var tendency = 300/radius * 5
		tend1 = tendency
		tend2 = tendency
	elif automaticTendency and radius == 0:
		tend1 = 0
		tend2 = 0





###############################################################################
## Overhad Line
var vertices: PoolVector3Array
var indices: PoolIntArray


func update_overheadline(mesh: ArrayMesh) -> void:
	if mesh == null and has_node("OverheadLine"):
		get_node("OverheadLine").queue_free()
		return

	if get_node_or_null("OverheadLine") == null:
		var overheadline_mesh_instance: MeshInstance = MeshInstance.new()
		overheadline_mesh_instance.name = "OverheadLine"
		self.add_child(overheadline_mesh_instance)
		overheadline_mesh_instance.owner = self
	$OverheadLine.mesh = mesh


func calculate_overhadline_mesh() -> ArrayMesh:
	vertices = PoolVector3Array()
	indices = PoolIntArray()

	## Get Pole Points:
	var polePositions: Array = []
	polePositions.append(0)

	for trackObject in trackObjects:
		if not is_instance_valid(trackObject):
			continue
		if trackObject.description.begins_with("Pole"):
			var pos = 0
			if trackObject.on_rail_position == 0:
				pos += trackObject.distanceLength
			while pos <= trackObject.length:
				polePositions.append(pos + trackObject.on_rail_position)
				pos += trackObject.distanceLength
			if not trackObject.placeLast and polePositions.size() > 1:
				polePositions.remove(polePositions.size()-1)
			## Maybe here comes a break in. (If we only want to search for one trackobkject which begins with "pole"
	polePositions.append(length)
	polePositions = jEssentials.remove_duplicates(polePositions)
	for i in range (polePositions.size()-2):
		var _unused = buildOverheadLineSegment(polePositions[i], polePositions[i+1])

	if polePositions[polePositions.size()-2] != length:
		var _unused = buildOverheadLineSegment(polePositions[polePositions.size()-2], length)

	var mesh: ArrayMesh = ArrayMesh.new()

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, preload("res://Resources/Materials/Overhead_Line.tres"))
	return mesh


func buildOverheadLineSegment(start: float, end: float) -> Dictionary:
	var startPos = get_local_pos_at_RailDistance(start)+Vector3(0,overheadLineHeight1,0)
	var endPos = get_local_pos_at_RailDistance(end)+Vector3(0,overheadLineHeight1,0)
	var directVector = (endPos-startPos).normalized()
	var directDistance = startPos.distance_to(endPos)

	create3DLine(get_local_pos_at_RailDistance(start)+Vector3(0,overheadLineHeight1,0), get_local_pos_at_RailDistance(end)+Vector3(0,overheadLineHeight1,0), overheadLineThinkness)

	var segments = int(directDistance/10)
	if segments == 0:
		segments = 1
	var segmentDistance = directDistance/segments
	var currentPos1 = startPos
	var currentPos2 = startPos + directVector*segmentDistance
	for i in range(segments):
		create3DLine(currentPos1+Vector3(0,overheadLineHeight2-overheadLineHeight1-sin(i*segmentDistance/directDistance*PI)*line2HeightChangingFactor,0), currentPos2+Vector3(0,overheadLineHeight2-overheadLineHeight1-sin((i+1)*segmentDistance/directDistance*PI)*line2HeightChangingFactor,0), overheadLineThinkness)

		var lineHeight2ChangingAtHalf = sin((i+1)*segmentDistance/directDistance*PI)*line2HeightChangingFactor - (sin((i+1)*segmentDistance/directDistance*PI)*line2HeightChangingFactor - sin(i*segmentDistance/directDistance*PI)*line2HeightChangingFactor)/2.0
		create3DLineUp(currentPos1+directVector*segmentDistance/2, currentPos1+directVector*segmentDistance/2+Vector3(0,overheadLineHeight2-overheadLineHeight1-lineHeight2ChangingAtHalf,0), overheadLineThinkness)
		currentPos1+=directVector*segmentDistance
		currentPos2+=directVector*segmentDistance
	return {"vertices" : vertices, "indices" : indices}


func create3DLine(start: Vector3, end: Vector3, thinkness: float) -> void:
	var x = vertices.size()
	vertices.push_back(start + Vector3(0,thinkness,0))
	vertices.push_back(start + Vector3(0,0,-thinkness))
	vertices.push_back(start + Vector3(0,-thinkness,0))
	vertices.push_back(start + Vector3(0,0,thinkness))

	vertices.push_back(end + Vector3(0,thinkness,0))
	vertices.push_back(end + Vector3(0,0,-thinkness))
	vertices.push_back(end + Vector3(0,-thinkness,0))
	vertices.push_back(end + Vector3(0,0,thinkness))

	var indices_array := PoolIntArray([0+x, 2+x, 4+x,  2+x, 4+x, 6+x,  1+x, 5+x, 7+x,  1+x, 7+x, 3+x])

	indices.append_array(indices_array)


func create3DLineUp(start: Vector3, end: Vector3, thinkness: float) -> void:
	var x: int = vertices.size()
	vertices.push_back(start + Vector3(thinkness,0,0))
	vertices.push_back(start + Vector3(0,0,-thinkness))
	vertices.push_back(start + Vector3(-thinkness,0,0))
	vertices.push_back(start + Vector3(0,0,thinkness))

	vertices.push_back(end + Vector3(thinkness,0,0))
	vertices.push_back(end + Vector3(0,0,-thinkness))
	vertices.push_back(end + Vector3(-thinkness,0,0))
	vertices.push_back(end + Vector3(0,0,thinkness))

	var indices_array := PoolIntArray([0+x, 2+x, 4+x,  2+x, 4+x, 6+x,  1+x, 5+x, 7+x,  1+x, 7+x, 3+x])

	indices.append_array(indices_array)


###############################################################################
func update_positions_and_rotations() -> void:
	startpos = self.get_translation()
	startrot = self.rotation_degrees.y
	endrot = get_deg_at_RailDistance(length)
	endpos = get_pos_at_RailDistance(length)


export(Array, String) var isSwitchPart: Array = ["", ""]
# 0: is Rail at beginning part of switch? 1: is the rail at end part of switch if not
# It is saved the name of the other rail which is part of switch
func update_is_switch_part() -> void:
	isSwitchPart = ["", ""]
	var foundRailsAtBeginning: Array = []
	var foundRailsAtEnding: Array = []
	for rail in world.get_node("Rails").get_children():
		if rail == self:
			continue
		# Check for beginning
		if startpos.distance_to(rail.startpos) < 0.1 and abs(Math.normDeg(startrot) - Math.normDeg(rail.startrot)) < 1:
			foundRailsAtBeginning.append(rail.name)
		elif startpos.distance_to(rail.endpos) < 0.1 and abs(Math.normDeg(startrot) - Math.normDeg(rail.endrot+180)) < 1:
			foundRailsAtBeginning.append(rail.name)
		#check for ending
		if endpos.distance_to(rail.startpos) < 0.1 and abs((Math.normDeg(endrot) - Math.normDeg(rail.startrot+180))) < 1:
			foundRailsAtEnding.append(rail.name)
		elif endpos.distance_to(rail.endpos) < 0.1 and abs((Math.normDeg(endrot) - Math.normDeg(rail.endrot))) < 1:
			foundRailsAtEnding.append(rail.name)

	if foundRailsAtBeginning.size() > 0:
		isSwitchPart[0] = foundRailsAtBeginning[0]
		pass

	if foundRailsAtEnding.size() > 0:
		isSwitchPart[1] = foundRailsAtEnding[0]
		pass


var _connected_rails_at_beginning: Array = [] # Array of rail nodes
var _connected_rails_at_ending: Array = [] # Array of rail nodes
# The code of update_connections and update_is_switch_part can't be summarized, because
# we are searching for different rails in these functions. (Rotation of searched
# rails differs by 180 degrees)

# This function should be called before get_connected_rails_at_beginning()
# or get_connected_rails_at_ending once.
func update_connections() -> void:
	_connected_rails_at_beginning = []
	_connected_rails_at_ending = []
	for rail in world.get_node("Rails").get_children():
		if rail == self or startpos.distance_to(rail.startpos) > 1500:
			continue
		# Check for beginning
		if startpos.distance_to(rail.startpos) < 0.1 and abs(Math.normDeg(startrot) - Math.normDeg(rail.startrot+180)) < 1:
			_connected_rails_at_beginning.append(rail)
		elif startpos.distance_to(rail.endpos) < 0.1 and abs(Math.normDeg(startrot) - Math.normDeg(rail.endrot)) < 1:
			_connected_rails_at_beginning.append(rail)
		#check for ending
		if endpos.distance_to(rail.startpos) < 0.1 and abs((Math.normDeg(endrot) - Math.normDeg(rail.startrot))) < 1:
			_connected_rails_at_ending.append(rail)
		elif endpos.distance_to(rail.endpos) < 0.1 and abs((Math.normDeg(endrot) - Math.normDeg(rail.endrot+180))) < 1:
			_connected_rails_at_ending.append(rail)

# Returns array of rail nodes
func get_connected_rails_at_beginning() -> Array:
	return _connected_rails_at_beginning

# Returns array of rail nodes
func get_connected_rails_at_ending() -> Array:
	return _connected_rails_at_ending


func update_connection_arrows():
	_update_connection_arrows_not_recursive()
	for rail in _connected_rails_at_beginning:
		rail._update_connection_arrows_not_recursive()
	for rail in _connected_rails_at_ending:
		rail._update_connection_arrows_not_recursive()

var _last_calculation_of_update_connection_arrows = 0
func _update_connection_arrows_not_recursive():
	if _last_calculation_of_update_connection_arrows == get_tree().get_frame():
		return
	if not Root.Editor:
		return
	if world == null:
		# Hack (but what follows is so broken and hacky...)
		yield(self, "ready")
	update_connections()
	if not _connected_rails_at_beginning.empty():
		$Beginning/Beginning.material_override = preload("res://Data/Misc/Rail_Beginning_connected.tres")
	else:
		$Beginning/Beginning.material_override = preload("res://Data/Misc/Rail_Beginning_disconnected.tres")

	if not _connected_rails_at_ending.empty():
		$Ending/Ending.material_override = preload("res://Data/Misc/Rail_Ending_connected.tres")
	else:
		$Ending/Ending.material_override = preload("res://Data/Misc/Rail_Ending_disconnected.tres")

	_last_calculation_of_update_connection_arrows = get_tree().get_frame()
