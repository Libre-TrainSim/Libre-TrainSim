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

export var set_pass_at_h: int = -1 # If these 3 variables represent a real time (24h format), the signal will be turned green at this specified time.
export var set_pass_at_m: int = 0
export var set_pass_at_s: int = 0
var did_set_pass: bool = false

export var speed: float = -1 setget set_speed # SpeedLimit, which will be applied to the train. If -1: Speed Limit won't be changed by overdriving.
var warn_speed: float = -1 setget set_warn_speed # Displays the speed of the following speedlimit. Just used for the player train. It doesn't affect any train..

export var is_block_signal: bool = false setget on_update_block_signal_setting

export (String, FILE, "*.tscn,*.scn") var visual_instance_path: String = "res://Resources/SignalTypes/Ks/Ks.tscn"
export (String) var attached_rail: String # Internal. Never change this via script.
var attached_rail_node: Node
export var forward: bool = true # Internal. Never change this via script.
export (int) var on_rail_position: int # Internal. Never change this via script.


func _get_type() -> String:
	return RailLogicTypes.SIGNAL


var timer
func update_visual_instance() -> void:
	update()

	assert(world != null)

	if not is_instance_valid(attached_rail_node):
		attached_rail_node = world.get_node("Rails/" + attached_rail)
		if attached_rail_node == null:
			queue_free()
			return

	visible = attached_rail_node.visible
	if not attached_rail_node.visible:
		if get_node_or_null("VisualInstance") != null:
			$VisualInstance.queue_free()
		return

	if get_node_or_null("VisualInstance") == null:
		create_visual_instance()


func create_visual_instance() -> void:
	if visual_instance_path.empty():
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
	if Engine.is_editor_hint() and is_block_signal:
		set_status(SignalStatus.GREEN)

	assert(world != null)

	if signal_after_node == null and not signal_after.empty():
		signal_after_node = world.get_node("Signals/"+String(signal_after))

	if not did_set_pass and not Engine.is_editor_hint() and not Root.Editor and world.time != null:
		if world.time[0] >= set_pass_at_h and world.time[1] >= set_pass_at_m and world.time[2] >= set_pass_at_s:
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

	# Set Signal while adding to the Signals node
	if Engine.is_editor_hint() and not get_parent().name == "Signals":
		if get_parent().is_in_group("Rail"):
			attached_rail = get_parent().name
		var signals = world.get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		update()

	if is_block_signal:
		set_status(SignalStatus.GREEN)

	set_to_rail()
	update()


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
	assert(world != null)

	if world.has_node("Rails/"+attached_rail) and not attached_rail.empty():
		var rail = get_parent().get_parent().get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.translation = rail.get_pos_at_RailDistance(on_rail_position)
		self.rotation_degrees.y = rail.get_deg_at_RailDistance(on_rail_position)
		if not forward:
			self.rotation_degrees.y += 180


func give_signal_free() -> void:
	if is_block_signal:
		set_status(SignalStatus.GREEN)


func get_scenario_data() -> Dictionary:
	var d = {}
	d.status = status
	d.set_pass_at_h = set_pass_at_h
	d.set_pass_at_m = set_pass_at_m
	d.set_pass_at_s = set_pass_at_s
	d.speed = speed
	d.is_block_signal = is_block_signal
	return d


func set_scenario_data(d: Dictionary) -> void:
	set_status(d.status)
	set_pass_at_h = d.set_pass_at_h
	set_pass_at_m = d.set_pass_at_m
	set_pass_at_s = d.set_pass_at_s
	set_speed(d.speed)
	is_block_signal = d.get("is_block_signal", false)


func reset() -> void:
	set_status(SignalStatus.RED)
	set_pass_at_h = 25
	set_pass_at_m = 0
	set_pass_at_s = 0
	set_speed(-1)
	is_block_signal = false


func on_update_block_signal_setting(new_value: bool) -> void:
	if new_value == false:
		status = SignalStatus.RED
	is_block_signal = new_value
