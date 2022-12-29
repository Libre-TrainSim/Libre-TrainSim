class_name RoutePointStation
extends RoutePoint

# the RailLogic node of the station
export (String) var station_node_name := "" setget _set_station_node_name
# the name of the station displayed in GUI
export (String) var station_name := ""

export (String) var approach_sound_path := ""
export (String) var arrival_sound_path := ""
export (String) var departure_sound_path := ""

# times in seconds (integer)
export (int) var duration_since_last_station := 0
export (int) var minimum_halt_time := 0
export (int) var planned_halt_time := 0
export (int) var signal_time := 0

var arrival_time := 0  # calculated
var departure_time := 0  # calculated

export (int) var stop_type := StopType.REGULAR

export (int) var leaving_persons := 0
export (int) var waiting_persons := 0


func get_description() -> String:
	match stop_type:
		StopType.BEGINNING:
			return "First Station: " + station_name
		StopType.REGULAR:
			return "Station: " + station_name
		StopType.DO_NOT_STOP:
			return "Station (don't stop): " + station_name
		StopType.END:
			return "Final Station: " + station_name
	return "Unknown"


func duplicate(deep: bool = true):
	var copy = get_script().new()

	copy.station_node_name = station_node_name
	copy.station_name = station_name
	copy.approach_sound_path = approach_sound_path
	copy.arrival_sound_path = arrival_sound_path
	copy.departure_sound_path = departure_sound_path
	copy.duration_since_last_station = duration_since_last_station
	copy.minimum_halt_time = minimum_halt_time
	copy.planned_halt_time = planned_halt_time
	copy.signal_time = signal_time
	copy.arrival_time = arrival_time
	copy.departure_time = departure_time
	copy.stop_type = stop_type
	copy.leaving_persons = leaving_persons
	copy.waiting_persons = waiting_persons

	return copy


func _set_station_node_name(new_name: String) -> void:
	station_node_name = new_name
	emit_route_change()
