class_name RoutePointSpawnPoint
extends RoutePoint

export (String) var rail_name := ""
export (float) var distance_on_rail := 0.0
export (float) var initial_speed := 0.0
export (int) var initial_speed_limit := -1
var forward := false  # direction of the rail


func get_description() -> String:
	return "Spawn Point"
