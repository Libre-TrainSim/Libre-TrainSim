extends Spatial

var worldPos: Vector3 ## Only updated by the player in function sendDoorPositionsToCurrentStation()

func _ready():
	$MeshInstance.queue_free()
