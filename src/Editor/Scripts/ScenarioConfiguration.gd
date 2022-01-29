extends Panel

onready var j_save_module = find_parent("ScenarioEditor").j_save_module

var routes: Dictionary = {}

var rail_logic_settings: Dictionary = {}

var current_route: String = ""

var world

onready var content_selector = get_parent().get_node("Content_Selector")

var route_manager = RouteManager.new()

func init():
	routes = j_save_module.get_value("routes", {})
	rail_logic_settings = j_save_module.get_value("rail_logic_settings", {})
	world = find_parent("ScenarioEditor").get_node("World")

	for signal_instance in world.get_node("Signals").get_children():
		if not rail_logic_settings.has(signal_instance.name) and signal_instance.type == "Signal":
			rail_logic_settings[signal_instance.name] = {
				operation_mode = SignalOperationMode.BLOCK,
				speed = -1,
				status = 0,
				signal_free_time = -1
			}
		if not rail_logic_settings.has(signal_instance.name) and signal_instance.type == "ContactPoint" :
			rail_logic_settings[signal_instance.name] = {
				enabled = false,
				affected_signal = "",
				affect_time = 0.1,
				new_speed_limit = -1,
				new_status = 1,
				enable_for_all_trains = true,
				specific_train = ""
			}

	update_route_list()
	update_rail_logic_ui()

	world.write_station_data(rail_logic_settings)



func _input(event):
	if Input.is_action_just_pressed("save"):
		save()


func save():
	j_save_module.save_value("rail_logic_settings", rail_logic_settings)
	j_save_module.write_to_disk()
	if current_route != "":
		routes[current_route].route_points = route_manager.get_route_data()
		j_save_module.save_value("routes", routes)
		j_save_module.write_to_disk()
		Logger.log("User manually saved.")
	find_parent("ScenarioEditor").show_message("Successfully saved!")

func _ready():
	update_ui_for_current_route()

func update_route_list():
	$TabContainer/Routes/Routes.clear()
	var route_names = []
	for key in routes.keys():
		route_names.append(key)
	$TabContainer/Routes/Routes.set_data(route_names)

func show_selection_message(text: String) -> void:
	get_parent().get_node("SelectMessage/HBoxContainer/Label").text = text
	get_parent().get_node("SelectMessage").show()


func hide_selection_message() -> void:
	get_parent().get_node("SelectMessage").hide()

func _on_Routes_user_added_entry(entry_name):
	routes[entry_name] = {
		"route_points" : [],
		"general_settings" : {
			"player_can_drive_this_route" : true,
			"interval_start" : 0,
			"interval" : 0,
			"interval_end" : 0,
			"train_name" : "",
			"activate_only_at_specific_routes" : false,
			"specific_routes" : [],
			"description" : ""
		},
	}
	j_save_module.save_value("routes", routes)

func _on_Routes_user_removed_entries(entry_names):
	var entry_name = entry_names[0]
	routes.erase(entry_name)
	j_save_module.save_value("routes", routes)
	set_current_route("")


func _on_Routes_user_renamed_entry(old_name, new_name):
	routes[new_name] = routes[old_name]
	routes.erase(old_name)
	j_save_module.save_value("routes", routes)
	set_current_route(new_name)


func _on_Routes_user_duplicated_entries(source_entry_names, duplicated_entry_names):
	var source_entry_name = source_entry_names[0]
	var duplicated_entry_name = duplicated_entry_names[0]
	routes[duplicated_entry_name] = routes[source_entry_name].duplicate(true)
	j_save_module.save_value("routes", routes)
	j_save_module.reload()
	routes = j_save_module.get_value("routes", {})
	update_route_list()
	set_current_route(duplicated_entry_name)

func _on_Routes_user_selected_entry(entry_name):
	set_current_route(entry_name)


func set_current_route(route_name : String) -> void:
	if current_route != "":
		routes[current_route].route_points = route_manager.get_route_data()
	current_route = route_name
	if current_route != "":
		route_manager.set_route_data(routes[current_route].route_points)
	else:
		route_manager.clear_route_data()
	update_ui_for_current_route()
	update_scenario_map()


