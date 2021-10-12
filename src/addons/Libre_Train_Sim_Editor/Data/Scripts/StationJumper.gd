extends Control


var current_station_indices = [] # All indices of selectable stations


signal station_index_selected(station_index)


func update_list(player):
	$StationJumper/ItemList.clear()
	current_station_indices.clear()
	var stations = player.stations
	for station_index in range(stations["stationName"].size()):
		if stations["passed"][station_index] == false:
			current_station_indices.append(station_index)
	if player.isInStation:
		current_station_indices.pop_front()
	for station_index in current_station_indices:
		$StationJumper/ItemList.add_item(stations["stationName"][station_index])

	$StationJumper/Label2.text = tr("WARNING_JUMPING_SCENARIO")

func _on_Jump_pressed():
	if $StationJumper/ItemList.get_selected_items().size() != 0:
		emit_signal("station_index_selected", current_station_indices[$StationJumper/ItemList.get_selected_items()[0]])
	hide()


func _on_Cancel_pressed():
	hide()
