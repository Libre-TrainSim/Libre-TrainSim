class_name RouteManager
extends Reference

var route_data: Array = []

var station_point_pattern: Dictionary = {
	type = RoutePointType.STATION,
	node_name = "",
	station_name = "",
	stop_type = StopType.DO_NOT_STOP,
	duration_since_station_before = 300,
	planned_halt_time = 20,
	minimal_halt_time = 15,
	signal_time = 60,
	waiting_persons = 100,
	leaving_persons = 50,
	arrival_sound_path = "",
	departure_sound_path = "",
	approach_sound_path = "",
#	arrival_time = 0,  # Only added by get_calculated_station_*()
#	departure_time = 0, # Only added by get_calculated_station_*()
}



var way_point_pattern: Dictionary = {
	type = RoutePointType.WAY_POINT,
	rail_name = "",
}


var spawn_point_pattern: Dictionary = {
	type = RoutePointType.SPAWN_POINT,
	rail_name = "",
	distance = 0,
	initial_speed = 0,
	initial_speed_limit = -1,
}

var despawn_point_pattern: Dictionary = {
	type = RoutePointType.DESPAWN_POINT,
	rail_name = "",
	distance = 0,
}

func set_route_data(data: Array):
	calculated_rail_route = []
	route_data = data


func get_route_data():
	return route_data


func add_station_point() -> Dictionary:
	var station_point: Dictionary = station_point_pattern.duplicate(true)
	if route_data.empty():
		station_point.stop_type = StopType.BEGINNING
	route_data.append(station_point)
	return station_point


func add_way_point() -> Dictionary:
	var way_point: Dictionary = way_point_pattern.duplicate(true)
	route_data.append(way_point)
	return way_point


func add_spawm_point() -> Dictionary:
	var point: Dictionary = spawn_point_pattern.duplicate(true)
	route_data.append(point)
	return point


func add_despawn_point() -> Dictionary:
	var point: Dictionary = despawn_point_pattern.duplicate(true)
	route_data.append(point)
	return point


func get_description_of_point(index : int) -> String:
	var point: Dictionary = route_data[index]
	if point.type == RoutePointType.STATION:
		match point.stop_type:
			StopType.BEGINNING:
				return "Beginning Station: " + point.station_name
			StopType.REGULAR:
				return "Station: " + point.station_name
			StopType.DO_NOT_STOP:
				return "Station (Don't halt): " + point.station_name
			StopType.END:
				return "Ending Station: " + point.station_name
	elif point.type == RoutePointType.WAY_POINT:
		return "Waypoint: " + point.rail_name
	elif point.type == RoutePointType.SPAWN_POINT:
		return "Spawnpoint"
	elif point.type == RoutePointType.DESPAWN_POINT:
		return "Despawnpoint"
	return "Unknown"


# (Read Only)
func get_point(index : int) -> Dictionary:
	if index >= get_route_size():
		Logger.err("Point index does not exist for actual list! Aborting...", "Route Manager")
		return {}
	return route_data[index].duplicate()


func get_route_size() -> int:
	return route_data.size()


func set_data_of_point(index: int, key: String, value) -> void:
	if index >= get_route_size():
		Logger.err("Point index does not exist for actual list! Aborting...", "Route Manager")
	if route_data[index].keys().has(key):
		route_data[index][key] = value


func move_point_up(index: int) -> void:
	if index == 0:
		return
	var tmp: Dictionary = route_data[index -1]
	route_data[index-1] = route_data[index]
	route_data[index] = tmp


func move_point_down(index: int) -> void:
	if index >= route_data.size():
		return
	var tmp: Dictionary = route_data[index +1]
	route_data[index+1] = route_data[index]
	route_data[index] = tmp


func remove_point(index : int) -> void:
	route_data.remove(index)


func clear_route_data() -> void:
	route_data.clear()


