extends Node


func _ready():
	get_parent().get_node("MeshInstance3D").queue_free()
