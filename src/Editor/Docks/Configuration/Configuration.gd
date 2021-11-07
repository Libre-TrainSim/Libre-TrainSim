extends Control

onready var editor: Node = find_parent("Editor")
var world: Node

var current_scenario: String = ""

var world_config_path: String
var world_config: WorldConfig
var scenarios: Dictionary


func _ready() -> void:
	var dir = Directory.new()
	if not dir.dir_exists(editor.current_track_path.get_base_dir().plus_file("scenarios")):
		dir.make_dir_recursive(editor.current_track_path.get_base_dir().plus_file("scenarios"))

	update_save_path()


func get_scenario_path(scenario_name: String) -> String:
	return editor.current_track_path.get_base_dir().plus_file("scenarios").plus_file("%s.tres" % scenario_name)


func save_scenario(path: String, config: TrackScenario) -> bool:
	if ResourceSaver.save(path, config) != OK:
		Logger.err("Error saving scenario at '%s'" % path, self)
		return false
	return true


func save_current_scenario() -> bool:
	var scenario_path: String = get_scenario_path(current_scenario)
	return save_scenario(scenario_path, scenarios[current_scenario])


func save_world_config() -> bool:
	if ResourceSaver.save(world_config_path, world_config) != OK:
		Logger.err("Error saving world config at '%s'" % world_config_path, self)
		return false
	return true


func update_save_path() -> void:
	world_config_path = editor.current_track_path + "_config.tres"
	scenarios.clear()
	current_scenario = ""

	var dir = Directory.new()
	if dir.file_exists(world_config_path):
		world_config = load(world_config_path) as WorldConfig
		for scenario in world_config.scenarios:
			var s = load(scenario) as TrackScenario
			scenarios[s.title] = s
	else:
		world_config = WorldConfig.new()


# returns true, if duplicate was found
func check_duplicate_scenario(sName: String) -> bool:
	if scenarios.has(sName):
		Logger.err("There already exists a scenario with this name!", self)
		return true
	return false


func _on_NewScenario_pressed() -> void:
	var sName: String = $Scenarios/VBoxContainer/HBoxContainer/LineEdit.text.strip_edges()
	if sName.empty() or check_duplicate_scenario(sName):
		return

	var scenario_config = TrackScenario.new()
	scenario_config.title = sName
	scenarios[sName] = scenario_config

	var scenario_path: String = get_scenario_path(sName)
	if not save_scenario(scenario_path, scenario_config):
		return

	world_config.scenarios.append(scenario_path)
	save_world_config()

	current_scenario = sName
	update_scenario_list()
	Logger.log("Scenario added.")


func _on_RenameScenario_pressed() -> void:
	var sName: String = $Scenarios/VBoxContainer/HBoxContainer/LineEdit.text
	if current_scenario.empty() or sName.empty() or check_duplicate_scenario(sName) or sName == current_scenario:
		Logger.err("Scenario '%s' cannot be renamed to '%s'!" % [current_scenario, sName], self)
		return

	var scenario_config = scenarios[current_scenario]

	var dir := Directory.new()
	var old_scenario_path: String = get_scenario_path(current_scenario)
	var new_scenario_path: String = get_scenario_path(sName)

	if not save_scenario(new_scenario_path, scenario_config):
		Logger.err("Cancelling rename!", self)
		return

	scenarios[sName] = scenario_config
	scenarios.erase(current_scenario)

	if dir.file_exists(old_scenario_path):
		dir.remove(old_scenario_path)

	world_config.scenarios.erase(old_scenario_path)
	world_config.scenarios.append(new_scenario_path)
	save_world_config()

	Logger.log("Scenario '%s' successfully renamed to '%s'." % [current_scenario, sName])
	current_scenario = sName
	update_scenario_list()


func _on_DuplicateScenario_pressed() -> void:
	var sName: String = current_scenario + " (Duplicate)"
	if current_scenario.empty() or sName.empty() or check_duplicate_scenario(sName) or sName == current_scenario:
		Logger.err("Cannot duplicate '%s'!" % current_scenario, self)
		return

	var scenario_config = scenarios[current_scenario]
	scenarios[sName] = scenario_config.duplicate()

	var new_scenario_path: String = get_scenario_path(sName)
	if ResourceSaver.save(new_scenario_path, scenario_config) != OK:
		Logger.err("Cannot save scenario at '%s'! Cancelling duplicate!" % new_scenario_path, self)
		return

	world_config.scenarios.append(new_scenario_path)
	save_world_config()

	Logger.log("Scenario '%s' duplicated." % current_scenario)
	current_scenario = sName
	update_scenario_list()


