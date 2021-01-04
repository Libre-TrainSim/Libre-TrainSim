extends Spatial

export (Array,String) var connections

func _ready():
	$MeshInstance.queue_free()

