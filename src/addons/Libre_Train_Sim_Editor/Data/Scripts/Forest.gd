tool
extends MultiMeshInstance

export (float) var x = 100
export (float) var z = 50
export (float) var spacing = 4
export (bool) var randomLocation
export (float) var randomLocationFactor = 0.3
export (bool) var randomRotation
export (bool) var randomScale 
export (float) var randomScaleFactor = 0.2
export (bool) var update setget _update

func _ready():
	if not Engine.is_editor_hint():
		$MeshInstance.visible = false
	$MeshInstance.translation = Vector3(x/2,0,z/2)
	$MeshInstance.scale = Vector3(x,rand_range(0,10),z)


func _update(newvar):
	## Cube For Editor:
	self.set_multimesh(self.multimesh.duplicate(false))
	self.multimesh.instance_count = int(x / spacing * z / spacing)
	var idx = 0
	for a in range(int(x / spacing)):
		for b in range(int(z / spacing)):
			var position = Vector3(a*spacing, 0, b * spacing)
			if randomLocation:
				var shiftx = rand_range(-spacing * randomLocationFactor, spacing * randomLocationFactor)
				var shiftz = rand_range(-spacing * randomLocationFactor, spacing * randomLocationFactor)
				position += Vector3(shiftx, 0, shiftz)
				#position = position.translated(Vector3(shiftx, 0, shiftz))
			
			var rot = 0
			if randomRotation:
				rot = rand_range(0,1)
				#position = position.rotated(Vector3(0, 1, 0), rand_range(0, 1))
				#position = Vector3(Basis().rotated(Vector3(0, 1, 0), rand_range(0, 1), position.
			var scale = Vector3(1,1,1)
			if randomScale:
				var scaleval = rand_range(1 - randomScaleFactor, 1 + randomScaleFactor)
				scale = Vector3(scaleval, scaleval, scaleval)
				
			self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,1,0), rot).scaled(scale), position))
			idx += 1
