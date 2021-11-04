extends Node


func _ready():
	get_parent().get_node("MeshInstance").queue_free()