func update_ui_for_current_route():
	if current_route == "":
		$TabContainer/Routes/RouteConfiguration.hide()
		return
	$TabContainer/Routes/RouteConfiguration.show()
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Playable.pressed = routes[current_route]["general_settings"]["player_can_drive_this_route"]
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalStart.set_data_in_seconds(routes[current_route]["general_settings"]["interval_start"])
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Interval.value = routes[current_route]["general_settings"]["interval"]
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalEnd.visible = routes[current_route].general_settings.interval != 0
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Label5.visible = routes[current_route].general_settings.interval != 0
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalEnd.set_data_in_seconds(routes[current_route]["general_settings"]["interval_end"])
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/TrainName.text = routes[current_route]["general_settings"]["train_name"]
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/RouteDescription.text = routes[current_route].general_settings.description

	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Label6.visible = not routes[current_route].general_settings.player_can_drive_this_route
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/ActivateOnlyAtSpecificRoutes.visible = not routes[current_route].general_settings.player_can_drive_this_route
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/ActivateOnlyAtSpecificRoutes.pressed = routes[current_route].general_settings.activate_only_at_specific_routes
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/P.visible = routes[current_route].general_settings.activate_only_at_specific_routes and not routes[current_route].general_settings.player_can_drive_this_route

	for child in $TabContainer/Routes/RouteConfiguration/GeneralSettings/P/SpecificRoutes.get_children():
		child.free()
	for route_name in routes.keys():
		if routes[route_name].general_settings.player_can_drive_this_route and route_name != current_route:
			var checkbox: CheckBox = CheckBox.new()
			checkbox.name = route_name
			checkbox.text = route_name
			checkbox.pressed = routes[current_route].general_settings.specific_routes.has(route_name)
			checkbox.connect("pressed", self, "_on_genereal_settings_SpecificRoutes_entry_pressed")
			$TabContainer/Routes/RouteConfiguration/GeneralSettings/P/SpecificRoutes.add_child(checkbox)


	update_route_point_list()
	update_route_point_settings()


func _on_Playable_pressed():
	routes[current_route]["general_settings"]["player_can_drive_this_route"] = $TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Playable.pressed
	update_route_point_list() # Because of updating, wether despawnpoints should be addable or not
	update_ui_for_current_route() # Because of updateing, if specific route config should be displayed or not


func _on_TrainName_text_changed(new_text):
	routes[current_route]["general_settings"]["train_name"] = new_text


func _on_IntervalEnd_time_set():
	routes[current_route]["general_settings"]["interval_end"] = $TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalEnd.get_data_in_seconds()


func _on_Interval_value_changed(value):
	routes[current_route]["general_settings"]["interval"] = value
	update_ui_for_current_route()

func _on_IntervalStart_time_set():
	routes[current_route]["general_settings"]["interval_start"] = $TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalStart.get_data_in_seconds()


func _on_ActivateOnlyAtSpecificRoutes_pressed():
	routes[current_route].general_settings.activate_only_at_specific_routes = $TabContainer/Routes/RouteConfiguration/GeneralSettings/G/ActivateOnlyAtSpecificRoutes.pressed
	update_ui_for_current_route()


func _on_RouteDescription_text_changed():
	routes[current_route].general_settings.description = $TabContainer/Routes/RouteConfiguration/GeneralSettings/RouteDescription.text


func _on_genereal_settings_SpecificRoutes_entry_pressed():
	var specific_routes: Array = []
	for checkbox in $TabContainer/Routes/RouteConfiguration/GeneralSettings/P/SpecificRoutes.get_children():
		if checkbox.pressed:
			specific_routes.append(checkbox.text)
	routes[current_route].general_settings.specific_routes = specific_routes


func update_route_point_list():
	var item_list = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList
	var selected_items = item_list.get_selected_items()
	item_list.clear()
	var size = route_manager.get_route_size()
	for i in range (size):
		item_list.add_item(route_manager.get_description_of_point(i))
	if (selected_items.size() > 0):
		item_list.select(selected_items[0])

	if current_route != "":
		$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint/Despawnpoint.visible = !routes[current_route].general_settings.player_can_drive_this_route



func _on_ListButtons_Up_pressed():
	var selected_items = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var selected_route_point_index = selected_items[0]
	if selected_route_point_index == 0:
		return
	route_manager.move_point_up(selected_route_point_index)
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(selected_route_point_index-1)


func _on_ListButtons_Down_pressed():
	var selected_items = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var selected_route_point_index = selected_items[0]
	if selected_route_point_index == route_manager.get_route_size()-1:
		return
	route_manager.move_point_down(selected_route_point_index)
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(selected_route_point_index+1)


