extends Node2D


func _ready():
	$Table/Arrival/Label.text = " " + TranslationServer.translate("ARRIVAL:") + " "
	$Table/Departure/Label.text = " " + TranslationServer.translate("DEPARTURE:") + " "
	$Table/Station/Label.text = " " + TranslationServer.translate("STATION:") + " "


func update_display(station_table, current_station_table_index, is_in_station):
	$CurrentStation.visible = is_in_station
	var arrString = ""
	var depString = ""
	var staString = ""
	for i in range (current_station_table_index, station_table.size()):

		if [StopType.BEGINNING, StopType.DO_NOT_HALT].has(station_table[i].stop_type):
			arrString += "\n"
		else:
			arrString += Math.time_seconds2String(station_table[i].arrival_time) + "\n"

		if station_table[i].stop_type == StopType.END:
			depString += "\n"
		else:
			depString += Math.time_seconds2String(station_table[i].departure_time) + "\n"

		staString += station_table[i].station_name + "\n"

	$Table/Arrival/Label2.text = arrString
	$Table/Departure/Label2.text = depString
	$Table/Station/Label2.text = staString

