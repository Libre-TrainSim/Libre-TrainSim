class_name RoutePointSpawnPoint
extends RoutePoint

export (String) var rail_name := "" setget _set_rail_name
export (float) var distance_on_rail := 0.0
export (float) var initial_speed := 0.0
export (int) var initial_speed_limit := -1
var forward := false  # direction of the rail


func get_description() -> String:
	return "Spawn Point"


func duplicate(deep: bool = true):
	var copy = get_script().new()

	copy.rail_name = rail_name
	copy.distance_on_rail = distance_on_rail
	copy.initial_speed = initial_speed
	copy.initial_speed_limit = initial_speed_limit
	copy.forward = forward

	return copy


func _set_rail_name(new_name: String) -> void:
	rail_name = new_name
	emit_route_change()
