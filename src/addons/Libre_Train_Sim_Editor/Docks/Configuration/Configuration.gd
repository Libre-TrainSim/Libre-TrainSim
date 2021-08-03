tool
extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var world
var config
var save_path

var currentScenario = ""
var loadedCurrentScenario = ""

func get_all_scenarios():
	if config == null: return []
	return config.get_value("Scenarios", "List", [])

func get_world_config():
	if world == null or world.name != "World" or world.trackName == null:
		return null
	var FileName = world.trackName + "/" + world.trackName
	save_path = "res://Worlds/" + FileName + "-scenarios.cfg"
	config = ConfigFile.new()
	var load_response = config.load(save_path)

func check_duplicate_scenario(sName): # gives true, if duplicate was found
	for otherSName in get_all_scenarios():
		if otherSName == sName:
			print("There already exists a scenario with this name!")
			return true
	return false

func _on_NewScenario_pressed():
	var sName = $Scenarios/VBoxContainer/HBoxContainer/LineEdit.text
	if sName == "" or check_duplicate_scenario(sName): return
	var scenarioList = get_all_scenarios()
	scenarioList.append(sName)
	config.set_value("Scenarios", "List", scenarioList)
	var sData = config.get_value("Scenarios", "sData", {})
	sData[sName] = {}
	config.set_value("Scenarios", "sData", sData)
	config.save(save_path)
	currentScenario = sName
	update_scenario_list()
	print("Scenario added.")

func _on_RenameScenario_pressed():
	var sName = $Scenarios/VBoxContainer/HBoxContainer/LineEdit.text
	if currentScenario == "" or sName == "" or check_duplicate_scenario(sName) or sName == currentScenario: return
	var scenarioList = get_all_scenarios()
	scenarioList.erase(currentScenario)
	scenarioList.append(sName)
	var sData = config.get_value("Scenarios", "sData", {})
	sData[sName] = sData[currentScenario]
	config.set_value("Scenarios", "sData", sData)
	config.set_value("Scenarios", "List", scenarioList)
	config.save(save_path)
	currentScenario = sName
	update_scenario_list()
	print("Scenario renamed.")

func _on_DuplicateScenario_pressed():
	var sName = currentScenario + " (Duplicate)"
	if currentScenario == "" or sName == "" or check_duplicate_scenario(sName) or sName == currentScenario: return
	var scenarioList = get_all_scenarios()
	scenarioList.append(sName)
	var sData = config.get_value("Scenarios", "sData", {})
	sData[sName] = sData[currentScenario].duplicate()
	config.set_value("Scenarios", "sData", sData)
	config.set_value("Scenarios", "List", scenarioList)
	config.save(save_path)
	reload_config()
	currentScenario = sName
	print("Scenario dulicated.")
	update_scenario_list()
	pass # Replace with function body.

func reload_config():
	config = ConfigFile.new()
	var load_response = config.load(save_path)
	print("Scenario Config reloaded.")


func _on_DeleteScenario_pressed():
	if currentScenario == "": return
	var scenarioList = get_all_scenarios()
	scenarioList.erase(currentScenario)
	var sData = config.get_value("Scenarios", "sData", {})
	sData.erase(currentScenario)
	config.set_value("Scenarios", "sData", sData)
	config.set_value("Scenarios", "List", scenarioList)
	config.save(save_path)
	currentScenario = ""
	update_scenario_list()
	print("Scenario deleted.")

