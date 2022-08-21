class_name RoutePointWayPoint
extends RoutePoint

export var rail_name := ""


func get_description() -> String:
	return "Waypoint: " + rail_name