func _on_ListButtons_Remove_pressed():
	var selected_items = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var selected_route_point_index = selected_items[0]
	route_manager.remove_point(selected_route_point_index)
	update_route_point_list()
	update_route_point_settings()


func _on_RouteList_Add_pressed():
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.visible = \
		!$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.visible

func update_route_point_settings():
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station.hide()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Waypoint.hide()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint.hide()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Despawnpoint.hide()

	var selected_items = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var index = selected_items[0]

	var route_point = route_manager.get_point(index)
	if route_point.type == RoutePointType.STATION:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station.show()
		update_station_point_settings()
	if route_point.type == RoutePointType.WAY_POINT:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Waypoint.show()
		update_way_point_settings()
	if route_point.type == RoutePointType.SPAWN_POINT:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint.show()
		update_spawn_point_settings()
	if route_point.type == RoutePointType.DESPAWN_POINT:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Despawnpoint.show()
		update_despawn_point_settings()


func _on_RouteList_ItemList_item_selected(index):
	update_route_point_settings()


enum ItemSelectionMode {
	NOTHING,
	STATION_POINT,
	WAY_POINT,
	SPAWN_POINT,
	DESPAWN_POINT,
	CONTACT_POINT_SIGNAL
}


var item_selection_mode = ItemSelectionMode.NOTHING
func _on_ScenarioMap_item_selected(path: String):
	match item_selection_mode:
		ItemSelectionMode.NOTHING:
			if path.begins_with("Signals/"):
				current_rail_logic_selected = path.replace("Signals/", "")
				$TabContainer.current_tab = 1
		ItemSelectionMode.STATION_POINT:
			current_rail_logic_selected = ""
			if path.begins_with("Signals/") and world.get_node(path).type == "Station":
				item_selection_mode = ItemSelectionMode.NOTHING
				hide_selection_message()
				_station_point_selected(path.replace("Signals/", ""))
		ItemSelectionMode.WAY_POINT:
			current_rail_logic_selected = ""
			if path.begins_with("Rails/"):
				item_selection_mode = ItemSelectionMode.NOTHING
				hide_selection_message()
				_rail_way_point_selected(path.replace("Rails/", ""))
		ItemSelectionMode.SPAWN_POINT:
			current_rail_logic_selected = ""
			if path.begins_with("Rails/"):
				item_selection_mode = ItemSelectionMode.NOTHING
				hide_selection_message()
				_rail_spawn_point_selected(path.replace("Rails/", ""))
		ItemSelectionMode.DESPAWN_POINT:
			current_rail_logic_selected = ""
			if path.begins_with("Rails/"):
				item_selection_mode = ItemSelectionMode.NOTHING
				hide_selection_message()
				_rail_despawn_point_selected(path.replace("Rails/", ""))
		ItemSelectionMode.CONTACT_POINT_SIGNAL:
			if path.begins_with("Signals/") and world.get_node(path).type == "Signal":
				item_selection_mode = ItemSelectionMode.NOTHING
				hide_selection_message()
				_contact_point_signal_selected(path.replace("Signals/", ""))


	update_rail_logic_ui()


func _on_SelectMessage_Cancel_pressed():
	item_selection_mode = ItemSelectionMode.NOTHING
	hide_selection_message()


## Station #########################################################################################
func _on_Station_pressed():
	route_manager.add_station_point()
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(route_manager.get_route_size()-1)
	update_route_point_settings()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.hide()
	_on_StationPoint_Select_pressed()


func _on_StationPoint_Select_pressed():
	item_selection_mode = ItemSelectionMode.STATION_POINT
	show_selection_message("Please select a station node (blue)!")


func _station_point_selected(node_name: String):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "node_name", node_name)
	update_route_point_list()
	update_station_point_settings()


