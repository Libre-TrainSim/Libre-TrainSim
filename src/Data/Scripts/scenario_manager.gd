class_name ScenarioManager
extends Reference

var save_path: String
var routes: Dictionary
var rail_logic_settings: Dictionary

var j_save_module = jSaveModule.new()


func set_save_path(_save_path) -> void:
	save_path = _save_path
	j_save_module.set_save_path(_save_path)
	routes = j_save_module.get_value("routes", {})
	rail_logic_settings = j_save_module.get_value("rail_logic_settings", {})

func get_route_data() -> Dictionary:
	return routes.duplicate(true)


func get_available_route_names() -> Array:
	return routes.keys()


func get_rail_logic_settings():
	return rail_logic_settings.duplicate()


func get_available_start_times_of_route(route_name: String) -> Array:
	if not routes.has(route_name):
		return []
	var times: Array = []
	var time: int = routes[route_name].general_settings.interval_start
	times.append(time)
	if routes[route_name].general_settings.interval == 0:
		return times
	while(time < routes[route_name].general_settings.interval_end):
		time += routes[route_name].general_settings.interval * 60
		times.append(time)
	print(times)
	return times


func get_description() -> String:
	return ""


func is_route_playable(route_name: String) -> bool:
	return routes[route_name].general_settings.player_can_drive_this_route

