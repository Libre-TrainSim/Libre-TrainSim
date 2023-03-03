extends Panel

var selected_track: String = ""


func _ready() -> void:
	$ScenarioList.connect("visibility_changed", self, "_on_ScenarioList_visibility_changed")


func show() -> void:
	$TrackList/ItemList.grab_focus()
	.show()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if $ScenarioList.visible:
			_on_Back_ScenarioList_pressed()
		else:
			_on_Back_TrackList_pressed()
		accept_event()


func update_track_list():
	$TrackList/ItemList.clear()
	for track in ContentLoader.repo.worlds:
		$TrackList/ItemList.add_item(track.get_file().get_basename())

	var tracks = ContentLoader.get_editor_tracks()
	for track in tracks.keys():
		$TrackList/ItemList.add_item("Track-Editor: " + track.get_file().get_basename())
	$TrackList/ItemList.select(0)


func _on_Back_TrackList_pressed():
	hide()


func _on_Select_TrackList_pressed():
	var selected_items = $TrackList/ItemList.get_selected_items()
	if selected_items.size() == 0:
		return
	var index = selected_items[0]
	if index < ContentLoader.repo.worlds.size():
		selected_track = ContentLoader.repo.worlds[selected_items[0]]
	else:
		selected_track = ContentLoader.get_editor_tracks().keys()[index- ContentLoader.repo.worlds.size()]

	Root.current_editor_track_path = selected_track.get_base_dir()
	Root.current_editor_track = selected_track.get_file().get_basename()

	$TrackList.hide()
	update_scenario_list()
	$ScenarioList.show()


func update_scenario_list():
	$ScenarioList/scenarioList.clear()
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	if not jEssentials.does_path_exist(scenarios_folder):
		jEssentials.create_directory(scenarios_folder)
		return
	var available_scenarios: Array = ContentLoader.get_scenarios_for_track(selected_track.get_base_dir())
	var available_scenarios_names = []
	for scenario in available_scenarios:
		available_scenarios_names.append(scenario.get_file().get_basename())

	$ScenarioList/scenarioList.set_data(available_scenarios_names)
	
	$ScenarioList/scenarioList.item_list.select(0)
	$ScenarioList/scenarioList._on_ItemList_item_selected(0)


func _on_Back_ScenarioList_pressed():
	$ScenarioList.hide()
	$TrackList.show()


func _on_scenarioList_user_added_entry(entry_name):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	var scenario_file = scenarios_folder.plus_file(entry_name + ".tres")
	var empty_scenario = TrackScenario.new()

	var err = ResourceSaver.save(scenario_file, empty_scenario)
	if err != OK:
		Logger.err("Failed to create new scenario at %s. (Reason %s)" % [scenario_file, err], self)


func _on_scenarioList_user_duplicated_entries(source_entry_names, duplicated_entry_names):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	var scenario_file = scenarios_folder.plus_file(source_entry_names[0] + ".tres")
	var new_file = scenarios_folder.plus_file(duplicated_entry_names[0] + ".tres")
	jEssentials.copy_file(scenario_file, new_file)


func _on_scenarioList_user_renamed_entry(old_name, new_name):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	var old_file = scenarios_folder.plus_file(old_name + ".tres")
	var new_file = scenarios_folder.plus_file(new_name + ".tres")
	jEssentials.rename_file(old_file, new_file)


func _on_scenarioList_user_pressed_action(entry_names):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	var entry_name = entry_names[0]
	Root.current_scenario = scenarios_folder.plus_file(entry_name + ".tres")
	Root.Editor = true
	Root.scenario_editor = true
	get_tree().change_scene_to(load("res://Editor/Modules/scenario_editor.tscn"))


func _on_ScenarioList_visibility_changed() -> void:
	if $ScenarioList.visible:
		$ScenarioList/scenarioList.item_list.grab_focus()
	else:
		$TrackList/ItemList.grab_focus()


# TrackList:
func _on_ItemList_item_activated(_index):
	_on_Select_TrackList_pressed()


func _on_scenarioList_user_removed_entries(entry_names):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	var dir = Directory.new()
	dir.remove(scenarios_folder.plus_file(entry_names[0] + ".tres"))



func _on_Control_visibility_changed():
	if visible:
		update_track_list()