func update_station_point_settings():
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	var p = route_manager.get_point(selected_route_point_index)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/StationNode/LineEdit.text = p.node_name
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/StationName.text = p.station_name
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/StopType.selected = p.stop_type
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/DurationSinceStationBefore.value = p.duration_since_station_before
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/PlannedHalttime.value = p.planned_halt_time
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/MinimalHalttime.value = p.minimal_halt_time
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/SignalTime.value = p.signal_time
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/WaitingPersons.value = p.waiting_persons
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/LeavingPersons.value = p.leaving_persons
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/HArrival/ArrivalSoundPath.text = p.arrival_sound_path
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/HDeparture/DepartureSoundPath.text = p.departure_sound_path
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/HApproach/ApproachSoundPath.text = p.approach_sound_path

	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label3.visible = p.stop_type != StopType.BEGINNING and p.stop_type != StopType.DO_NOT_STOP
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/DurationSinceStationBefore.visible = p.stop_type != StopType.BEGINNING and p.stop_type != StopType.DO_NOT_STOP

	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label4.visible = p.stop_type == StopType.REGULAR or p.stop_type == StopType.BEGINNING
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/PlannedHalttime.visible = p.stop_type == StopType.REGULAR or p.stop_type == StopType.BEGINNING

	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label5.visible = p.stop_type == StopType.REGULAR
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/MinimalHalttime.visible = p.stop_type == StopType.REGULAR

	if world.get_signal(p.node_name) != null:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label7.visible = world.get_signal(p.node_name).assigned_signal != ""
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/SignalTime.visible = world.get_signal(p.node_name).assigned_signal != ""
	else:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label7.visible = true
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/SignalTime.visible = true

	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label9.visible = p.stop_type == StopType.END or p.stop_type == StopType.REGULAR
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/HArrival.visible = p.stop_type == StopType.END or p.stop_type == StopType.REGULAR

	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label10.visible = p.stop_type == StopType.BEGINNING or p.stop_type == StopType.REGULAR
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/HDeparture.visible = p.stop_type == StopType.BEGINNING or p.stop_type == StopType.REGULAR

	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label11.visible = p.stop_type == StopType.END or p.stop_type == StopType.REGULAR
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/HApproach.visible = p.stop_type == StopType.END or p.stop_type == StopType.REGULAR

	# Update Planned Arrival and Departure:
	var calculated_point = route_manager.get_calculated_station_point_from_route_point_index(selected_route_point_index, routes[current_route].general_settings.interval_start)
	var arrival_text = "->"
	if p.stop_type == StopType.REGULAR or p.stop_type == StopType.END:
		arrival_text = "-> (Arrival: %s)" % Math.seconds_to_string(calculated_point.arrival_time)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/PlannedArrival.text = arrival_text

	var departure_text = ""
	if p.stop_type != StopType.END:
		departure_text = "(Departure: %s)" % Math.seconds_to_string(calculated_point.departure_time)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/PlannedDeparture.text = departure_text

func _on_StationPoint_StationName_text_changed(new_text):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "station_name", new_text)
	update_route_point_list()


func _on_StationPoint_StopType_item_selected(index):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "stop_type", index)
	update_route_point_list()
	update_station_point_settings()
	update_scenario_map()


func _on_StationPoint_DurationSinceStationBefore_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "duration_since_station_before", value)
	update_station_point_settings()


func _on_StationPoint_PlannedHalttime_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "planned_halt_time", value)
	update_station_point_settings()

func _on_StationPoint_MinimalHalttime_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "minimal_halt_time", value)


func _on_StationPoint_signal_time_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "signal_time", value)


func _on_StationPoint_WaitingPersons_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "waiting_persons", value)


func _on_StationPoint_LeavingPersons_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "leaving_persons", value)


func _on_SelectArrivalSoundPath_pressed():
	content_selector_index = 1
	content_selector.set_type(content_selector.SOUNDS)


func _on_SelectDepartureSoundPath_pressed():
	content_selector_index = 2
	content_selector.set_type(content_selector.SOUNDS)


func _on_SelectApporachSoundPath_pressed():
	content_selector_index = 0
	content_selector.set_type(content_selector.SOUNDS)


## Waypoint ########################################################################################
func _on_AddRoutePoint_Waypoint_pressed():
	route_manager.add_way_point()
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(route_manager.get_route_size()-1)
	update_route_point_settings()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.hide()
	_on_WayPoint_Rail_Select_pressed()


func update_way_point_settings() -> void:
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	var p = route_manager.get_point(selected_route_point_index)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Waypoint/Grid/Rail/LineEdit.text = p.rail_name
	update_scenario_map()

func _on_WayPoint_Rail_Select_pressed():
	item_selection_mode = ItemSelectionMode.WAY_POINT
	show_selection_message("Please select a rail!")


func _rail_way_point_selected(rail_name: String):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "rail_name", rail_name)
	update_route_point_list()
	update_way_point_settings()


## Spawnpoint ######################################################################################
func _on_AddRoutePoint_Spawnpoint_pressed():
	route_manager.add_spawm_point()
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(route_manager.get_route_size()-1)
	update_route_point_settings()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.hide()
	_on_SawnPoint_Rail_Select_pressed()


