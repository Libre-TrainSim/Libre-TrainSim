class_name RoutePointDespawnPoint
extends RoutePoint

var rail_name := ""
var distance_on_rail := 0.0

func _init() -> void:
	type = RoutePointType.DESPAWN_POINT


func get_description() -> String:
	return "Despawn Point"
