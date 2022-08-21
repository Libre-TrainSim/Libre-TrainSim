extends Panel

# local cache of things edited
var routes: Dictionary = {}
var rail_logic_settings: Dictionary = {}

var current_route: String = ""
var loaded_route: ScenarioRoute = null

var world
var scenario_editor

onready var content_selector = get_parent().get_node("Content_Selector")


func init():
	scenario_editor = find_parent("ScenarioEditor")
	world = scenario_editor.get_node("World")

	routes = scenario_editor.scenario_info.routes.duplicate(true)
	rail_logic_settings = scenario_editor.scenario_info.rail_logic_settings.duplicate(true)

	# FIXME: scenario editor crashes if no route is selected...
	set_current_route(routes.keys()[0])  # by default, select first route

	for signal_instance in world.get_node("Signals").get_children():
		if not rail_logic_settings.has(signal_instance.name):
			match signal_instance.type:
				RailLogicTypes.SIGNAL:
					rail_logic_settings[signal_instance.name] = SignalSettings.new()
				RailLogicTypes.CONTACT_POINT:
					rail_logic_settings[signal_instance.name] = ContactPointSettings.new()
				RailLogicTypes.STATION:
					rail_logic_settings[signal_instance.name] = StationSettings.new()

	update_route_list()
	update_rail_logic_ui()
	world.write_station_data(rail_logic_settings)


func _input(_event):
	if Input.is_action_just_pressed("save"):
		save()


func save():
	routes[current_route] = loaded_route.duplicate(true)
	scenario_editor.scenario_info.routes = routes.duplicate(true)
	scenario_editor.scenario_info.rail_logic_settings = rail_logic_settings.duplicate(true)
	scenario_editor.scenario_info.save_scenario()  # write to disk
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
	routes[entry_name] = ScenarioRoute.new()


func _on_Routes_user_removed_entries(entry_names):
	var entry_name = entry_names[0]
	routes.erase(entry_name)
	set_current_route("")


func _on_Routes_user_renamed_entry(old_name, new_name):
	routes[new_name] = routes[old_name]
	routes.erase(old_name)
	set_current_route(new_name)


func _on_Routes_user_duplicated_entries(source_entry_names, duplicated_entry_names):
	var source_entry_name = source_entry_names[0]
	var duplicated_entry_name = duplicated_entry_names[0]
	routes[duplicated_entry_name] = routes[source_entry_name].duplicate(true)
	update_route_list()
	set_current_route(duplicated_entry_name)


func _on_Routes_user_selected_entry(entry_name):
	set_current_route(entry_name)


func set_current_route(route_name : String) -> void:
	if is_instance_valid(loaded_route):
		routes[current_route] = loaded_route.duplicate(true)
	current_route = route_name
	loaded_route = routes[current_route].duplicate(true)
	update_ui_for_current_route()
	update_scenario_map()


func update_ui_for_current_route():
	if current_route == "":
		$TabContainer/Routes/RouteConfiguration.hide()
		return
	$TabContainer/Routes/RouteConfiguration.show()
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Playable.pressed = loaded_route.is_playable
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalStart.set_data_in_seconds(loaded_route.interval_start)
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Interval.value = loaded_route.interval
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalEnd.visible = loaded_route.interval != 0
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Label5.visible = loaded_route.interval != 0
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalEnd.set_data_in_seconds(loaded_route.interval_end)
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/TrainName.text = loaded_route.train_name
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/RouteDescription.text = loaded_route.description

	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Label6.visible = not loaded_route.is_playable
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/ActivateOnlyAtSpecificRoutes.visible = not loaded_route.is_playable
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/G/ActivateOnlyAtSpecificRoutes.pressed = loaded_route.activate_only_at_specific_routes
	$TabContainer/Routes/RouteConfiguration/GeneralSettings/P.visible = loaded_route.activate_only_at_specific_routes and not loaded_route.is_playable

	for child in $TabContainer/Routes/RouteConfiguration/GeneralSettings/P/SpecificRoutes.get_children():
		child.queue_free()

	for route_name in routes.keys():
		if routes[route_name].is_playable and route_name != current_route:
			var checkbox: CheckBox = CheckBox.new()
			checkbox.name = route_name
			checkbox.text = route_name
			checkbox.pressed = routes[current_route].specific_routes.has(route_name)
			checkbox.connect("pressed", self, "_on_genereal_settings_SpecificRoutes_entry_pressed")
			$TabContainer/Routes/RouteConfiguration/GeneralSettings/P/SpecificRoutes.add_child(checkbox)

	update_route_point_list()
	update_route_point_settings()


