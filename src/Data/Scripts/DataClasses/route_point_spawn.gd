class_name RoutePointSpawnPoint
extends RoutePoint

var rail_name := ""
var distance_on_rail := 0.0
var initial_speed := 0.0
var initial_speed_limit := -1
var forward := false  # direction of the rail


func get_description() -> String:
	return "Spawn Point"
