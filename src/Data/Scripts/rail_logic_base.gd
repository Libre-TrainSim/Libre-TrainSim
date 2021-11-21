class_name RailLogic
extends WorldObject

onready var world: Node = find_parent("World")

var type: String = RailLogicTypes.LOGIC setget , _get_type
func _get_type() -> String:
	return RailLogicTypes.LOGIC


func set_scenario_data(_d: Dictionary) -> void:
	return


func get_scenario_data() -> Dictionary:
	return {}
