class_name RailLogic
extends WorldObject


export var attached_rail := ""
export var on_rail_position: float = 0.0
export var forward := true


var type: String = RailLogicTypes.LOGIC setget , _get_type
var rail: WorldObject = null


onready var world: Node = find_parent("World")


func _get_type() -> String:
	return RailLogicTypes.LOGIC


func set_scenario_data(_d: Dictionary) -> void:
	return


func get_scenario_data() -> Dictionary:
	return {}


func set_to_rail(skip_in_scenario_editor := false) -> void:
	assert(is_inside_tree())
	assert(not not world)


	if attached_rail.empty() or not world.has_node("Rails/"+attached_rail):
		Logger.warn("Cannot set %s '%s' to rail '%s'" % [self.type, name, attached_rail], self)
		return
	rail = world.get_node("Rails/"+attached_rail)

	if skip_in_scenario_editor and Root.scenario_editor:
		return

	rail.register_signal(self.name, on_rail_position)
	self.transform = rail.get_global_transform_at_distance(on_rail_position)
	if not forward:
		rotation.y += PI
