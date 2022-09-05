class_name RoutePointWayPoint
extends RoutePoint

export (String) var rail_name := ""


func get_description() -> String:
	return "Waypoint: " + rail_name


func duplicate(deep: bool = true):
	var copy = get_script().new()

	copy.rail_name = rail_name

	return copy
