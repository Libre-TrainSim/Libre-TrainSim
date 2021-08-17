tool
extends StaticBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh = get_parent().mesh
	if mesh != null:
		$CollisionShape.shape = mesh.create_convex_shape()
		
	print("huhu")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
