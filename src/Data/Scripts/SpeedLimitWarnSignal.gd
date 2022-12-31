class_name WarnSpeedLimit
extends RailLogic


export (float) var warn_speed: float


func _get_type() -> String:
	return RailLogicTypes.SPEED_LIMIT_WARNING


func _ready() -> void:
	if not Root.Editor:
		$SelectCollider.queue_free()
	$Mesh.set_surface_material(2, $Mesh.get_surface_material(2).duplicate(true))
	$Mesh.get_surface_material(2).albedo_texture = $Viewport.get_texture()
	set_to_rail()