func _on_DeleteScenario_pressed() -> void:
	if current_scenario.empty():
		return

	scenarios.erase(current_scenario)

	var scenario_path: String = get_scenario_path(current_scenario)
	world_config.scenarios.erase(scenario_path)
	save_world_config()

	var dir = Directory.new()
	if dir.file_exists(scenario_path):
		dir.remove(scenario_path)

	current_scenario = ""
	update_scenario_list()
	Logger.log("Scenario deleted.")


var oldworld: Node
func _process(delta: float) -> void:
	if world == null:
		current_scenario = ""
		return
	if oldworld != world:
		update_save_path()
		update_ui_from_world_config()
		update_scenario_list()
		current_scenario = ""
	oldworld = world
	var activeWorld: bool = world.name == "World"
	for child in $"World Configuration".get_children():
		child.visible = activeWorld
	for child in $"Scenarios".get_children():
		child.visible = activeWorld
	if not activeWorld:
		return
	$Scenarios/VBoxContainer/CurrentScenario/LineEdit.text = current_scenario

	if $Scenarios/VBoxContainer/ItemList.get_selected_items().size() > 0:
		current_scenario = $Scenarios/VBoxContainer/ItemList.get_item_text($Scenarios/VBoxContainer/ItemList.get_selected_items()[0])

	$Scenarios/VBoxContainer/Settings.visible = not current_scenario.empty()
	$Scenarios/VBoxContainer/Label2.visible = not current_scenario.empty()
	$Scenarios/VBoxContainer/SaveSignalData.visible = not current_scenario.empty()
	$Scenarios/VBoxContainer/CopySignalDataFrom.visible = not current_scenario.empty()
	$Scenarios/VBoxContainer/ResetSignals.visible = not current_scenario.empty()


