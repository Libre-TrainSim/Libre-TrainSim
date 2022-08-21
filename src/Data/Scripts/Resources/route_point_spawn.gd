class_name RoutePointSpawnPoint
extends RoutePoint

export var rail_name := ""
export var distance_on_rail := 0.0
export var initial_speed := 0.0
export var initial_speed_limit := -1
export var forward := false  # direction of the rail


func get_description() -> String:
	return "Spawn Point"
