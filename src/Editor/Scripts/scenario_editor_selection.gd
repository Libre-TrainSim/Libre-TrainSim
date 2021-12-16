extends Panel

var selected_track: String = ""

var available_scenarios = []

var j_save_module = jSaveModule.new()

func _ready():
	update_track_list()


func update_track_list():
	$TrackList/ItemList.clear()
	for track in ContentLoader.repo.worlds:
		$TrackList/ItemList.add_item(track.get_file().get_basename())

	var tracks = ContentLoader.get_editor_tracks()
	for track in tracks.keys():
		$TrackList/ItemList.add_item("Track-Editor: " + track.get_file().get_basename())




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
	var available_scenarios: Array = ContentLoader.get_scenarios_for_track(selected_track)
	var available_scenarios_names = []
	for scenario in available_scenarios:
		available_scenarios_names.append(scenario.get_file().get_basename())

	$ScenarioList/scenarioList.set_data(available_scenarios_names)


func _on_Back_ScenarioList_pressed():
	$ScenarioList.hide()
	$TrackList.show()


func _on_scenarioList_user_added_entry(entry_name):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	j_save_module.set_save_path(scenarios_folder.plus_file(entry_name + ".scenario"))
	j_save_module.save_value("empty", true)
	j_save_module.write_to_disk()


func _on_scenarioList_user_duplicated_entries(source_entry_names, duplicated_entry_names):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	jEssentials.copy_file(scenarios_folder.plus_file(source_entry_names[0] + ".scenario"), scenarios_folder.plus_file(duplicated_entry_names[0] + ".scenario"))


func _on_scenarioList_user_renamed_entry(old_name, new_name):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	jEssentials.rename_file(scenarios_folder.plus_file(old_name + ".scenario"), scenarios_folder.plus_file(new_name + ".scenario"))


func _on_scenarioList_user_pressed_action(entry_names):
	var scenarios_folder: String = selected_track.get_base_dir().plus_file("scenarios")
	var entry_name = entry_names[0]
	Root.current_scenario = scenarios_folder.plus_file(entry_name + ".scenario")
	Root.Editor = true
	Root.scenario_editor = true
	get_tree().change_scene_to(load("res://Editor/Modules/scenario_editor.tscn"))


# TrackList:
func _on_ItemList_item_activated(index):
	_on_Select_TrackList_pressed()