func update_ui_from_scenario_config() -> void: # fills the settings field with saved values
	clear_general_scenario_settings_fields()

	if not scenarios.has(current_scenario):
		Logger.err("Scenario '%s' is not in scenario list!" % current_scenario, self)
		return

	var s = scenarios[current_scenario]
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeHour.value = s.time["hour"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeMinute.value = s.time["minute"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeSecond.value = s.time["second"]
	$Scenarios/VBoxContainer/Settings/Tab/General/TrainLength/SpinBox.value = s.train_length
	$Scenarios/VBoxContainer/Settings/Tab/General/Description.text = s.description
	$Scenarios/VBoxContainer/Settings/Tab/General/Duration/SpinBox.value = s.duration
	Logger.log("Scenario Settings loaded")


func save_general_scenario_settings() -> void:
	if current_scenario.empty():
		return

	if not scenarios.has(current_scenario):
		Logger.err("Scenario '%s' is not in scenario list!" % current_scenario, self)
		return

	var s = scenarios[current_scenario]
	s.time["hour"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeHour.value
	s.time["minute"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeMinute.value
	s.time["second"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeSecond.value
	s.train_length = $Scenarios/VBoxContainer/Settings/Tab/General/TrainLength/SpinBox.value
	s.description = $Scenarios/VBoxContainer/Settings/Tab/General/Description.text
	s.duration = $Scenarios/VBoxContainer/Settings/Tab/General/Duration/SpinBox.value

	save_current_scenario()
	Logger.log("Scenario General Settings saved")


func clear_general_scenario_settings_fields() -> void:
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeHour.value = 12
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeMinute.value = 0
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeSecond.value = 0
	$Scenarios/VBoxContainer/Settings/Tab/General/TrainLength/SpinBox.value = 100
	$Scenarios/VBoxContainer/Settings/Tab/General/Description.text = ""
	$Scenarios/VBoxContainer/Settings/Tab/General/Duration/SpinBox.value = 0


func update_scenario_list() -> void:
	$Scenarios/VBoxContainer/ItemList.clear()
	for scenario in scenarios:
		$Scenarios/VBoxContainer/ItemList.add_item(scenario)
	Logger.log("Scenario List updated.")


func update_train_list() -> void:
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.clear()

	if not scenarios.has(current_scenario):
		Logger.err("Scenario '%s' is not in scenario list!" % current_scenario, self)
		return

	for train in scenarios[current_scenario].trains:
		$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(train)
	Logger.log("Train List updated.")


func _on_SaveGeneral_pressed() -> void:
	save_general_scenario_settings()


func save_everything() -> void:
	if not current_scenario.empty():
		_on_SaveGeneral_pressed()
	if not current_train.empty():
		_on_SaveTrain_pressed()
	_on_Notes_Save_pressed()
	_on_SaveWorldConfig_pressed()


func _on_ItemList_item_selected(index: int) -> void:
	current_scenario = $Scenarios/VBoxContainer/ItemList.get_item_text(index)
	world.current_scenario = current_scenario
	update_train_list()
	load_current_train()
	update_ui_from_scenario_config()


func _on_SaveChunks_pressed() -> void:
	Logger.log("Saving and Creating World Chunks..")
	world.save_world(true)


func _on_SaveWorldConfig_pressed() -> void:
	world_config.release_date["day"] = $"World Configuration/GridContainer/ReleaseDate/Day".value
	world_config.release_date["month"] = $"World Configuration/GridContainer/ReleaseDate/Month".value
	world_config.release_date["year"] = $"World Configuration/GridContainer/ReleaseDate/Year".value

	world_config.author = $"World Configuration/GridContainer/Author".text
	world_config.track_description = $"World Configuration/GridContainer/TrackDescription".text

	save_world_config()
	Logger.log("World Config saved.")


func update_ui_from_world_config() -> void:
	$"World Configuration/GridContainer/ReleaseDate/Day".value = world_config.release_date["day"]
	$"World Configuration/GridContainer/ReleaseDate/Month".value = world_config.release_date["month"]
	$"World Configuration/GridContainer/ReleaseDate/Year".value = world_config.release_date["year"]
	$"World Configuration/GridContainer/Author".text = world_config.author
	$"World Configuration/GridContainer/TrackDescription".text = world_config.track_description
	$"World Configuration/Notes/RichTextLabel".text = world_config.notes


## Trains:
### Station Editing: #################################
func _on_SaveTrain_pressed() -> void:
	save_current_train()


var current_train: String = "Player"
func load_current_train() -> void:
	if not scenarios.has(current_scenario):
		Logger.err("Scenario '%s' is not in scenario list!" % current_scenario, self)
		return

	if not scenarios[current_scenario].trains.has(current_train):
		Logger.err("No Train Data for "+ current_train + " found. - No data loaded.", self)
		clear_train_settings_view()
		return

	var train: Dictionary = scenarios[current_scenario].trains[current_train]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/PreferredTrain/TrainName.text = train.get("PreferredTrain", "")
	$Scenarios/VBoxContainer/Settings/Tab/Trains/Route/Route.text = train["Route"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRail.text = train ["StartRail"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRailPosition.value = train["StartRailPosition"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/Direction.selected = train["Direction"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected = train["DoorConfiguration"]
	Logger.vlog(train)
	$Scenarios/VBoxContainer/Settings/Tab/Trains/stationTable.set_data(train["Stations"])
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/H.value = train["SpawnTime"][0]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/M.value = train["SpawnTime"][1]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/S.value = train["SpawnTime"][2]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DespawnRail.text = train["DespawnRail"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeed.value = train.get("InitialSpeed", 0)
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeedLimit.value = train.get("InitialSpeedLimit", -1)
	Logger.log("Train "+ current_train + " loaded.")


func save_current_train() -> void:
	if current_scenario.empty():
		return

	var train := {}
	train["PreferredTrain"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/PreferredTrain/TrainName.text
	train["Route"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/Route/Route.text
	train ["StartRail"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRail.text
	train["StartRailPosition"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRailPosition.value
	train["Direction"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/Direction.selected
	train["DoorConfiguration"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected
	train["SpawnTime"] = [$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/H.value, $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/M.value, $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/S.value]
	train["DespawnRail"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DespawnRail.text
	train["InitialSpeed"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeed.value
	train["InitialSpeedLimit"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeedLimit.value
	train["Stations"] = $Scenarios/VBoxContainer/Settings/Tab/Trains/stationTable.get_data()

	scenarios[current_scenario].trains[current_train] = train
	save_current_scenario()
	Logger.log("Train "+ current_train + " saved.")


func _on_ItemList2_Train_selected(index: int) -> void:
	current_train = $Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.get_item_text(index)
	load_current_train()
	$Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text = current_train


func _on_NewTrain_pressed() -> void:
	var trainName: String = $Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text
	if trainName.empty():
		return
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(trainName)


func _on_RenameTrain_pressed() -> void:
	if current_train == "Player":
		Logger.err("You can't rename the player train!", self)
		return
	var oldTrain: String = current_train
	var trainName: String = $Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text
	if trainName.empty():
		return

	if scenarios[current_scenario].trains.has(trainName):
		Logger.err("Cannot rename train '%s' to '%s', already exists." % [oldTrain, trainName], self)
		return

	load_current_train()
	current_train = trainName
	save_current_train()
	delete_train(oldTrain)
	update_train_list()


func _on_DuplicateTrain_pressed() -> void:
	if current_train.empty():
		return
	load_current_train()
	current_train = current_train + " (Duplicate)"
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(current_train)
	save_current_train()


func delete_train(train: String) -> void:
	if not scenarios.has(current_scenario):
		Logger.err("Scenario '%s' is not in scenario list!" % current_scenario, self)
		return
	if not scenarios[current_scenario].trains.has(train):
		Logger.warn("Cannot delete non existant Train '%s'." % train, self)
		return
	scenarios[current_scenario].trains.erase(train)
	save_current_scenario()


func _on_DeleteTrain_pressed() -> void:
	if current_train == "Player":
		Logger.err("You cant delete the player train!", self)
		return
	delete_train(current_train)
	Logger.log("Train deleted.")
	current_train = ""
	update_train_list()
	clear_train_settings_view()


# Resets the Train settings when adding a new npc for example.
func clear_train_settings_view() -> void:
	$Scenarios/VBoxContainer/Settings/Tab/Trains/PreferredTrain/TrainName.text = ""
	$Scenarios/VBoxContainer/Settings/Tab/Trains/Route/Route.text = ""
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRail.text = ""
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRailPosition.value = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/Direction.selected = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/H.value = -1
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/M.value = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/S.value = 0
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DespawnRail.text = ""
	$Scenarios/VBoxContainer/Settings/Tab/Trains/stationTable.clear_data()


func _on_WorldLoading_AllChunks_pressed() -> void:
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		$"World Configuration/WorldLoading/RailConfiguration".hide()
		$"World Configuration/WorldLoading/IncludeNeighbours".hide()
	else:
		$"World Configuration/WorldLoading/RailConfiguration".show()
		$"World Configuration/WorldLoading/IncludeNeighbours".show()


func _on_WorldLoading_Unload_pressed() -> void:
	world.chunk_manager.save_and_unload_all_chunks()
	world.chunk_manager.resume_chunking()
	Logger.log("Unloaded all chunks.")


func _on_WorldLoading_Load_pressed() -> void:
	return


func _on_Chunks_Save_pressed() -> void:
	world.chunk_manager._save_chunks(world.chunk_manager._get_all_chunks())


# NOTE: this will also save chunks... great
func _on_Notes_Save_pressed() -> void:
	world_config.notes = $"World Configuration/Notes/RichTextLabel".text
	save_world_config()


## Signals: ####################################################################
func _on_SaveSignalData_pressed() -> void:
	save_signal_data_to_current_scenario()


func save_signal_data_to_current_scenario() -> void:
	var signal_data: Dictionary = world.get_signal_scenario_data()
	if not scenarios.has(current_scenario):
		Logger.err("Scenario '%s' is not in scenario list!" % current_scenario, self)
		return
	scenarios[current_scenario].signals = signal_data
	save_current_scenario()


func _on_CopyAndOverwriteSignalDataFrom_pressed() -> void:
	if scenarios.size() < 2:
		Logger.warn("Will not copy from scenario. You only have 1 scenario.", self)
		return
	$Scenarios/VBoxContainer/CopySignalDataFrom/PopupMenu.clear()
	for scenario in scenarios:
		$Scenarios/VBoxContainer/CopySignalDataFrom/PopupMenu.add_item(scenario)
	$Scenarios/VBoxContainer/CopySignalDataFrom/PopupMenu.show()


func load_signal_data_from_current_scenario_to_world() -> void:
	if current_scenario.empty():
		return
	if not scenarios.has(current_scenario):
		Logger.err("Scenario '%s' is not in scenario list!" % current_scenario, self)
		return
	world.apply_scenario_to_signals(scenarios[current_scenario].signals)


func _on_PopupMenu_Copy_SignalDataFrom_index_pressed(index: int) -> void:
	var scenario_source: String = $Scenarios/VBoxContainer/CopySignalDataFrom/PopupMenu.get_item_text(index)
	if scenario_source == current_scenario:
		Logger.warn("Nothing done. Can't copy and overwrite from current scenario to current scenario.", self)
		jEssentials.show_message("Nothing done. Can't copy and overwrite from current scenario to current scenario.")
		return

	scenarios[current_scenario] = scenarios[scenario_source].duplicate()
	save_current_scenario()
	load_signal_data_from_current_scenario_to_world()
	Logger.log("Scenario Data successfully imported from scenario '%s'." % scenario_source)
	jEssentials.show_message("Scenario Data successfully imported from scenario '%s'." % scenario_source)


func _on_ResetSignals_pressed() -> void:
	for child in world.get_node("Signals").get_children():
		if child.type == "Signal":
			child.reset()
