class_name Signal
extends RailLogic


enum SignalType {
	MAIN = 1,
	PRESIGNAL = 2,
	COMBINED = 3
}
export(SignalType) var signal_type: int = SignalType.COMBINED

export(SignalStatus.TypeHint) var status: int = SignalStatus.RED setget set_status
signal signal_changed(signal_instance)

var signal_after: String = "" # SignalName of the following signal. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!
var signal_after_node: Node # Reference to the signal after it. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!

export var signal_free_time: int = -1 # the signal will be turned to status = 1 at this specified time. Set to -1 to deactivate. Only available in manual mode.
var did_set_pass: bool = false

export var speed: float = -1 setget set_speed # SpeedLimit, which will be applied to the train. If -1: Speed Limit won't be changed by overdriving.
var warn_speed: float = -1 setget set_warn_speed # Displays the speed of the following speedlimit. Just used for the player train. It doesn't affect any train..

export (String, FILE, "*.tscn,*.scn") var visual_instance_path: String = "res://Resources/SignalTypes/Ks/Ks.tscn"
export (String) var attached_rail: String # Internal. Never change this via script.
var attached_rail_node: Node
export var forward: bool = true # Internal. Never change this via script.
export (int) var on_rail_position: int # Internal. Never change this via script.

export(SignalOperationMode) var operation_mode: int = SignalOperationMode.BLOCK


func _get_type() -> String:
	return RailLogicTypes.SIGNAL


var timer
func update_visual_instance() -> void:
	update()
	if not is_instance_valid(attached_rail_node):
		attached_rail_node = world.get_node("Rails/" + attached_rail)
		if attached_rail_node == null:
			queue_free()
			return

	visible = attached_rail_node.visible
	if not attached_rail_node.visible:
		if get_node_or_null("VisualInstance") != null:
			self.disconnect("signal_changed", $VisualInstance, "update_visual_instance")
			$VisualInstance.queue_free()
			if get_node_or_null("SelectCollider") != null:
				$SelectCollider.queue_free()

		return

	if get_node_or_null("VisualInstance") == null:
		create_visual_instance()


func create_visual_instance() -> void:
	if visual_instance_path == "":
		visual_instance_path = "res://Resources/SignalTypes/Ks/Ks.tscn"
	var visual_instance = load(visual_instance_path).instance()
	add_child(visual_instance)
	visual_instance.name = "VisualInstance"
	visual_instance.owner = self
	connect_visual_instance()


func connect_visual_instance() -> void:
	var visual_instance = get_node_or_null("VisualInstance")
	var _unused = self.connect("signal_changed", visual_instance, "update_visual_instance")


func update() -> void:
	if Root.Editor and operation_mode == SignalOperationMode.BLOCK:
		set_status(SignalStatus.GREEN)

	assert(not not world)

	if operation_mode == SignalOperationMode.STATION:
		if world.get_assigned_station_of_signal(name) == null:
			Logger.warn("%s should run in station mode, but can't find it's correspondending station. Switching to block mode..." % name, "Signal")
			set_operation_mode(SignalOperationMode.BLOCK)

	if signal_after_node == null and signal_after != "":
		signal_after_node = world.get_node("Signals/"+String(signal_after))

	if operation_mode == SignalOperationMode.MANUAL and signal_free_time != -1 and not did_set_pass and not Root.Editor and world.time > signal_free_time:
		set_status(SignalStatus.GREEN)
		did_set_pass = true

	# set signal orange if next signal is RED and this signal is not RED, but only for Pre- and Combined Signals
	if signal_type != SignalType.MAIN and status == SignalStatus.GREEN and signal_after_node != null and signal_after_node.status == SignalStatus.RED:
		set_status(SignalStatus.ORANGE)


func _ready() -> void:
	timer = Timer.new()
	timer.connect("timeout", self, "update_visual_instance")
	self.add_child(timer)
	timer.start()

	if get_node_or_null("VisualInstance") != null:
		connect_visual_instance()
	else:
		create_visual_instance()

	set_to_rail()
	update()

	if operation_mode == SignalOperationMode.BLOCK:
		set_status(SignalStatus.GREEN)

	if [SignalOperationMode.BLOCK, SignalOperationMode.STATION].has(operation_mode):
		signal_free_time = -1



# signals necessary for RailMap to work
func set_status(new_val: int) -> void:
	if signal_type == SignalType.PRESIGNAL and new_val == SignalStatus.RED:
		Logger.err(name + ": Cannot set a presignal to red!", self)
		return
	if signal_type == SignalType.MAIN and new_val == SignalStatus.ORANGE:
		Logger.err(name + ": Cannot set a main signal to orange!", self)
		return

	# make sure signal does not become green when it should be orange
	if signal_type != SignalType.MAIN and new_val == SignalStatus.GREEN and signal_after_node != null and signal_after_node.status == SignalStatus.RED:
		new_val = SignalStatus.ORANGE

	status = new_val
	emit_signal("signal_changed", self)


func set_speed(new_speed: float) -> void:
	speed = new_speed
	emit_signal("signal_changed", self)


func set_warn_speed(new_speed: float) -> void:
	warn_speed = new_speed
	emit_signal("signal_changed", self)



func set_to_rail() -> void:
	assert(is_inside_tree())
	assert(not not world)

	if world.has_node("Rails/"+attached_rail) and attached_rail != "":
		var rail: Node = world.get_node("Rails/"+attached_rail)
		if not Root.scenario_editor:
			rail.register_signal(self.name, on_rail_position)
			self.translation = rail.get_pos_at_RailDistance(on_rail_position)
			self.rotation_degrees.y = rail.get_deg_at_RailDistance(on_rail_position)
			if not forward:
				self.rotation_degrees.y += 180


func give_signal_free() -> void:
	if operation_mode == SignalOperationMode.BLOCK:
		set_status(SignalStatus.GREEN)


func set_data(d: Dictionary) -> void:
	set_status(d.status)
	signal_free_time = d.signal_free_time
	set_speed(d.speed)
	set_operation_mode(d.operation_mode)


func reset() -> void:
	set_status(SignalStatus.RED)
	signal_free_time = -1
	set_speed(-1)
	operation_mode = SignalOperationMode.BLOCK


func set_operation_mode(mode: int):
	operation_mode = mode
	if operation_mode == SignalOperationMode.BLOCK:
		set_status(SignalStatus.GREEN)
		signal_free_time = -1
	elif operation_mode == SignalOperationMode.STATION:
		set_status(SignalStatus.RED)
		signal_free_time = -1
