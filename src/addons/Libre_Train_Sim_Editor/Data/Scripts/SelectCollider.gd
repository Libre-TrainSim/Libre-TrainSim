tool
extends StaticBody


# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh = get_parent().mesh
	if mesh != null:
		$CollisionShape.shape = mesh.create_convex_shape()
