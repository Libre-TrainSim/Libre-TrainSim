class_name SpeedLimit
extends RailLogic


export (float) var speed: float setget set_speed


func set_speed(val: float) -> void:
	speed = val
	if not is_inside_tree():
		yield(self, "ready")
	$Viewport/Node2D/Label.text = str(int(val/10))


func _get_type() -> String:
	return RailLogicTypes.SPEED_LIMIT


func _ready() -> void:
	if not Root.Editor:
		$SelectCollider.queue_free()
	$Mesh.set_surface_material(2, $Mesh.get_surface_material(2).duplicate(true))
	$Mesh.get_surface_material(2).albedo_texture = $Viewport.get_texture()
	set_to_rail()
