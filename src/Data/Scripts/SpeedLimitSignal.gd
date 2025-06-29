class_name SpeedLimit
extends RailLogic


@export var speed: float: set = set_velocity


func set_velocity(val: float) -> void:
	speed = val
	if not is_inside_tree():
		await self.ready
	$Label3D.text = str(int(val/10))


func _get_type() -> String:
	return RailLogicTypes.SPEED_LIMIT


func _ready() -> void:
	if not Root.Editor:
		$SelectCollider.queue_free()
	set_to_rail()