func update_spawn_point_settings() -> void:
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	var p = route_manager.get_point(selected_route_point_index)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint/Grid/Rail/LineEdit.text = p.rail_name
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint/Grid/Distance.value = p.distance
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint/Grid/InitialSpeed.value = p.initial_speed
	update_scenario_map()

func _on_SawnPoint_Rail_Select_pressed():
	item_selection_mode = ItemSelectionMode.SPAWN_POINT
	show_selection_message("Please select a rail!")


func _rail_spawn_point_selected(rail_name: String):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "rail_name", rail_name)
	update_route_point_list()
	update_spawn_point_settings()


func _on_SpawnPoint_Distance_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "distance", value)


func _on_SpawnPoint_InitialSpeed_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "initial_speed", value)


## Despawnpoint ####################################################################################
func _on_AddRoutePoint_Despawnpoint_pressed():
	route_manager.add_despawn_point()
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(route_manager.get_route_size()-1)
	update_route_point_settings()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.hide()
	_on_DespawnPoint_Rail_Select_pressed()


func update_despawn_point_settings():
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	var p = route_manager.get_point(selected_route_point_index)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Despawnpoint/Grid/Rail/LineEdit.text = p.rail_name
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Despawnpoint/Grid/Distance.value = p.distance
	update_scenario_map()

func _on_DespawnPoint_Rail_Select_pressed():
	item_selection_mode = ItemSelectionMode.DESPAWN_POINT
	show_selection_message("Please select a rail!")


func _rail_despawn_point_selected(rail_name: String):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "rail_name", rail_name)
	update_route_point_list()
	update_despawn_point_settings()


func _on_DespawnPoint_Distance_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	route_manager.set_data_of_point(selected_route_point_index, "distance", value)


## Rail Logic ######################################################################################
var current_rail_logic_selected: String = ""
func update_rail_logic_ui():
	if current_rail_logic_selected == "":
		$TabContainer/RailLogic/Label.text = "No Rail Logic selected"
		return

	$TabContainer/RailLogic/Signals.hide()
	$TabContainer/RailLogic/Stations.hide()
	$TabContainer/RailLogic/ContactPoints.hide()

	var rail_logic = world.get_signal(current_rail_logic_selected)
	if rail_logic.type == "Signal":
		$TabContainer/RailLogic/Signals.show()
		var sd: Dictionary = rail_logic_settings[rail_logic.name]

		sd.operation_mode = get_operation_mode_of_signal(current_rail_logic_selected)

		$TabContainer/RailLogic/Label.text = "Signal: " + current_rail_logic_selected
		$TabContainer/RailLogic/Signals/OperationMode/OptionButton.selected = sd.operation_mode
		$TabContainer/RailLogic/Signals/OperationMode/OptionButton.disabled = sd.operation_mode == SignalOperationMode.STATION
		$TabContainer/RailLogic/Signals/SpeedLimitSettings/EnableSpeedLimit/CheckBox.pressed = sd.speed != -1
		$TabContainer/RailLogic/Signals/SpeedLimitSettings/Speed/SpinBox.value = sd.speed
		$TabContainer/RailLogic/Signals/SpeedLimitSettings/Speed.visible = sd.speed != -1

		$TabContainer/RailLogic/Signals/ManualSettings.hide()
		$TabContainer/RailLogic/Signals/AttachedToStation.hide()
		match sd.operation_mode:
			SignalOperationMode.BLOCK:
				pass
			SignalOperationMode.STATION:
				var assigned_station = world.get_assigned_station_of_signal(current_rail_logic_selected)
				$TabContainer/RailLogic/Signals/AttachedToStation.show()
				$TabContainer/RailLogic/Signals/AttachedToStation.text = "Attached to station: " + assigned_station.name
			SignalOperationMode.MANUAL:
				$TabContainer/RailLogic/Signals/ManualSettings.show()
				$TabContainer/RailLogic/Signals/ManualSettings/GridContainer/Status.selected = sd.status
				$"TabContainer/RailLogic/Signals/ManualSettings/GridContainer/Enable Timed Free".pressed = sd.signal_free_time != -1
				$TabContainer/RailLogic/Signals/ManualSettings/GridContainer/TimeField.set_data_in_seconds(sd.signal_free_time)
				$TabContainer/RailLogic/Signals/ManualSettings/GridContainer/TimeField.visible = sd.signal_free_time != -1
	if rail_logic.type == "Station":
		$TabContainer/RailLogic/Stations.show()
		var sd: Dictionary
		if  rail_logic_settings.has(rail_logic.name):
			sd = rail_logic_settings[rail_logic.name]
		else:
			sd = {
				overwrite = false,
				assigned_signal = rail_logic.assigned_signal,
				enable_person_system = rail_logic.personSystem
			}
			rail_logic_settings[current_rail_logic_selected] = sd

		$TabContainer/RailLogic/Label.text = "Station: " + current_rail_logic_selected

		$TabContainer/RailLogic/Stations/Overwrite.pressed = sd.overwrite
		$TabContainer/RailLogic/Stations/GridContainer.visible = sd.overwrite
		$TabContainer/RailLogic/Stations/Label.visible = sd.overwrite
		$TabContainer/RailLogic/Stations/ReloadWorld.visible = sd.overwrite

		if not sd.overwrite:
			return

		$TabContainer/RailLogic/Stations/GridContainer/AssignedSignal.text = sd.assigned_signal
		$TabContainer/RailLogic/Stations/GridContainer/EnablePersonSystem.pressed = sd.enable_person_system
	if rail_logic.type == "ContactPoint":
		$TabContainer/RailLogic/ContactPoints.show()
		var sd: Dictionary = rail_logic_settings[rail_logic.name]

		$TabContainer/RailLogic/Label.text = "Contact Point: " + current_rail_logic_selected
		$TabContainer/RailLogic/ContactPoints/GridContainer/Enabled.pressed = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/AffectedSignal/LineEdit.text = sd.affected_signal
		$TabContainer/RailLogic/ContactPoints/GridContainer/AffectTime.value = sd.affect_time
		$TabContainer/RailLogic/ContactPoints/GridContainer/NewSpeedLimit.value = sd.new_speed_limit
		$TabContainer/RailLogic/ContactPoints/GridContainer/NewStatus.selected = sd.new_status
		$TabContainer/RailLogic/ContactPoints/GridContainer/EnableForAllTrains.pressed = sd.enable_for_all_trains
		$TabContainer/RailLogic/ContactPoints/GridContainer/SpecificTrains.text = sd.specific_train

		$TabContainer/RailLogic/ContactPoints/GridContainer/Label2.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/AffectedSignal/.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/Label3.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/AffectTime.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/Label4.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/NewSpeedLimit.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/Label5.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/NewStatus.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/Label6.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/EnableForAllTrains.visible = sd.enabled
		$TabContainer/RailLogic/ContactPoints/GridContainer/Label7.visible = sd.enabled and not sd.enable_for_all_trains
		$TabContainer/RailLogic/ContactPoints/GridContainer/SpecificTrains.visible = sd.enabled and not sd.enable_for_all_trains



