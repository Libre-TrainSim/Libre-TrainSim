tool
extends Spatial

const type = "Speed"

export (int) var speed
export (String) var attached_rail
export (int) var on_rail_position
export (bool) var forward


func set_speed(val):
	if not is_inside_tree():
		return
	speed = val
	$Viewport/Node2D/Label.text = str(int(val/10))


func _ready():
	if Engine.is_editor_hint():
		if get_parent().name == "Signals":
			return
		if get_parent().is_in_group("Rail"):
			attached_rail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		set_to_rail()

	if not Engine.is_editor_hint():
		$Mesh.set_surface_material(2, $Mesh.get_surface_material(2).duplicate(true))
		$Mesh.get_surface_material(2).albedo_texture = $Viewport.get_texture()
		set_to_rail()


func set_to_rail():
	if !is_inside_tree():
		return
	if not find_parent("World"):
		print(name, " can't find World Parent!")
		return

	$Viewport/Node2D/Label.text = str(int(speed/10))

	if find_parent("World").has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail = find_parent("World").get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.translation = rail.get_pos_at_RailDistance(on_rail_position)
		self.rotation_degrees.y = rail.get_deg_at_RailDistance(on_rail_position)
		if not forward:
			self.rotation_degrees.y += 180


func set_scenario_data(d):
	return


func get_scenario_data():
	return null