func _on_Playable_pressed():
	loaded_route.is_playable = $TabContainer/Routes/RouteConfiguration/GeneralSettings/G/Playable.pressed
	update_route_point_list() # Because of updating, wether despawnpoints should be addable or not
	update_ui_for_current_route() # Because of updateing, if specific route config should be displayed or not


func _on_TrainName_text_changed(new_text):
	loaded_route.train_name = new_text


func _on_IntervalEnd_time_set():
	loaded_route.interval_end = $TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalEnd.get_data_in_seconds()


func _on_Interval_value_changed(value):
	loaded_route.interval = value
	update_ui_for_current_route()

func _on_IntervalStart_time_set():
	loaded_route.interval_start = $TabContainer/Routes/RouteConfiguration/GeneralSettings/G/IntervalStart.get_data_in_seconds()


func _on_ActivateOnlyAtSpecificRoutes_pressed():
	loaded_route.activate_only_at_specific_routes = $TabContainer/Routes/RouteConfiguration/GeneralSettings/G/ActivateOnlyAtSpecificRoutes.pressed
	update_ui_for_current_route()


func _on_RouteDescription_text_changed():
	loaded_route.description = $TabContainer/Routes/RouteConfiguration/GeneralSettings/RouteDescription.text


func _on_genereal_settings_SpecificRoutes_entry_pressed():
	var specific_routes: Array = []
	for checkbox in $TabContainer/Routes/RouteConfiguration/GeneralSettings/P/SpecificRoutes.get_children():
		if checkbox.pressed:
			specific_routes.append(checkbox.text)
	loaded_route.specific_routes = specific_routes


func update_route_point_list():
	var item_list = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList
	var selected_items = item_list.get_selected_items()
	item_list.clear()
	var size = loaded_route.size()
	for i in range (size):
		item_list.add_item(loaded_route.get_point_description(i))
	if (selected_items.size() > 0):
		item_list.select(selected_items[0])

	if current_route != "":
		$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint/Despawnpoint.visible = not loaded_route.is_playable



func _on_ListButtons_Up_pressed():
	var selected_items = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var selected_route_point_index = selected_items[0]
	if selected_route_point_index == 0:
		return
	loaded_route.move_point_up(selected_route_point_index)
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(selected_route_point_index-1)


func _on_ListButtons_Down_pressed():
	var selected_items = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var selected_route_point_index = selected_items[0]
	if selected_route_point_index == loaded_route.size()-1:
		return
	loaded_route.move_point_down(selected_route_point_index)
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(selected_route_point_index+1)


func _on_ListButtons_Remove_pressed():
	var selected_items = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var selected_route_point_index = selected_items[0]
	loaded_route.remove_point(selected_route_point_index)
	update_route_point_list()
	update_route_point_settings()


func _on_RouteList_Add_pressed():
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.visible = \
		not $TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.visible


func update_route_point_settings():
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station.hide()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Waypoint.hide()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint.hide()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Despawnpoint.hide()

	var selected_items = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var index = selected_items[0]

	var route_point = loaded_route.get_point(index)
	if route_point is RoutePointStation:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station.show()
		update_station_point_settings()
	if route_point is RoutePointWayPoint:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Waypoint.show()
		update_way_point_settings()
	if route_point is RoutePointSpawnPoint:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint.show()
		update_spawn_point_settings()
	if route_point is RoutePointDespawnPoint:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Despawnpoint.show()
		update_despawn_point_settings()


func _on_RouteList_ItemList_item_selected(_index):
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
	loaded_route.route_points.append(RoutePointStation.new())
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(loaded_route.size()-1)
	update_route_point_settings()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.hide()
	_on_StationPoint_Select_pressed()


func _on_StationPoint_Select_pressed():
	item_selection_mode = ItemSelectionMode.STATION_POINT
	show_selection_message("Please select a station node (blue)!")


func _station_point_selected(node_name: String):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].station_node_name = node_name
	update_route_point_list()
	update_station_point_settings()


func update_station_point_settings():
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	var p = loaded_route.get_point(selected_route_point_index)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/StationNode/LineEdit.text = p.station_node_name
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/StationName.text = p.station_name
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/StopType.selected = p.stop_type
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/DurationSinceStationBefore.value = p.duration_since_last_station
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/PlannedHalttime.value = p.planned_halt_time
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/MinimalHalttime.value = p.minimum_halt_time
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

	if world.get_signal(p.station_node_name) != null:
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/Label7.visible = world.get_signal(p.station_node_name).assigned_signal != ""
		$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Station/Grid/SignalTime.visible = world.get_signal(p.station_node_name).assigned_signal != ""
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
	var calculated_point = loaded_route.get_calculated_station_point(selected_route_point_index, loaded_route.interval_start)
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
	loaded_route.route_points[selected_route_point_index].station_name = new_text
	update_route_point_list()


