class_name WorldObject
extends Node3D


func _ready() -> void:
	Root.connect("world_origin_shifted", Callable(self, "_on_world_origin_shifted"))


func _on_world_origin_shifted(delta: Vector3):
	position += delta
	self.update()


# overwrite this in child classes
func update():
	pass
