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
	if world == null or world.name != "World":
		return null
	var FileName = world.FileName
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
	var sName = $Scenarios/HBoxContainer/LineEdit.text
	if sName == "" or check_duplicate_scenario(sName): return
	var scenarioList = get_all_scenarios()
	scenarioList.append(sName)
	config.set_value("Scenarios", "List", scenarioList)
	config.save(save_path)
	currentScenario = sName
	update_scenario_list()
	print("Scenario added.")
		
func _on_RenameScenario_pressed():
	var sName = $Scenarios/HBoxContainer/LineEdit.text
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
	currentScenario = sName
	print("Scenario dulicated.")
	update_scenario_list()
	pass # Replace with function body.


func _on_DeleteScenario_pressed():
	if currentScenario == "": return
	var scenarioList = get_all_scenarios()
	scenarioList.erase(currentScenario)
	var sData = config.get_value("Scenarios", "sData", {})
	sData.remove(currentScenario)
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
	$Scenarios/CurrentScenario/LineEdit.text = currentScenario

	if $Scenarios/ItemList.get_selected_items().size() > 0:
		currentScenario = $Scenarios/ItemList.get_item_text($Scenarios/ItemList.get_selected_items()[0])
	
func get_scenario_settings(): # fills the settings field with saved values
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario): return
	var s = sData[currentScenario]
	
	$Scenarios/Settings/Tab/General/Time/TimeHour.value = s["TimeH"]
	$Scenarios/Settings/Tab/General/Time/TimeMinute.value = s["TimeM"]
	$Scenarios/Settings/Tab/General/Time/TimeSecond.value = s["TimeS"]
	$Scenarios/Settings/Tab/General/TrainLength/SpinBox.value = s["TrainLength"]
	$Scenarios/Settings/Tab/General/Description.text = s["Description"]
	$Scenarios/Settings/Tab/General/Duration/SpinBox.value = s["Duration"]

func set_scenario_settings():
	if currentScenario == "": return
	var sData = config.get_value("Scenarios", "sData", {})
	if sData == null:
		sData = {}
	sData[currentScenario]["TimeH"] = $Scenarios/Settings/Tab/General/Time/TimeHour.value 
	sData[currentScenario]["TimeM"] = $Scenarios/Settings/Tab/General/Time/TimeMinute.value 
	sData[currentScenario]["TimeS"] = $Scenarios/Settings/Tab/General/Time/TimeSecond.value 
	sData[currentScenario]["TrainLength"] = $Scenarios/Settings/Tab/General/TrainLength/SpinBox.value 
	sData[currentScenario]["Description"] = $Scenarios/Settings/Tab/General/Description.text 
	sData[currentScenario]["Duration"] = $Scenarios/Settings/Tab/General/Duration/SpinBox.value 
	

	config.set_value("Scenarios", "sData", sData)
	config.save(save_path)
	print("Scenario General Settings saved")
	
func update_scenario_list():
	$Scenarios/ItemList.clear()
	var scenarios = config.get_value("Scenarios", "List", {})
	for scenario in scenarios:
		$Scenarios/ItemList.add_item(scenario)
	print("Scenario List updated.")

func update_train_list():
	$Scenarios/Settings/Tab/Trains/ItemList2.clear()
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData[currentScenario].has("Trains"): return
	var trains = sData[currentScenario]["Trains"].keys()
	for train in trains:
		$Scenarios/Settings/Tab/Trains/ItemList2.add_item(train)
	print("Train List updated.")

func _on_SaveGeneral_pressed():
	set_scenario_settings()
	
var currentTrain = "Player"

func get_train_settings():
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario): return
	if not sData[currentScenario].has("Trains"): return
	if not sData[currentScenario]["Trains"].has(currentTrain): return
	var trains = sData[currentScenario]["Trains"]
	if not trains.has(currentTrain): return
	var train = trains[currentTrain]
	
	$Scenarios/Settings/Tab/Trains/Route/Route.text = train["Route"]
	$Scenarios/Settings/Tab/Trains/GridContainer/StartRail.text = train ["StartRail"]
	$Scenarios/Settings/Tab/Trains/GridContainer/StartRailPosition.value = train["StartRailPosition"]
	$Scenarios/Settings/Tab/Trains/GridContainer/Direction.selected = train["Direction"]
	$Scenarios/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected = train["DoorConfiguration"]
	prepare_station_table(train["Stations"])