func _on_StationPoint_StopType_item_selected(index):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].stop_type = index
	update_route_point_list()
	update_station_point_settings()
	update_scenario_map()


func _on_StationPoint_DurationSinceStationBefore_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].duration_since_last_station = value
	update_station_point_settings()


func _on_StationPoint_PlannedHalttime_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].planned_halt_time = value
	update_station_point_settings()

func _on_StationPoint_MinimalHalttime_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].minimum_halt_time = value


func _on_StationPoint_signal_time_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].signal_time = value


func _on_StationPoint_WaitingPersons_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].waiting_persons = value


func _on_StationPoint_LeavingPersons_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].leaving_persons = value


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
	loaded_route.route_points.append(RoutePointWayPoint.new())
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(loaded_route.size()-1)
	update_route_point_settings()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.hide()
	_on_WayPoint_Rail_Select_pressed()


func update_way_point_settings() -> void:
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	var p = loaded_route.get_point(selected_route_point_index)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Waypoint/Grid/Rail/LineEdit.text = p.rail_name
	update_scenario_map()

func _on_WayPoint_Rail_Select_pressed():
	item_selection_mode = ItemSelectionMode.WAY_POINT
	show_selection_message("Please select a rail!")


func _rail_way_point_selected(rail_name: String):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].rail_name = rail_name
	update_route_point_list()
	update_way_point_settings()


## Spawnpoint ######################################################################################
func _on_AddRoutePoint_Spawnpoint_pressed():
	loaded_route.route_points.append(RoutePointSpawnPoint.new())
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(loaded_route.size()-1)
	update_route_point_settings()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.hide()
	_on_SawnPoint_Rail_Select_pressed()


func update_spawn_point_settings() -> void:
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	var p = loaded_route.get_point(selected_route_point_index)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint/Grid/Rail/LineEdit.text = p.rail_name
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint/Grid/Distance.value = p.distance
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Spawnpoint/Grid/InitialSpeed.value = p.initial_speed
	update_scenario_map()

func _on_SawnPoint_Rail_Select_pressed():
	item_selection_mode = ItemSelectionMode.SPAWN_POINT
	show_selection_message("Please select a rail!")


func _rail_spawn_point_selected(rail_name: String):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].rail_name = rail_name
	update_route_point_list()
	update_spawn_point_settings()


func _on_SpawnPoint_Distance_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].distance_on_rail = value


func _on_SpawnPoint_InitialSpeed_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].initial_speed = value


## Despawnpoint ####################################################################################
func _on_AddRoutePoint_Despawnpoint_pressed():
	loaded_route.route_points.append(RoutePointDespawnPoint.new())
	update_route_point_list()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.select(loaded_route.size()-1)
	update_route_point_settings()
	$TabContainer/Routes/RouteConfiguration/RoutePoints/AddRoutePoint.hide()
	_on_DespawnPoint_Rail_Select_pressed()


func update_despawn_point_settings():
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	var p = loaded_route.get_point(selected_route_point_index)
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Despawnpoint/Grid/Rail/LineEdit.text = p.rail_name
	$TabContainer/Routes/RouteConfiguration/RoutePoints/Configuration/Despawnpoint/Grid/Distance.value = p.distance
	update_scenario_map()

func _on_DespawnPoint_Rail_Select_pressed():
	item_selection_mode = ItemSelectionMode.DESPAWN_POINT
	show_selection_message("Please select a rail!")


func _rail_despawn_point_selected(rail_name: String):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].rail_name = rail_name
	update_route_point_list()
	update_despawn_point_settings()


