class_name ContactPoint
extends RailLogic

export var affectedSignal: String = ""
export var disabled: bool = false
export var newStatus: int = 1
export var newSpeed: float = -1
export var enable_for_all_trains: bool = true
export var bySpecificTrain: String = ""
export var affectTime: float = 0.1

export (String) var attached_rail: String
export (int) var on_rail_position: int
export var forward: bool = true


func _get_type() -> String:
	return RailLogicTypes.CONTACT_POINT


func _ready() -> void:
	if not Root.Editor or Root.scenario_editor:
		$Timer.wait_time = affectTime # affectTime MUST be > 0!
		$Mesh.queue_free()

	set_to_rail()


func set_to_rail() -> void:
	assert(is_inside_tree())
	assert(not not world)

	if world.has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail = world.get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.translation = rail.get_pos_at_distance(on_rail_position)
		self.rotation.y = rail.get_rad_at_distance(on_rail_position)
		if not forward:
			self.rotation_degrees.y += 180


func set_data(d: Dictionary) -> void:
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