func set_train_settings():
	var train = {}
	train["Route"] = $Scenarios/Settings/Tab/Trains/Route/Route.text
	train ["StartRail"] = $Scenarios/Settings/Tab/Trains/GridContainer/StartRail.text
	train["StartRailPosition"] = $Scenarios/Settings/Tab/Trains/GridContainer/StartRailPosition.value
	train["Direction"] = $Scenarios/Settings/Tab/Trains/GridContainer/Direction.selected
	train["DoorConfiguration"] = $Scenarios/Settings/Tab/Trains/GridContainer/DoorConfiguration.selected
	train["Stations"] = get_station_array()
	var sData = config.get_value("Scenarios", "sData", {})
	if not sData.has(currentScenario):
		sData[currentScenario] = {}
	if not sData[currentScenario].has("Trains"):
		sData[currentScenario]["Trains"] = {}
	sData[currentScenario]["Trains"][currentTrain] = train
	config.set_value("Scenarios", "sData", sData)
	config.save(save_path)
	print("Train Settings saved")
	
func _on_SaveTrain_pressed():
	set_train_settings()
	
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
	currentScenario = $Scenarios/ItemList.get_item_text(index)
	world.currentScenario = currentScenario
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
	var d = config.get_value("WorldConfig", "Data", null)
	if d == null: return
	$"World Configuration/GridContainer/ReleaseDate/Day".value = d["ReleaseDate"][0]
	$"World Configuration/GridContainer/ReleaseDate/Month".value = d["ReleaseDate"][1]
	$"World Configuration/GridContainer/ReleaseDate/Year".value = d["ReleaseDate"][2]
	$"World Configuration/GridContainer/Author".text = d["Author"]
	$"World Configuration/GridContainer/TrackDescription".text = d["TrackDesciption"]
	$"World Configuration/GridContainer/ThumbnailPath".text = d["ThumbnailPath"]



### Station Editing: #################################

var entriesCount = 0


func _on_RemoveStationEntry_pressed():
	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
	var children = grid.get_children()
	if entriesCount == 0:
		return
	children.invert()
	for i in range (0,6):
		children[i].queue_free()
	entriesCount -= 1


func _on_AddStationEntry_pressed():
	entriesCount += 1
	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
	var a
	
	a = grid.get_node("nodeName0").duplicate()
	grid.add_child(a)
	a.show()
	
	a = grid.get_node("stationName0").duplicate()
	grid.add_child(a)
	a.show()
	
	a = grid.get_node("arrivalTime0").duplicate()
	grid.add_child(a)
	a.show()
	
	a = grid.get_node("departureTime0").duplicate()
	grid.add_child(a)
	a.show()
	
	a = grid.get_node("haltTime0").duplicate()
	grid.add_child(a)
	a.show()
	
	a = grid.get_node("stopType0").duplicate()
	grid.add_child(a)
	a.show()
	pass # Replace with function body.

func get_station_array():
	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
	var children = grid.get_children()
	var stations = {"nodeName" : [], "stationName" : [], "arrivalTime" : [], "departureTime" : [], "haltTime" : [], "stopType" : [], "passed" : []}
	for i in range(2, entriesCount+2):
		stations["nodeName"].append(children[6*i+0].text)
		stations["stationName"].append(children[6*i+1].text)
		stations["arrivalTime"].append([children[6*i+2].get_node("H").value, children[6*i+2].get_node("M").value, children[6*i+2].get_node("S").value])
		stations["departureTime"].append([children[6*i+3].get_node("H").value, children[6*i+3].get_node("M").value, children[6*i+3].get_node("S").value])
		stations["haltTime"].append(children[6*i+4].value)
		stations["stopType"].append(children[6*i+5].selected)
		stations["passed"].append(false)
	return stations

func prepare_station_table(stations):
	var grid = $Scenarios/Settings/Tab/Trains/Stations/Stations
	for i in range(12, grid.get_children().size()):
		grid.get_children()[i].queue_free()
	entriesCount = 0
	for i in range (0,stations["nodeName"].size()):
		_on_AddStationEntry_pressed()
	var children = grid.get_children()
	for i in range(2, entriesCount+2):
		children[6*i+0].text = stations["nodeName"][i-2]
		children[6*i+1].text = stations["stationName"][i-2]
		children[6*i+2].get_node("H").value = stations["arrivalTime"][i-2][0]
		children[6*i+2].get_node("M").value = stations["arrivalTime"][i-2][1]
		children[6*i+2].get_node("S").value = stations["arrivalTime"][i-2][2]
		children[6*i+3].get_node("H").value = stations["departureTime"][i-2][0]
		children[6*i+3].get_node("M").value = stations["departureTime"][i-2][1]
		children[6*i+3].get_node("S").value = stations["departureTime"][i-2][2]
		children[6*i+4].value = stations["haltTime"][i-2]
		children[6*i+5].selected = stations["stopType"][i-2]

	