func get_calculated_station_points(start_time: int) -> Array:
	var time: int = start_time
	var station_table: Array = []

	for route_point in route_data:
		if route_point.type != RoutePointType.STATION:
			continue
		var p: Dictionary = route_point.duplicate()
		if p.stop_type != StopType.BEGINNING:
			time += p.duration_since_station_before
		p.arrival_time = time
		time += route_point.planned_halt_time
		p.departure_time = time
		station_table.append(p)

	return station_table


func get_station_index_from_route_point_index(index: int):
	if route_data[index].type != RoutePointType.STATION:
		return -1
	var station_index: int = 0
	for i in range (index):
		if route_data[i].type == RoutePointType.STATION:
			station_index += 1
	print(station_index)
	return station_index


func get_calculated_station_point_from_route_point_index(index: int, start_time: int):
	var station_index: int = get_station_index_from_route_point_index(index)
	var station_table: Array = get_calculated_station_points(start_time)
	return station_table[station_index]

# If the route can't be generated then in these variables both enclosing routpoints of the error are saved
var error_route_point_start_index: int
var error_route_point_end_index: int

var calculated_rail_route: Array = []
# Entry:
#{
#	rail: Node,
#	forward: bool
#}
func get_calculated_rail_route(world: Node) -> Array:
	world.update_rail_connections()
	var rail_route: Array = []
	for i in range (get_route_size()-1):
		# get start and end rails for calculation
		var start_end_rails: Array = []
		var start_direction_set: bool = false
		var forward: bool = true
		for j in range(2):
			var route_point: Dictionary = route_data[i+j]
			if route_point.type == RoutePointType.STATION:
				var station: Node = world.get_signal(route_point.node_name)
				if station == null:
					return []
				start_end_rails.append(world.get_rail(station.attached_rail))
				if j == 0 and rail_route.size() == 0:
					start_direction_set = true
					forward = station.forward
			else:
				start_end_rails.append(world.get_rail(route_point.rail_name))
		if rail_route.size() != 0:
			start_direction_set = true
			forward = rail_route.back().forward

		# calculate route
		var calculated_route: Array = []
		if not start_direction_set:
			var possible_route_1: Array = world.get_path_from_to(start_end_rails[0], true, start_end_rails[1])
			var possible_route_2: Array = world.get_path_from_to(start_end_rails[0], false, start_end_rails[1])
			if possible_route_1.size() > possible_route_2.size():
				calculated_route = possible_route_1
			else:
				calculated_route = possible_route_2
		else:
			calculated_route = world.get_path_from_to(start_end_rails[0], forward, start_end_rails[1])

		# If no route found - error!
		if calculated_route.size() == 0:
			error_route_point_start_index = i
			error_route_point_end_index = i+1
			return []

		# Append calculated route to whole route:
		if rail_route.size() > 0:
			rail_route.pop_back()
		rail_route.append_array(calculated_route)
	calculated_rail_route = rail_route.duplicate(true)
	return rail_route


# Once before get_calculated_rail_route() should be called
func get_spawn_position(train_length, world: Node) -> Dictionary:
	var start_point: Dictionary = route_data[0]
	var return_value: Dictionary = spawn_point_pattern.duplicate(true)
	if start_point.type == RoutePointType.SPAWN_POINT:
		return_value = start_point
		return_value.forward = calculated_rail_route[0].forward
	elif start_point.type == RoutePointType.STATION:
		var station_node: Node = world.get_signal(start_point.node_name)
		return_value.distance = station_node.get_perfect_halt_distance_on_rail(train_length)
		return_value.rail_name = station_node.attached_rail
		return_value.forward = station_node.forward
		return_value.initial_speed = 0
		return_value.initial_speed_limit = -1
	else:
		return {}
	return return_value


func get_despawn_information() -> Dictionary:
	return route_data.back().duplicate(true)


func get_minimal_platform_length(world: Node) -> int:
	var minimal_platform_length: int = 1000000000000000
	for route_point in route_data:
		if route_point.type == RoutePointType.STATION and route_point.stop_type != StopType.DO_NOT_STOP:
				var station_node: Node = world.get_signal(route_point.node_name)
				if minimal_platform_length > station_node.length:
					minimal_platform_length = station_node.length
	return minimal_platform_length
