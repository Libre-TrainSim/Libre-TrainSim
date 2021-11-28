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
	if Engine.is_editor_hint():
		add_child(preload("res://Data/Modules/SelectCollider.tscn").instance())
		if get_parent().name == "Signals":
			return
		if get_parent().is_in_group("Rail"):
			attached_rail = get_parent().name
		var signals: Spatial = world.get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		set_to_rail()

	if not Engine.is_editor_hint():
		$Timer.wait_time = affectTime # affectTime MUST be > 0!
		$MeshInstance.queue_free()
		set_to_rail()


func set_to_rail() -> void:
	assert(is_inside_tree())
	assert(not not world)

	if world.has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail = world.get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.translation = rail.get_pos_at_RailDistance(on_rail_position)
		self.rotation_degrees.y = rail.get_deg_at_RailDistance(on_rail_position)
		if not forward:
			self.rotation_degrees.y += 180


func set_scenario_data(d: Dictionary) -> void:
	var a = self
	var b = d
	a.affectedSignal = b.affectedSignal
	a.bySpecificTrain = b.bySpecificTrain
	a.newStatus = b.newStatus
	a.affectTime = b.affectTime
	a.newSpeed = b.get("newSpeed", -1)

func get_scenario_data() -> Dictionary:
	var a = {}
	var b = self
	a.affectedSignal = b.affectedSignal
	a.bySpecificTrain = b.bySpecificTrain
	a.newStatus = b.newStatus
	a.affectTime = b.affectTime
	a.newSpeed = b.newSpeed
	return a

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
