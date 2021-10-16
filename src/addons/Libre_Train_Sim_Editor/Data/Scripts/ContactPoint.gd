tool
extends Spatial

var type = "ContactPoint"

export var affectedSignal = ""
export var disabled = false
export var newStatus = 1
export var newSpeed = -1
export var enable_for_all_trains = true
export var bySpecificTrain = ""
export var affectTime = 0.1

export (String) var attached_rail
export (int) var on_rail_position
export (bool) var update setget set_to_rail
export var forward = true


func _ready():
	if Engine.is_editor_hint():
		if get_parent().name == "Signals":
			return
		if get_parent().is_in_group("Rail"):
			attached_rail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		set_to_rail(true)
	if not Engine.is_editor_hint():
		$Timer.wait_time = affectTime # affectTime MUST be > 0!
		$MeshInstance.queue_free()
		set_to_rail(true)



# warning-ignore:unused_argument
func set_to_rail(newvar):
	if not find_parent("World"):
		Logger.err("ContactPoint can't find World Parent!", self)
		return

	if find_parent("World").has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail = find_parent("World").get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.translation = rail.get_pos_at_RailDistance(on_rail_position)
		self.rotation_degrees.y = rail.get_deg_at_RailDistance(on_rail_position)
		if not forward:
			self.rotation_degrees.y += 180


func set_scenario_data(d):
	var a = self
	var b = d
	a.affectedSignal = b.affectedSignal
	a.bySpecificTrain = b.bySpecificTrain
	a.newStatus = b.newStatus
	a.affectTime = b.affectTime
	a.newSpeed = b.get("newSpeed", -1)

func get_scenario_data():
	var a = {}
	var b = self
	a.affectedSignal = b.affectedSignal
	a.bySpecificTrain = b.bySpecificTrain
	a.newStatus = b.newStatus
	a.affectTime = b.affectTime
	a.newSpeed = b.newSpeed
	return a

func reset():
	affectedSignal = ""
	bySpecificTrain = ""
	newStatus = 1
	affectTime = 0.1

func activateContactPoint(trainName):
	if disabled: return
	if affectedSignal == "": return
	if enable_for_all_trains or trainName == bySpecificTrain:
		$Timer.start()

func _on_Timer_timeout():
	var signalN = get_parent().get_node(affectedSignal)
	if signalN == null:
		Logger.err("Contact Point "+ name + " could not find signal "+affectedSignal+" aborting...", self)
		return
	if signalN.type != "Signal":
		Logger.err("Contact Point "+ name + ": Specified signal point is no Signal. Aborting...", self)
		return
	signalN.set_status(newStatus)
	signalN.set_speed(newSpeed)
