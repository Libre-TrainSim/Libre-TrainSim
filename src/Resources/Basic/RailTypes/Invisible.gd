tool
extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.editor_hint:
		get_parent().get_node("MeshInstance").queue_free()
