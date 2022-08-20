class_name RoutePointDespawnPoint
extends RoutePoint

export var rail_name := ""
export var distance_on_rail := 0.0

func _init() -> void:
	type = RoutePointType.DESPAWN_POINT


func get_description() -> String:
	return "Despawn Point"
