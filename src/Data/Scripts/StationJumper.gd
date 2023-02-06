extends Control


var current_station_indices := [] # All indices of selectable stations


signal station_index_selected(station_index)


func _ready() -> void:
	$StationJumper/ItemList.connect("item_activated", self, "_on_ItemList_item_activated")


func show() -> void:
	if $StationJumper/ItemList.get_item_count() > 0:
		$StationJumper/ItemList.grab_focus()
	else:
		$StationJumper/HBoxContainer/Cancel.grab_focus()
	.show()


func update_list(player: Spatial) -> void:
	$StationJumper/ItemList.clear()
	current_station_indices.clear()
	for station_index in range(player.current_station_table_index, player.station_table.size()):
		current_station_indices.append(station_index)
	if player.is_in_station:
		current_station_indices.pop_front()
	current_station_indices.pop_back() # Remove endstation out of list.
	for station_index in current_station_indices:
		$StationJumper/ItemList.add_item(player.station_table[station_index].station_name)
	$StationJumper/ItemList.select(0)

	$StationJumper/Label2.text = tr("WARNING_JUMPING_SCENARIO")


func _on_Jump_pressed() -> void:
	if $StationJumper/ItemList.get_selected_items().size() != 0:
		emit_signal("station_index_selected", current_station_indices[$StationJumper/ItemList.get_selected_items()[0]])
	hide()


func _on_Cancel_pressed() -> void:
	hide()


func _on_ItemList_item_activated(index: int) -> void:
	_on_Jump_pressed()
