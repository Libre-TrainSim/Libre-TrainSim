class_name RoutePoint
extends Resource


signal route_rebuild_required(changed_point)


func get_description() -> String:
	return "Unknown"


func emit_route_change() -> void:
	emit_signal("route_rebuild_required", self)
