extends Spatial

var worldPos ## Only updated by the player in function sendDoorPositionsToCurrentStation()

func _ready():
	$MeshInstance.queue_free()
