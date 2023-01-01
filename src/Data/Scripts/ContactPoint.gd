class_name ContactPoint
extends RailLogic

export var affectedSignal: String = ""
export var disabled: bool = false
export var newStatus: int = 1
export var newSpeed: float = -1
export var enable_for_all_trains: bool = true
export var bySpecificTrain: String = ""
export var affectTime: float = 0.1


func _get_type() -> String:
	return RailLogicTypes.CONTACT_POINT


func _ready() -> void:
	if not Root.Editor or Root.scenario_editor:
		$Timer.wait_time = affectTime # affectTime MUST be > 0!
		$Mesh.queue_free()

	set_to_rail()


func set_data(d: ContactPointSettings) -> void:
	affectTime = d.affect_time
	affectedSignal = d.affected_signal
	enable_for_all_trains = d.enable_for_all_trains
	disabled = !d.enabled
	newSpeed = d.new_speed_limit
	newStatus = d.new_status
	bySpecificTrain = d.specific_train


func reset() -> void:
	affectedSignal = ""
	bySpecificTrain = ""
	newStatus = 1
	affectTime = 0.1


func activateContactPoint(trainName: String) -> void:
	if disabled:
		 return
	if affectedSignal == "":
		return
	if enable_for_all_trains or trainName == bySpecificTrain:
		$Timer.start()


func _on_Timer_timeout() -> void:
	var signalN: Spatial = get_parent().get_node(affectedSignal)
	if signalN == null:
		Logger.err("Contact Point "+ name + " could not find signal "+affectedSignal+" aborting...", self)
		return
	if signalN.type != "Signal":
		Logger.err("Contact Point "+ name + ": Specified signal point is no Signal. Aborting...", self)
		return
	signalN.set_status(newStatus)
	signalN.set_speed(newSpeed)
