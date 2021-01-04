extends Spatial

func _ready():
	$MeshInstance.queue_free()
	$MeshInstance2.queue_free()
