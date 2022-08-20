class_name RoutePointWayPoint
extends RoutePoint

var rail_name := ""

func _init() -> void:
	type = RoutePointType.WAY_POINT


func get_description() -> String:
	return "Waypoint: " + rail_name
