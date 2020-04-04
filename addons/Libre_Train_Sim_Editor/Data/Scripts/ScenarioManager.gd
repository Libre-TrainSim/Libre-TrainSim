tool
extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (Dictionary) var data = {}
var currentScenario



# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		var scenario = data[currentScenario]
		var world = find_parent("World")
		
		# set world Time:
		world.timeHour = scenario["Time"][0]
		world.timeMinute = scenario["Time"][1]
		world.timeMSeconds = scenario["Time"][2]
		
		## Player:
		var player = world.get_node("Players/Player")
		player.length = scenario["TrainLength"]
		player.route = scenario["Route"].insert(0, scenario["StartInformation"]["StartRail"])
		player.forward = scenario["StartInformation"]["Direction"]
		player.startPosition = scenario["StartInformation"]["RailPosition"]
		
		var doorStatus = scenario["StartInformation"]["DoorStatus"]
		match doorStatus:
			0:
				pass
			1: 
				player.doorLeft = true
			2:
				player.doorRight = true
			3:
				player.doorLeft = true
				player.doorRight = true
		
		player.ready()
	
	pass
	
func save_scenario(scenarioName, inspectorData):
	var world = find_parent("World")
	var scenario = {}
	
	## Save Signals:
	var signals = {}
	for s in world.get_node("Signals").get_children():
		signals[s.name] = s.get_scenario_data()
	scenario["Signals"] = signals
	scenario["Route"] = inspectorData["Route"]
	scenario["Time"] = [inspectorData["Time"][0], inspectorData["Time"][1], inspectorData["Time"][2]]
	scenario["Description"] = inspectorData["Description"]
	
	scenario["TrainLength"] = inspectorData["TrainLength"]
	scenario["StartInformation"] = inspectorData["StartInformation"]
	data[scenarioName] = scenario
	
func get_all_scenarios():
	return data.keys()
	
func add_scenario(sName):
	var s = {}
	var i = {}
	s["Time"] = {}
	s["Time"][0] = 0
	s["Time"][1] =0
	s["Time"][2] = 0
	s["Route"] = "Rail1 Rail2 Rail18"
	s["TrainLength"] = 0
	s["StartInformation"] = {}
	s["StartInformation"]["StartRail"] = "Rail"
	s["StartInformation"]["RailPostion"] = 0
	s["StartInformation"]["Direction"] = 1
	s["StartInformation"]["DoorConfiguration"] = 0
	s["Description"] = "Scenario Description"
	s["Signals"] = {}
	data[sName] = s

func apply_scenario_to_enviroment(sName):
	var scenario = data[sName]
	var world = find_parent("World")
	var signals = scenario["Signals"]
	## Apply Scenario Data
	for signalN in  world.get_node("Signals").get_children():
		if signals.has(signalN.name):
			signalN.set_scenario_data(signals[signalN.name])
	
	
func rename_scenario(oldName, newName):
	data[newName] = data[oldName]
	data.erase(oldName)

func copy_scenario(sName, newSName):
	data[newSName] = data[sName].duplicate()
	
func get_inspector_data(sName):
	var s = data[sName]
	var inspectorData= {"Route" : s["Route"], "Description" : s["Description"], "TrainLength" : s["TrainLength"], "StartInformation" : s["StartInformation"], "Time" : s["Time"]}
	return inspectorData

func delete_scenario(sName):
	data.erase(sName)
