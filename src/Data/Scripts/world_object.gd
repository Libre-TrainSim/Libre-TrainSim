class_name WorldObject
extends Spatial


func _ready() -> void:
	Root.connect("world_origin_shifted", self, "_on_world_origin_shifted")


func _on_world_origin_shifted(delta: Vector3):
	translation += delta
	self.update()


# overwrite this in child classes
func update():
	pass
