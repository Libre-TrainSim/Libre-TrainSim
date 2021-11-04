extends Spatial

export (Array,String) var connections: Array

func _ready():
	$MeshInstance.queue_free()