func _on_DespawnPoint_Distance_value_changed(value):
	var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
	loaded_route.route_points[selected_route_point_index].distance_on_rail = value


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
		var sd: SignalSettings
		if rail_logic_settings.has(rail_logic.name):
			sd = rail_logic_settings[rail_logic.name]
		else:
			sd = SignalSettings.new()
			rail_logic_settings[rail_logic.name] = sd

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
		var sd: StationSettings
		if  rail_logic_settings.has(rail_logic.name):
			sd = rail_logic_settings[rail_logic.name]
		else:
			sd = StationSettings.new()
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
		var sd: ContactPointSettings
		if rail_logic_settings.has(rail_logic.name):
			sd = rail_logic_settings[rail_logic.name]
		else:
			sd = ContactPointSettings.new()
			rail_logic_settings[rail_logic.name] = sd

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
	var route_points = loaded_route.route_points
	if route_points.size() == 0:
		error_message += "Your route seems to be empty. Add some route points!\n\n"
		$TabContainer/Routes/RouteConfiguration/IsRouteValid/Messages.text = error_message
		return

	if route_points.size() < 2:
		error_message += "Your route has to have at least two route points!\n\n"
		$TabContainer/Routes/RouteConfiguration/IsRouteValid/Messages.text = error_message
		return

	var station_points = loaded_route.get_calculated_station_points(0)
	for station_point in station_points:
		if world.get_signal(station_point.station_node_name).length <= 0:
			error_message += "The station length of station '%s' is not valid! You have to fix this in the track editor.\n\n" % station_point.station_node_name

	if not route_points[0] is RoutePointSpawnPoint and not\
	(route_points[0] is RoutePointStation and route_points[0].stop_type == StopType.BEGINNING):
		error_message += "No beginning station or spawn point found. The first route point should be a beginning station or a spawn point.\n\n"

	if loaded_route.is_playable and not \
	(route_points.back() is RoutePointStation and route_points.back().stop_type == StopType.END):
		error_message += "The last route point has to be an end station. Otherwise the scenario won't be able to be finished.\n\n"

	if not loaded_route.is_playable and not\
	(route_points.back() is RoutePointStation and route_points.back().stop_type == StopType.END) and not\
	(route_points.back() is RoutePointDespawnPoint):
		error_message += "The last point has to be an end station or a despawn point. Otherwise npc trains can't despawn.\n\n"

	var baked_route: Array = loaded_route.get_calculated_rail_route(world)
	if baked_route.size() == 0:
		var first_error_route_point: String = loaded_route.get_point_description(loaded_route.error_route_point_start_index)
		var second_error_route_point: String = loaded_route.get_point_description(loaded_route.error_route_point_end_index)
		error_message += "The train route can't be generated. Between '%s' and '%s' seems to be an error. Check, if a train could drive between these two points. Maybe some rails are not connected. Try adding a waypoint between these two route points to locate the error. Are your points in the correct order?\n\n" % [first_error_route_point, second_error_route_point]

	if loaded_route.is_playable:
		for route_point in route_points:
			if route_point is RoutePointDespawnPoint:
				error_message += "In the route there is a despawn point. Routes which should be playable can't have a despawn point. Try deleting the depspawn point and add a endstation in the end of your route.\n\n"
				break

	var signals_with_manual_mode: Array = []
	for signal_instance in world.get_node("Signals").get_children():
		if signal_instance.type == "Signal" and get_operation_mode_of_signal(signal_instance.name) == SignalOperationMode.MANUAL:
			signals_with_manual_mode.append(signal_instance.name)
	if signals_with_manual_mode.size() != 0:
		error_message += "Just for notice: The following signals are set to manual mode. They don't turn automatically back to green if not explicit called by a script, a contact point or by the time field in the signal settings. If you don't want this change them to block mode: \n%s\n\n" % String(signals_with_manual_mode)

	for i in range(loaded_route.size()):
		if i != 0 and ((route_points[i] is RoutePointStation and route_points[i].stop_type == StopType.BEGINNING) or route_points[i] is RoutePointSpawnPoint):
			error_message += "The route point '%s' cant be at this position. A point of this type can be just at the very start of the route.\n\n" % loaded_route.get_point_description(i)
		if i != loaded_route.size()-1 and ((route_points[i] is RoutePointStation and route_points[i].stop_type == StopType.END) or route_points[i] is RoutePointDespawnPoint):
			error_message += "The route point '%s' cant be at this position. A point of this type can be just at the very end of the route.\n\n" % loaded_route.get_point_description(i)

	for i in range(loaded_route.size()):
		var route_point = route_points[i]
		if route_point is RoutePointStation:
			if world.get_signal(route_point.station_node_name) == null:
				error_message += "The route point %s is not assigned to any station! Please fix that by clicking on 'Select' at the 'Node Name' setting of the route point and then select a blue arrow.\n\n" % loaded_route.get_point_description(i)
		elif world.get_rail(route_point.rail_name) == null:
			error_message += "The route point %s is not assigned to any rail! Please fix that by clicking on 'Select' at the 'Rail' setting of the route point and then select a blue line.\n\n" % loaded_route.get_point_description(i)

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
			loaded_route.route_points[selected_route_point_index].approach_sound_path = complete_path
			update_station_point_settings()
		# Station: Arrival Sound Path
		1:
			content_selector_index = -1
			var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
			loaded_route.route_points[selected_route_point_index].arrival_sound_path = complete_path
			update_station_point_settings()
		# Station: Departure Sound Path
		2:
			content_selector_index = -1
			var selected_route_point_index = $TabContainer/Routes/RouteConfiguration/RoutePoints/ItemList.get_selected_items()[0]
			loaded_route.route_points[selected_route_point_index].departure_sound_path = complete_path
			update_station_point_settings()
		_:
			content_selector_index = -1
