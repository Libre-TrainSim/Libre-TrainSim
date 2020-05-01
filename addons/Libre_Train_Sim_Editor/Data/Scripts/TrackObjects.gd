tool
extends MultiMeshInstance

export (String) var description = ""
export (String) var attachedRail 
export (int) var onRailPosition
export (float) var length

export (String) var objectPath
export var materialPaths = []
export (int) var sides = 0#0: No Side, 1: Left, 2: Right 4: Both
export (float) var spawnRate = 1
export (float) var rows
export (float) var distanceLength = 10
export (float) var distanceRows
export (float) var shift
export (float) var height
export (float) var rotationObjects = 0
export (bool) var randomLocation
export (float) var randomLocationFactor = 0.3
export (bool) var randomRotation
export (bool) var randomScale 
export (float) var randomScaleFactor = 0.2
export (bool) var placeLast = false
export (bool) var applySlopeRotation = false

export (bool) var wholeRail

var material_updated = false


export (bool) var update setget _update
export (bool) var meshSet = false

onready var world = find_parent("World")
var rail
var updated = false

func get_data():
	var d = {}
	d.description = description
	d.attachedRail = attachedRail
	d.onRailPosition = onRailPosition
	d.length = length
	d.objectPath = objectPath
	d.materialPaths = materialPaths
	d.sides = sides
	d.spawnRate = spawnRate
	d.rows = rows
	d.distanceLength = distanceLength
	d.distanceRows = distanceRows
	d.shift = shift
	d.height = height
	d.randomLocation = randomLocation
	d.randomLocationFactor = randomLocationFactor
	d.randomRotation = randomRotation
	d.randomScale = randomScale
	d.randomScaleFactor = randomScaleFactor
	d.wholeRail = wholeRail
	d.meshSet = meshSet
	d.multimesh = multimesh
	d.rotationObjects = rotationObjects
	d.placeLast = placeLast
	d.applySlopeRotation = applySlopeRotation
	return d
	
	
func set_data(d):
	description = d.description
	attachedRail = d.attachedRail
	onRailPosition = d.onRailPosition
	length = d.length
	objectPath = d.objectPath
	materialPaths = d.materialPaths
	sides = d.sides
	spawnRate = d.spawnRate
	rows = d.rows
	distanceLength = d.distanceLength
	distanceRows = d.distanceRows
	shift = d.shift
	height = d.height
	randomLocation = d.randomLocation
	randomLocationFactor = d.randomLocationFactor
	randomRotation = d.randomRotation
	randomScale = d.randomScale
	randomScaleFactor = d.randomScaleFactor
	wholeRail = d.wholeRail
	meshSet = d.meshSet
	multimesh = d.multimesh
	rotationObjects = d.rotationObjects
	placeLast = d.placeLast
	if d.has("applySlopeRotation"):
		applySlopeRotation = d.applySlopeRotation

func _ready():
	_update(true)
	pass
		
func _process(delta):
	if world == null:
		world = find_parent("World")
		if world != null:
			print("Updating Track Object...")
			_update(true)
		else:
			print("TrackObject cant find World Node, retrying..")
			return
	if rail == null:
		attach_to_rail()
	if not material_updated:
		_update(true)
		material_updated = true
	if updated == false:
		_update(true)
			

func attach_to_rail():
	if world == null: 
		return
	var rail = world.get_node("Rails").get_node(attachedRail)
	if rail != null:
		if not rail.trackObjects.has(self):
			rail.trackObjects.append(self)

func _update(newvar):
	updated = true
	world = find_parent("World")
	if world == null: return
	if wholeRail:
		var rail = world.get_node("Rails").get_node(attachedRail)
		if rail == null:
			queue_free()
			return
		onRailPosition = 0
		length = rail.length
	attach_to_rail()
	## Set to Rail:
	if world == null: return
	if world.has_node("Rails/"+attachedRail) and attachedRail != "":
		rail = world.get_node("Rails/"+attachedRail)
		translation = rail.get_pos_at_RailDistance(onRailPosition)
		#rotation_degrees.y = rail.getNextDeg(rail.radius, rail.rotation_degrees.y, onRailPosition)
	for x in range(materialPaths.size()):
		if materialPaths[x] != "":
			multimesh.mesh.surface_set_material(x, load(materialPaths[x]))
	
	## MultiMesh
	self.set_multimesh(self.multimesh.duplicate(false))
	
	if meshSet: ## Only set Mesh if needed
		return
	material_updated = false
	
	if objectPath == "" : return
	var mesh = load(objectPath).duplicate(true)
	self.multimesh.mesh = mesh
	
	var straightCount = int(length / distanceLength)
	if placeLast:
		straightCount += 1

	
	self.multimesh.instance_count = 0
	multimesh.visible_instance_count = 0
	if sides == 0:
		self.multimesh.instance_count = 0
	if sides == 1 or sides == 2:
		self.multimesh.instance_count = int(straightCount * rows)
	if sides == 3: 
		self.multimesh.instance_count = int(straightCount * rows)*2
	var idx = 0
	var railpos = onRailPosition
	for a in range(straightCount):
		for b in range(rows):
			if sides == 1 or sides == 3: ## Left Side
				if rand_range(0,1) < spawnRate:
					var position = rail.get_shifted_pos_at_RailDistance(railpos, -(shift+(b)*distanceRows)) - self.translation + Vector3(0,height,0)
					if randomLocation:
						var shiftx = rand_range(-distanceLength * randomLocationFactor, distanceLength * randomLocationFactor)
						var shiftz = rand_range(-distanceRows * randomLocationFactor, distanceRows * randomLocationFactor)
						position += Vector3(shiftx, 0, shiftz)
					var rot = rail.get_deg_at_RailDistance(railpos)
					if randomRotation:
						rot = rand_range(0,360)
					else:
						rot += rotationObjects
					var slopeRot = 0
					if applySlopeRotation:
						slopeRot = rail.get_heightRot(railpos)
					var scale = Vector3(1,1,1)
					if randomScale:
						var scaleval = rand_range(1 - randomScaleFactor, 1 + randomScaleFactor)
						scale = Vector3(scaleval, scaleval, scaleval)
					self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,0,1), deg2rad(slopeRot)).rotated(Vector3(0,1,0), deg2rad(rot)).scaled(scale), position))
					idx += 1
			if sides == 2 or sides == 3: ## Right Side
				if rand_range(0,1) < spawnRate:
					var position = rail.get_shifted_pos_at_RailDistance(railpos, (shift+(b)*distanceRows)) - self.translation + Vector3(0,height,0)
					if randomLocation:
						var shiftx = rand_range(-distanceLength * randomLocationFactor, distanceLength * randomLocationFactor)
						var shiftz = rand_range(-distanceRows * randomLocationFactor, distanceRows * randomLocationFactor)
						position += Vector3(shiftx, 0, shiftz)
					var rot = rail.get_deg_at_RailDistance(railpos)
					if randomRotation:
						rot = rand_range(0,360)
					else:
						rot += rotationObjects
					var slopeRot = 0
					if applySlopeRotation:
						slopeRot = rail.get_heightRot(railpos)
					var scale = Vector3(1,1,1)
					if randomScale:
						var scaleval = rand_range(1 - randomScaleFactor, 1 + randomScaleFactor)
						scale = Vector3(scaleval, scaleval, scaleval)
					self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,0,1), deg2rad(slopeRot)).rotated(Vector3(0,1,0), deg2rad(rot)).scaled(scale), position))
					idx += 1
		railpos += distanceLength
		self.multimesh.visible_instance_count = idx
	meshSet = true


