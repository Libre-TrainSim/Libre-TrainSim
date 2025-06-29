extends MultiMeshInstance3D

@export var x: float = 100
@export var z: float = 50
@export var spacing: float = 4
@export var randomLocation: bool
@export var randomLocationFactor: float = 0.3
@export var randomRotation: bool
@export var randomScale: bool
@export var randomScaleFactor: float = 0.2

func _ready() -> void:
	if not Engine.is_editor_hint():
		$MeshInstance3D.visible = false
	$MeshInstance3D.position = Vector3(x/2,0,z/2)
	$MeshInstance3D.scale = Vector3(x,randf_range(0,10),z)
	Root.connect("world_origin_shifted", Callable(self, "_on_world_origin_shifted"))


func _on_world_origin_shifted(delta: Vector3):
	position += delta


func _update() -> void:
	## Cube For Editor:
	self.set_multimesh(self.multimesh.duplicate(false))
	self.multimesh.instance_count = int(x / spacing * z / spacing)
	var idx: int = 0
	for a in range(int(x / spacing)):
		for b in range(int(z / spacing)):
			var position: Vector3 = Vector3(a*spacing, 0, b * spacing)
			if randomLocation:
				var shiftx: float = randf_range(-spacing * randomLocationFactor, spacing * randomLocationFactor)
				var shiftz: float = randf_range(-spacing * randomLocationFactor, spacing * randomLocationFactor)
				position += Vector3(shiftx, 0, shiftz)
				#position = position.translated(Vector3(shiftx, 0, shiftz))

			var rot: float = 0
			if randomRotation:
				rot = randf_range(0,1)
				#position = position.rotated(Vector3(0, 1, 0), rand_range(0, 1))
				#position = Vector3(Basis().rotated(Vector3(0, 1, 0), rand_range(0, 1), position.
			var scale: Vector3 = Vector3(1,1,1)
			if randomScale:
				var scaleval: float = randf_range(1 - randomScaleFactor, 1 + randomScaleFactor)
				scale = Vector3(scaleval, scaleval, scaleval)

			self.multimesh.set_instance_transform(idx, Transform3D(Basis.rotated(Vector3(0,1,0), rot).scaled(scale), position))
			idx += 1
