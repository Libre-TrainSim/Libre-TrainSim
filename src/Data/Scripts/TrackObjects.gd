extends MultiMeshInstance

export (String) var description: String = ""
export (String) var attached_rail: String
export (float) var on_rail_position: float
export (float) var length: float

export (String) var objectPath: String = ""
export var materialPaths: Array = []
export (PlatformSide.TypeHint) var sides: int = 0 #0: No Side, 1: Left, 2: Right 4: Both
export (float) var spawnRate: float = 1
export (int) var rows: int
export (float) var distanceLength: float = 10
export (float) var distanceRows: float
export (float) var shift: float
export (float) var height: float
export (float) var rotationObjects: float = 0
export (bool) var randomLocation: bool
export (float) var randomLocationFactor: float = 0.3
export (bool) var randomRotation: bool
export (bool) var randomScale: bool
export (float) var randomScaleFactor: float = 0.2
export (bool) var placeLast: bool = false
export (bool) var applySlopeRotation: bool = false

export (int) var randomSeed: int = 0

export (bool) var wholeRail: bool = false

var material_updated: bool = false

onready var world: Node = find_parent("World")
var rail_node: Spatial
var updated: bool = false


func get_data() -> Dictionary:
	var d := {}
	d.description = description
	d.attached_rail = attached_rail
	d.on_rail_position = on_rail_position
	d.length = length
	d.objectPath = objectPath
	d.materialPaths = materialPaths.duplicate()
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
#	d.meshSet = meshSet
#	d.multimesh = multimesh.duplicate()
	d.rotationObjects = rotationObjects
	d.placeLast = placeLast
	d.applySlopeRotation = applySlopeRotation
	d.randomSeed = randomSeed
	return d


func set_data(d: Dictionary) -> void:
	description = d.description
	attached_rail = d.attached_rail
	on_rail_position = d.on_rail_position
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
#	meshSet = d.meshSet
#	multimesh = d.multimesh
	rotationObjects = d.rotationObjects
	placeLast = d.placeLast
	randomSeed = d.get("randomSeed", 0)
	if d.has("applySlopeRotation"):
		applySlopeRotation = d.applySlopeRotation


func attach_to_rail(_rail_node: Spatial) -> void:
	rail_node = _rail_node
	if not rail_node.trackObjects.has(self):
		rail_node.trackObjects.append(self)

func unattach_from_rail() -> void:
	if rail_node == null:
		return
	rail_node.trackObjects.erase(self)

func _exit_tree() -> void:
	unattach_from_rail()

func update(_rail_node: Spatial, res_cache := {}) -> void:
#	print("Loading Rail Attachment..")
	attach_to_rail(_rail_node)
	self.set_multimesh(self.multimesh.duplicate(false))
	if wholeRail:
		on_rail_position = 0
		length = rail_node.length

	translation = rail_node.get_pos_at_RailDistance(on_rail_position)
	if not res_cache.has(objectPath):
		if not ResourceLoader.exists(objectPath):
			Logger.err("Resource "+ objectPath + " not found! Skipping loading track bject "+ name + " ...", self)
			return
		res_cache[objectPath] = load(objectPath)

	multimesh.mesh = load(objectPath).duplicate()

	# This was sometimes out of bounds!!
	#for x in range(materialPaths.size()):
	# FIX:

	var count: int = int(min(multimesh.mesh.get_surface_count(), materialPaths.size()))
	for x in range(count):
		if materialPaths[x] != "":
			var material_path: String = materialPaths[x]
			if not res_cache.has(material_path):
				if not ResourceLoader.exists(material_path):
					continue
				res_cache[material_path] = load(material_path)
			multimesh.mesh.surface_set_material(x, res_cache[material_path])

	var straightCount: int = int(length / distanceLength)
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
	var idx: int = 0
	var railpos: float = on_rail_position
	seed(randomSeed)
	for _a in range(straightCount):
		for b in range(rows):
			if sides == 1 or sides == 3: ## Left Side
				if rand_range(0,1) < spawnRate:
					var position: Vector3 = rail_node.get_shifted_pos_at_RailDistance(railpos, -(shift+(b)*distanceRows)) - self.translation + Vector3(0,height,0)
					if randomLocation:
						var shiftx: float = rand_range(-distanceLength * randomLocationFactor, distanceLength * randomLocationFactor)
						var shiftz: float = rand_range(-distanceRows * randomLocationFactor, distanceRows * randomLocationFactor)
						position += Vector3(shiftx, 0, shiftz)
					var rot: float = rail_node.get_deg_at_RailDistance(railpos)
					if randomRotation:
						rot = rand_range(0,360)
					else:
						rot += rotationObjects
					var slopeRot = 0
					if applySlopeRotation:
						slopeRot = rail_node.get_heightRot(railpos)
					var scale := Vector3(1,1,1)
					if randomScale:
						var scaleval: float = rand_range(1 - randomScaleFactor, 1 + randomScaleFactor)
						scale = Vector3(scaleval, scaleval, scaleval)
					self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,0,1), deg2rad(slopeRot)).rotated(Vector3(0,1,0), deg2rad(rot)).scaled(scale), position))
					idx += 1
			if sides == 2 or sides == 3: ## Right Side
				if rand_range(0,1) < spawnRate:
					var position: Vector3 = rail_node.get_shifted_pos_at_RailDistance(railpos, (shift+(b)*distanceRows)) - self.translation + Vector3(0,height,0)
					if randomLocation:
						var shiftx: float = rand_range(-distanceLength * randomLocationFactor, distanceLength * randomLocationFactor)
						var shiftz: float = rand_range(-distanceRows * randomLocationFactor, distanceRows * randomLocationFactor)
						position += Vector3(shiftx, 0, shiftz)
					var rot: float = rail_node.get_deg_at_RailDistance(railpos)
					if randomRotation:
						rot = rand_range(0,360)
					else:
						rot += rotationObjects
					var slopeRot = 0
					if applySlopeRotation:
						slopeRot = rail_node.get_heightRot(railpos)
					var scale := Vector3(1,1,1)
					if randomScale:
						var scaleval: float = rand_range(1 - randomScaleFactor, 1 + randomScaleFactor)
						scale = Vector3(scaleval, scaleval, scaleval)
					self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,0,1), deg2rad(slopeRot)).rotated(Vector3(0,1,0), deg2rad(rot)).scaled(scale), position))
					idx += 1
		railpos += distanceLength
		self.multimesh.visible_instance_count = idx


func newSeed() -> void:
	randomize()
	randomSeed = int(rand_range(-1000000,1000000))
