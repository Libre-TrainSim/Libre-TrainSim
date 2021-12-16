class_name SpeedLimit
extends RailLogic


export (float) var speed: float
export (String) var attached_rail: String
export (float) var on_rail_position: float
export (bool) var forward: bool


func set_speed(val: float) -> void:
	if not is_inside_tree():
		return
	speed = val
	$Viewport/Node2D/Label.text = str(int(val/10))


func _get_type() -> String:
	return RailLogicTypes.SPEED_LIMIT


func _ready() -> void:
	if not Root.Editor:
		$SelectCollider.queue_free()
	$Mesh.set_surface_material(2, $Mesh.get_surface_material(2).duplicate(true))
	$Mesh.get_surface_material(2).albedo_texture = $Viewport.get_texture()
	set_to_rail()



func set_to_rail() -> void:
	assert(is_inside_tree())
	assert(not not world)

	$Viewport/Node2D/Label.text = str(int(speed/10))

	if world.has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail = world.get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.translation = rail.get_pos_at_RailDistance(on_rail_position)
		self.rotation_degrees.y = rail.get_deg_at_RailDistance(on_rail_position)
		if not forward:
			self.rotation_degrees.y += 180
