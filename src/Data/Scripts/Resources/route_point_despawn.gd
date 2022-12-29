class_name RoutePointDespawnPoint
extends RoutePoint

export (String) var rail_name := "" setget _set_rail_name
export (float) var distance_on_rail := 0.0


func get_description() -> String:
	return "Despawn Point"


func duplicate(deep: bool = true):
	var copy = get_script().new()

	copy.rail_name = rail_name
	copy.distance_on_rail = distance_on_rail

	return copy


func _set_rail_name(new_name: String) -> void:
	rail_name = new_name
	emit_route_change()
