class_name WarnSpeedLimit
extends RailLogic


export (float) var warn_speed: float


func _get_type() -> String:
	return RailLogicTypes.SPEED_LIMIT_WARNING


func _ready() -> void:
	if not Root.Editor:
		$SelectCollider.queue_free()
	set_to_rail()