var oldworld
func _process(delta):
	if world == null:
		currentScenario = ""
		return
	if oldworld != world:
		get_world_config()
		get_world_configuration()
		update_scenario_list()
		currentScenario = ""
	oldworld = world
	var activeWorld = world.name == "World"
	for child in $"World Configuration".get_children():
		child.visible = activeWorld
	for child in $"Scenarios".get_children():
		child.visible = activeWorld
	if not activeWorld: return
	$Scenarios/VBoxContainer/CurrentScenario/LineEdit.text = currentScenario

	if $Scenarios/VBoxContainer/ItemList.get_selected_items().size() > 0:
		currentScenario = $Scenarios/VBoxContainer/ItemList.get_item_text($Scenarios/VBoxContainer/ItemList.get_selected_items()[0])

	$Scenarios/VBoxContainer/Settings.visible = currentScenario != ""
	$Scenarios/VBoxContainer/Label2.visible = currentScenario != ""
	$Scenarios/VBoxContainer/Write.visible = currentScenario != ""
	$Scenarios/VBoxContainer/Load.visible = currentScenario != ""
	$Scenarios/VBoxContainer/ResetSignals.visible = currentScenario != ""


func get_scenario_settings(): # fills the settings field with saved values
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario): return
	var s = sData[currentScenario]

	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeHour.value = s["TimeH"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeMinute.value = s["TimeM"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeSecond.value = s["TimeS"]
	$Scenarios/VBoxContainer/Settings/Tab/General/TrainLength/SpinBox.value = s["TrainLength"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Description.text = s["Description"]
	$Scenarios/VBoxContainer/Settings/Tab/General/Duration/SpinBox.value = s["Duration"]
	print("Scenario Settings loaded")

func set_scenario_settings():
	if currentScenario == "": return
	var sData = config.get_value("Scenarios", "sData", {})
	if sData == null:
		sData = {}
	sData[currentScenario]["TimeH"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeHour.value
	sData[currentScenario]["TimeM"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeMinute.value
	sData[currentScenario]["TimeS"] = $Scenarios/VBoxContainer/Settings/Tab/General/Time/TimeSecond.value
	sData[currentScenario]["TrainLength"] = $Scenarios/VBoxContainer/Settings/Tab/General/TrainLength/SpinBox.value
	sData[currentScenario]["Description"] = $Scenarios/VBoxContainer/Settings/Tab/General/Description.text
	sData[currentScenario]["Duration"] = $Scenarios/VBoxContainer/Settings/Tab/General/Duration/SpinBox.value
	print("Scenario Settings saved")


	config.set_value("Scenarios", "sData", sData)
	config.save(save_path)
	print("Scenario General Settings saved")

func update_scenario_list():
	$Scenarios/VBoxContainer/ItemList.clear()
	if config == null: return
	var scenarios = config.get_value("Scenarios", "List", {})
	for scenario in scenarios:
		$Scenarios/VBoxContainer/ItemList.add_item(scenario)
	print("Scenario List updated.")

func update_train_list():
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.clear()
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData[currentScenario].has("Trains"): return
	var trains = sData[currentScenario]["Trains"].keys()
	for train in trains:
		$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(train)
	print("Train List updated.")

func _on_SaveGeneral_pressed():
	set_scenario_settings()





## Load Signals
func _on_LoadScenario_pressed():
	if currentScenario == "": return
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario): return
	var scenario = sData[currentScenario]
	if not scenario.has("Signals"): return
	var signals = scenario["Signals"]
	world.apply_scenario_to_signals(signals)
	print("Signal Data loaded successfully from scenario into world")

## Save Signals
func _on_WriteData_pressed():
	get_enviroment_data_for_scenario()

func get_enviroment_data_for_scenario():
	var signals = world.get_signal_data_for_scenario()
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario):
		sData[currentScenario] = {}
	sData[currentScenario]["Signals"] = signals
	config.set_value("Scenarios", "sData", sData)
	config.save(save_path)
	print("Signal Data saved successfully")


func _on_ItemList_item_selected(index):
	currentScenario = $Scenarios/VBoxContainer/ItemList.get_item_text(index)
	world.currentScenario = currentScenario
	update_train_list()
	get_train_settings()
	get_scenario_settings()

func _on_SaveChunks_pressed():
	print("Saving and Creating World Chunks..")
	world.save_world(true)

func _on_SaveWorldConfig_pressed():
	var d = {}
	#d["FileName"] = $Configuration/GridContainer/FileName.text
	d["ReleaseDate"] = [$"World Configuration/GridContainer/ReleaseDate/Day".value, $"World Configuration/GridContainer/ReleaseDate/Month".value, $"World Configuration/GridContainer/ReleaseDate/Year".value]
	d["Author"] = $"World Configuration/GridContainer/Author".text
	d["TrackDesciption"] = $"World Configuration/GridContainer/TrackDescription".text
	d["ThumbnailPath"] = $"World Configuration/GridContainer/ThumbnailPath".text
	config.set_value("WorldConfig", "Data", d)
	config.save(save_path)
	print("World Config saved.")

func get_world_configuration():
	if config == null: return
	var d = config.get_value("WorldConfig", "Data", null)
	if d == null: return
	$"World Configuration/GridContainer/ReleaseDate/Day".value = d["ReleaseDate"][0]
	$"World Configuration/GridContainer/ReleaseDate/Month".value = d["ReleaseDate"][1]
	$"World Configuration/GridContainer/ReleaseDate/Year".value = d["ReleaseDate"][2]
	$"World Configuration/GridContainer/Author".text = d["Author"]
	$"World Configuration/GridContainer/TrackDescription".text = d["TrackDesciption"]
	$"World Configuration/GridContainer/ThumbnailPath".text = d["ThumbnailPath"]

	$"World Configuration/Notes/RichTextLabel".text = world.get_value("notes", "")




## Trains:
### Station Editing: #################################

func _on_SaveTrain_pressed():
	set_train_settings()

var currentTrain = "Player"

func get_train_settings():
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario): return
	if not sData[currentScenario].has("Trains"): return
	if not sData[currentScenario]["Trains"].has(currentTrain):
		print("No Train Data for "+ currentTrain + " found. - No data loaded.")
		clear_train_settings_view()
		return
	var trains = sData[currentScenario]["Trains"]
	if not trains.has(currentTrain): return
	var train = trains[currentTrain]

	$Scenarios/VBoxContainer/Settings/Tab/Trains/PreferredTrain/TrainName.text = train.get("PreferredTrain", "")
	$Scenarios/VBoxContainer/Settings/Tab/Trains/Route/Route.text = train["Route"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRail.text = train ["StartRail"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/StartRailPosition.value = train["StartRailPosition"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/Direction.selected = train["Direction"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected = train["DoorConfiguration"]
	print(train)
	$Scenarios/VBoxContainer/Settings/Tab/Trains/stationTable.set_data(train["Stations"])
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/H.value = train["SpawnTime"][0]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/M.value = train["SpawnTime"][1]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/SpawnTime/S.value = train["SpawnTime"][2]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/DespawnRail.text = train["DespawnRail"]
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeed.value = train.get("InitialSpeed", 0)
	$Scenarios/VBoxContainer/Settings/Tab/Trains/GridContainer/InitialSpeedLimit.value = train.get("InitialSpeedLimit", -1)
	print("Train "+ currentTrain + " loaded.")

func set_train_settings():
	var train = {}
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
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario):
		sData[currentScenario] = {}
	if not sData[currentScenario].has("Trains"):
		sData[currentScenario]["Trains"] = {}
	sData[currentScenario]["Trains"][currentTrain] = train
	config.set_value("Scenarios", "sData", sData)
	config.save(save_path)
	print("Train "+ currentTrain + " saved.")

#var entriesCount = 0
#const stationTableColumns = 8

#func _on_RemoveStationEntry_pressed():
#	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
#	var children = grid.get_children()
#	if entriesCount == 0:
#		return
#	children.invert()
#	for i in range (0,stationTableColumns):
#		children[i].queue_free()
#	entriesCount -= 1


#func _on_AddStationEntry_pressed():
#	entriesCount += 1
#	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
#	for child in grid.get_children():
#		print(child.name)
#	print("###############")
#
#	var a
#
#	a = grid.get_node("nodeName0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("stationName0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("arrivalTime0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("departureTime0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("haltTime0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("stopType0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("waitingPersons0").duplicate()
#	grid.add_child(a)
#	a.show()
#
#	a = grid.get_node("leavingPersons0").duplicate()
#	grid.add_child(a)
#	a.show()
#	pass # Replace with function body.


#func get_station_array():
#	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
#	var children = grid.get_children()
#	var stations = {"nodeName" : [], "stationName" : [], "arrivalTime" : [], "departureTime" : [], "haltTime" : [], "stopType" : [], "waitingPersons": [], "leavingPersons" : [], "passed" : []}
#	for i in range(2, entriesCount+2):
#		stations["nodeName"].append(children[stationTableColumns*i+0].text)
#		stations["stationName"].append(children[stationTableColumns*i+1].text)
#		stations["arrivalTime"].append([children[stationTableColumns*i+2].get_node("H").value, children[6*i+2].get_node("M").value, children[6*i+2].get_node("S").value])
#		stations["departureTime"].append([children[stationTableColumns*i+3].get_node("H").value, children[6*i+3].get_node("M").value, children[6*i+3].get_node("S").value])
#		stations["haltTime"].append(children[stationTableColumns*i+4].value)
#		stations["stopType"].append(children[stationTableColumns*i+5].selected)
#		stations["waitingPersons"].append(children[stationTableColumns*i+6].value)
#		stations["leavingPersons"].append(children[stationTableColumns*i+7].value)
#		stations["passed"].append(false)
#	return stations

#func prepare_station_table(stations):
#
##	print(stations)
#	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
#	while (grid.get_children().size() > 2*stationTableColumns):
#		grid.get_children()[grid.get_children().size()-1].free()
#	entriesCount = 0
#	if stations == null:
#		return
#	for i in range (0,stations["nodeName"].size()):
#		_on_AddStationEntry_pressed()
#	var children = grid.get_children()
#	for i in range(2, entriesCount+2):
#		children[stationTableColumns*i+0].text = stations["nodeName"][i-2]
#		children[stationTableColumns*i+1].text = stations["stationName"][i-2]
#		children[stationTableColumns*i+2].get_node("H").value = stations["arrivalTime"][i-2][0]
#		children[stationTableColumns*i+2].get_node("M").value = stations["arrivalTime"][i-2][1]
#		children[stationTableColumns*i+2].get_node("S").value = stations["arrivalTime"][i-2][2]
#		children[stationTableColumns*i+3].get_node("H").value = stations["departureTime"][i-2][0]
#		children[stationTableColumns*i+3].get_node("M").value = stations["departureTime"][i-2][1]
#		children[stationTableColumns*i+3].get_node("S").value = stations["departureTime"][i-2][2]
#		children[stationTableColumns*i+4].value = stations["haltTime"][i-2]
#		children[stationTableColumns*i+5].selected = stations["stopType"][i-2]
#		if stations.has("waitingPersons"):
#			children[stationTableColumns*i+6].value = stations["waitingPersons"][i-2]
#		if stations.has("leavingPersons"):
#			children[stationTableColumns*i+7].value = stations["leavingPersons"][i-2]





func _on_ResetSignals_pressed():
	for child in world.get_node("Signals").get_children():
		if child.type == "Signal":
			child.reset()


func _on_ItemList2_Train_selected(index):
	currentTrain = $Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.get_item_text(index)
	get_train_settings()
	$Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text = currentTrain


func _on_NewTrain_pressed():
	var trainName = $Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text
	if trainName == "": return
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(trainName)



func _on_RenameTrain_pressed():
	if currentTrain == "Player":
		print("You can't rename the player train!")
		return
	var oldTrain = currentTrain
	var trainName = $Scenarios/VBoxContainer/Settings/Tab/Trains/HBoxContainer2/LineEdit.text
	if trainName == "": return
	for  i in range(0, $Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.get_item_count()):
		if $Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.get_item_text(i) == trainName:
			print("There already exists a train whith this train name, aborting...")
			return
	get_train_settings()
	currentTrain = trainName
	set_train_settings()
	## Delete "Old Train"
	delete_train(oldTrain)
	update_train_list()




func _on_DuplicateTrain_pressed():
	if currentTrain == "": return
	get_train_settings()
	currentTrain = currentTrain + " (Duplicate)"
	$Scenarios/VBoxContainer/Settings/Tab/Trains/ItemList2.add_item(currentTrain)
	set_train_settings()



func delete_train(train):
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario): return
	if not sData[currentScenario].has("Trains"): return
	if not sData[currentScenario]["Trains"].has(train):
		return
	var trains = sData[currentScenario]["Trains"]
	trains.erase(train)
	sData[currentScenario]["Trains"] = trains
	config.set_value("Scenarios", "sData", sData)
	config.save(save_path)

func _on_DeleteTrain_pressed():
	if currentTrain == "Player":
		print ("You cant delete the player train!")
		return
	delete_train(currentTrain)
	print("Train deleted.")
	currentTrain = ""
	update_train_list()
	clear_train_settings_view()

func clear_train_settings_view(): # Resets the Train settings when adding a new npc for example.
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

	$Scenarios/VBoxContainer/VBoxContainer/Settings/Tab/Trains/stationTable.clear_data()



#func _on_ToggleAllSavedObjects_pressed():
#	if world.editorAllObjectsUnloaded:
#		world.editorLoadAllChunks()
#	else:
#		world.editorUnloadAllChunks()
#	updateToggleAllSavedObjectsButton()
#
#
#func updateToggleAllSavedObjectsButton():
#	if world == null or world.name != "World":
#		return
#	if not world.editorAllObjectsUnloaded:
#		$"World Configuration/ToggleAllSavedObjects".text = "Unload all Objects from configuration"
#	else:
#		$"World Configuration/ToggleAllSavedObjects".text = "Load all Objects from configuration"


func _on_WorldLoading_AllChunks_pressed():
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		$"World Configuration/WorldLoading/RailConfiguration".hide()
		$"World Configuration/WorldLoading/IncludeNeighbours".hide()
	else:
		$"World Configuration/WorldLoading/RailConfiguration".show()
		$"World Configuration/WorldLoading/IncludeNeighbours".show()



func _on_WorldLoading_Unload_pressed():
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		world.unload_and_save_all_chunks()
		print("Unloaded all chunks.")
		return
	var chunks = world.get_chunks_between_rails(
		$"World Configuration/WorldLoading/RailConfiguration/FromRail".text,
		$"World Configuration/WorldLoading/RailConfiguration/ToRail".text,
		$"World Configuration/WorldLoading/IncludeNeighbours".pressed)
	if chunks == null:
		return
	world.unload_and_save_chunks(chunks)
	pass # Replace with function body.


func _on_WorldLoading_Load_pressed():
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		world.force_load_all_chunks()
		print("Loaded all chunks.")
		return
	var chunks = world.get_chunks_between_rails(
		$"World Configuration/WorldLoading/RailConfiguration/FromRail".text,
		$"World Configuration/WorldLoading/RailConfiguration/ToRail".text,
		$"World Configuration/WorldLoading/IncludeNeighbours".pressed)
	if chunks == null:
		return
	world.load_chunks(chunks)
	print("Loaded Chunks " + String(chunks))


func _on_Chunks_Save_pressed():
	if $"World Configuration/WorldLoading/AllChunks".pressed:
		world.save_all_chunks()
		print("Saved all chunks.")
		return
	var chunks = world.get_chunks_between_rails(
		$"World Configuration/WorldLoading/RailConfiguration/FromRail".text,
		$"World Configuration/WorldLoading/RailConfiguration/ToRail".text,
		$"World Configuration/WorldLoading/IncludeNeighbours".pressed)
	if chunks == null:
		return
	world.save_chunks(chunks)


func _on_Notes_Save_pressed():
	world.save_value("notes", $"World Configuration/Notes/RichTextLabel".text)