func _on_RailLogic_Signal_OptionButton_item_selected(index):
	rail_logic_settings[current_rail_logic_selected].operation_mode = index
	update_rail_logic_ui()
	update_scenario_map()



func _on_RailLogic_Signal_CheckBox_pressed():
	if $TabContainer/RailLogic/Signals/SpeedLimitSettings/EnableSpeedLimit/CheckBox.pressed:
		rail_logic_settings[current_rail_logic_selected].speed = 0
	else:
		rail_logic_settings[current_rail_logic_selected].speed = -1
	update_rail_logic_ui()


func _on_RailLogic_Signal_SpinBox_value_changed(value):
	rail_logic_settings[current_rail_logic_selected].speed = value
	update_rail_logic_ui()


func _on_Signal_Status_item_selected(index):
	rail_logic_settings[current_rail_logic_selected].status = index
	update_rail_logic_ui()


func _on_RailLogic_Signal_Enable_Timed_Free_pressed():
	if $"TabContainer/RailLogic/Signals/ManualSettings/GridContainer/Enable Timed Free".pressed:
		rail_logic_settings[current_rail_logic_selected].signal_free_time = 0
	else:
		rail_logic_settings[current_rail_logic_selected].signal_free_time = -1
	update_rail_logic_ui()


func _on_RailLogic_Signal_TimeField_time_set():
	rail_logic_settings[current_rail_logic_selected].signal_free_time = $TabContainer/RailLogic/Signals/ManualSettings/GridContainer/TimeField.get_data_in_seconds()
	update_rail_logic_ui()


func _on_Stations_Overwrite_pressed():
	rail_logic_settings[current_rail_logic_selected].overwrite = $TabContainer/RailLogic/Stations/Overwrite.pressed
	update_rail_logic_ui()


