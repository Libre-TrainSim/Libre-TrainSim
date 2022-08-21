class_name RoutePointStation
extends RoutePoint

export (String) var station_node_name := ""  # the RailLogic node of the station
export (String) var station_name := ""  # the name of the station displayed in GUI

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
