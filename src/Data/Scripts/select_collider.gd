tool
extends StaticBody


func _ready():
	var mesh
	if get_parent().is_in_group("Signal"):
		if get_parent().get_node_or_null("Mesh") != null:
			mesh = get_parent().get_node_or_null("Mesh").mesh
			transform = get_parent().get_node_or_null("Mesh").transform
	else:
		mesh = get_parent().mesh
	if mesh != null:
		$CollisionShape.shape = mesh.create_convex_shape()