func _on_RailLogic_Stations_AssignedSignal_text_changed(new_text):
	rail_logic_settings[current_rail_logic_selected].assigned_signal = new_text
	if rail_logic_settings.has(new_text):
		rail_logic_settings[new_text].operation_mode = SignalOperationMode.STATION

func _on_RailLogic_Stations_EnablePersonSystem_pressed():
	rail_logic_settings[current_rail_logic_selected].enable_person_system = $TabContainer/RailLogic/Stations/GridContainer/EnablePersonSystem.pressed
	update_rail_logic_ui()


func _on_Reload_World_pressed():
	world.write_station_data(rail_logic_settings)
	update_scenario_map()


func _on_ContactPoints_AffectedSignal_Select_pressed():
	item_selection_mode = ItemSelectionMode.CONTACT_POINT_SIGNAL
	show_selection_message("Please select a signal!")


func _contact_point_signal_selected(signal_name: String):
	rail_logic_settings[current_rail_logic_selected].affected_signal = signal_name
	update_rail_logic_ui()


func _on_ContactPoint_Enabled_pressed():
	rail_logic_settings[current_rail_logic_selected].enabled = $TabContainer/RailLogic/ContactPoints/GridContainer/Enabled.pressed
	update_rail_logic_ui()


func _on_ContactPoint_AffectTime_value_changed(value):
	rail_logic_settings[current_rail_logic_selected].affect_time = value
	update_rail_logic_ui()


func _on_ContactPoint_NewSpeedLimit_value_changed(value):
	rail_logic_settings[current_rail_logic_selected].new_speed_limit = value
	update_rail_logic_ui()


func _on_ContactPoint_NewStatus_item_selected(index):
	rail_logic_settings[current_rail_logic_selected].new_status = index
	update_rail_logic_ui()


func _on_ContactPoint_EnableForAllTrains_pressed():
	rail_logic_settings[current_rail_logic_selected].enable_for_all_trains = $TabContainer/RailLogic/ContactPoints/GridContainer/EnableForAllTrains.pressed
	update_rail_logic_ui()


func _on_ContactPoint_SpecificTrains_text_changed(new_text):
	rail_logic_settings[current_rail_logic_selected].specific_train = new_text


func get_operation_mode_of_signal(signal_name: String) -> int:
	if world == null:
		world = find_parent("ScenarioEditor").get_node("World")
	var rail_logic = world.get_signal(signal_name)
	if rail_logic.type == "Signal":
		if  rail_logic_settings.has(rail_logic.name):
			var assigned_station = world.get_assigned_station_of_signal(rail_logic.name)
			if assigned_station == null and rail_logic_settings[rail_logic.name].operation_mode == SignalOperationMode.STATION:
				rail_logic_settings[rail_logic.name].operation_mode = SignalOperationMode.BLOCK
			elif assigned_station != null:
				rail_logic_settings[rail_logic.name].operation_mode = SignalOperationMode.STATION
			return rail_logic_settings[rail_logic.name].operation_mode
		else:
			return rail_logic.operation_mode
	return -1


func update_scenario_map():
	find_parent("ScenarioEditor").get_node("ScenarioMap").update_map()


func _on_CheckIfRouteIsValid_pressed():
	check_route_for_errors()


