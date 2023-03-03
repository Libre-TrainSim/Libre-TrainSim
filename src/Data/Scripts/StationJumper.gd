extends Control


var current_station_indices := [] # All indices of selectable stations

onready var item_list: ItemList = $StationJumper/ItemList


signal station_index_selected(station_index)


func _ready() -> void:
	item_list.connect("item_activated", self, "_on_ItemList_item_activated")


func show() -> void:
	if item_list.get_item_count() > 0:
		item_list.grab_focus()
	else:
		$StationJumper/HBoxContainer/Cancel.grab_focus()
	.show()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_Cancel_pressed()
		accept_event()


func update_list(player: Spatial) -> void:
	item_list.clear()
	current_station_indices.clear()
	for station_index in range(player.current_station_table_index, player.station_table.size()):
		current_station_indices.append(station_index)
	if player.is_in_station:
		current_station_indices.pop_front()
	current_station_indices.pop_back() # Remove endstation out of list.
	for station_index in current_station_indices:
		item_list.add_item(player.station_table[station_index].station_name)
	item_list.select(0)

	$StationJumper/Label2.text = tr("WARNING_JUMPING_SCENARIO")


func _on_Jump_pressed() -> void:
	if item_list.get_selected_items().size() != 0:
		emit_signal("station_index_selected", current_station_indices[item_list.get_selected_items()[0]])
	hide()


func _on_Cancel_pressed() -> void:
	hide()


func _on_ItemList_item_activated(index: int) -> void:
	_on_Jump_pressed()
