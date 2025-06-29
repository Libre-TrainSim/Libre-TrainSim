class_name RoutePointSpawnPoint
extends RoutePoint

@export (String) var rail_name := "": set = _set_rail_name
@export var distance_on_rail: float = 0.0
@export var initial_speed: float = 0.0
@export var initial_speed_limit: int = -1
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