func check_route_for_errors() -> void:
	var error_message = "\n"
	var route_points = route_manager.get_route_data()
	if route_manager.get_route_data().size() == 0:
		error_message += "Your route seems to be empty. Add some route points!\n\n"
		$TabContainer/Routes/RouteConfiguration/IsRouteValid/Messages.text = error_message
		return

	if route_manager.get_route_data().size() < 2:
		error_message += "Your route has to have at least two route points!\n\n"
		$TabContainer/Routes/RouteConfiguration/IsRouteValid/Messages.text = error_message
		return

	var station_points = route_manager.get_calculated_station_points(0)
	for station_point in station_points:
		if world.get_signal(station_point.node_name).length <= 0:
			error_message += "The station length of station '%s' is not valid! You have to fix this in the track editor.\n\n" % station_point.node_name

	if route_points[0].type != RoutePointType.SPAWN_POINT and not\
	(route_points[0].type == RoutePointType.STATION and route_points[0].stop_type == StopType.BEGINNING):
		error_message += "No beginning station or spawn point found. The first route point should be a beginning station or a spawn point.\n\n"

	if routes[current_route].general_settings.player_can_drive_this_route and not \
	(route_points.back().type == RoutePointType.STATION and route_points.back().stop_type == StopType.END):
		error_message += "The last route point has to be an end station. Otherwise the scenario won't be able to be finished.\n\n"

	if not routes[current_route].general_settings.player_can_drive_this_route and not\
	(route_points.back().type == RoutePointType.STATION and route_points.back().stop_type == StopType.END) and not\
	(route_points.back().type == RoutePointType.DESPAWN_POINT):
		error_message += "The last point has to be an end station or a despawn point. Otherwise npc trains can't despawn.\n\n"

	var baked_route: Array = route_manager.get_calculated_rail_route(world)
	if baked_route.size() == 0:
		var first_error_route_point: String = route_manager.get_description_of_point(route_manager.error_route_point_start_index)
		var second_error_route_point: String = route_manager.get_description_of_point(route_manager.error_route_point_end_index)
		error_message += "The train route can't be generated. Between '%s' and '%s' seems to be an error. Check, if a train could drive between these two points. Maybe some rails are not connected. Try adding a waypoint between these two route points to locate the error. Are your points in the correct order?\n\n" % [first_error_route_point, second_error_route_point]

	if routes[current_route].general_settings.player_can_drive_this_route:
		for route_point in route_points:
			if route_point.type == RoutePointType.DESPAWN_POINT:
				error_message += "In the route there is a despawn point. Routes which should be playable can't have a despawn point. Try deleting the depspawn point and add a endstation in the end of your route.\n\n"
				break

	var signals_with_manual_mode: Array = []
	for signal_instance in world.get_node("Signals").get_children():
		if signal_instance.type == "Signal" and get_operation_mode_of_signal(signal_instance.name) == SignalOperationMode.MANUAL:
			signals_with_manual_mode.append(signal_instance.name)
	if signals_with_manual_mode.size() != 0:
		error_message += "Just for notice: The following signals are set to manual mode. They don't turn automatically back to green if not explicit called by a script, a contact point or by the time field in the signal settings. If you don't want this change them to block mode: \n%s\n\n" % String(signals_with_manual_mode)

	for i in range(route_manager.get_route_size()):
		if i != 0 and ((route_points[i].type == RoutePointType.STATION and route_points[i].stop_type == StopType.BEGINNING) or route_points[i].type == RoutePointType.SPAWN_POINT):
			error_message += "The route point '%s' cant be at this position. A point of this type can be just at the very start of the route.\n\n" % route_manager.get_description_of_point(i)
		if i != route_manager.get_route_size()-1 and ((route_points[i].type == RoutePointType.STATION and route_points[i].stop_type == StopType.END) or route_points[i].type == RoutePointType.DESPAWN_POINT):
			error_message += "The route point '%s' cant be at this position. A point of this type can be just at the very end of the route.\n\n" % route_manager.get_description_of_point(i)

	for i in range(route_manager.get_route_size()):
		var route_point = route_points[i]
		match route_point.type:
			RoutePointType.STATION:
				if world.get_signal(route_point.node_name) == null:
					error_message += "The route point %s is not assigned to any station! Please fix that by clicking on 'Select' at the 'Node Name' setting of the route point and then select a blue arrow.\n\n" % route_manager.get_description_of_point(i)
			_:
				if world.get_rail(route_point.rail_name) == null:
					error_message += "The route point %s is not assigned to any rail! Please fix that by clicking on 'Select' at the 'Rail' setting of the route point and then select a blue line.\n\n" % route_manager.get_description_of_point(i)



	if error_message == "\n":
		error_message += "No errors found. Your route seems to be valid."

	$TabContainer/Routes/RouteConfiguration/IsRouteValid/Messages.text = error_message









var content_selector_index = -1
func _on_Content_Selector_resource_selected(complete_path):
	match content_selector_index:
		# Station: ApproachSoundPath
		0:
			content_selector_index = -1
			var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
			route_manager.set_data_of_point(selected_route_point_index, "approach_sound_path", complete_path)
			update_station_point_settings()
		# Station: Arrival Sound Path
		1:
			content_selector_index = -1
			var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
			route_manager.set_data_of_point(selected_route_point_index, "arrival_sound_path", complete_path)
			update_station_point_settings()
		# Station: Departure Sound Path
		2:
			content_selector_index = -1
			var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
			route_manager.set_data_of_point(selected_route_point_index, "departure_sound_path", complete_path)
			update_station_point_settings()
		_:
			content_selector_index = -1
