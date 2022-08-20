class_name RoutePointStation
extends RoutePoint

export var station_node_name := ""  # the RailLogic node of the station
export var station_name := ""  # the name of the station displayed in GUI

export var approach_sound_path := ""
export var arrival_sound_path := ""
export var departure_sound_path := ""

# times in seconds (integer)
export var duration_since_last_station := 0
export var minimum_halt_time := 0
export var planned_halt_time := 0
export var signal_time := 0

var arrival_time := 0  # calculated
var departure_time := 0  # calculated

export var stop_type := StopType.REGULAR

export var leaving_persons := 0.0
export var waiting_persons := 0.0

func _init() -> void:
	type = RoutePointType.STATION


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
