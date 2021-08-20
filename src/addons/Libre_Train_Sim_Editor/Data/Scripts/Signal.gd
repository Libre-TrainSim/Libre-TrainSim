tool
extends Spatial
const type = "Signal" # Never change this type!!
onready var world = find_parent("World")

enum SignalType {
	MAIN = 1,
	PRESIGNAL = 2,
	COMBINED = 3
}
export(SignalType) var signal_type = SignalType.COMBINED

export var status = SignalStatus.RED setget set_status
signal status_changed(signal_instance)

var signalAfter = "" # SignalName of the following signal. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!
var signalAfterNode # Reference to the signal after it. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!

export var setPassAtH = -1 # If these 3 variables represent a real time (24h format), the signal will be turned green at this specified time.
export var setPassAtM = 0
export var setPassAtS = 0
var did_set_pass = false

export var speed = -1 setget set_speed # SpeedLimit, which will be applied to the train. If -1: Speed Limit won't be changed by overdriving.
var warn_speed = -1 setget set_warn_speed # Displays the speed of the following speedlimit. Just used for the player train. It doesn't affect any train..

signal warn_speed_changed(new_speed)
signal speed_changed(new_speed)

export var blockSignal = false setget on_update_block_signal_setting

export var visualInstancePath = "res://Resources/Basic/SignalTypes/Default/Default.tscn"
export (String) var attachedRail # Internal. Never change this via script.
var attachedRailNode
export var forward = true # Internal. Never change this via script.
export (int) var onRailPosition # Internal. Never change this via script.

export (bool) var update setget setToRail # Just uesd for the editor. If it will be pressed, then the function set_get rail will be


var timer
func updateVisualInstance():
	update()
	if attachedRailNode == null:
		attachedRailNode = find_parent("World").get_node("Rails" + "/" + attachedRail)
		if attachedRailNode == null:
			return

	visible = attachedRailNode.visible
	if not attachedRailNode.visible:
		if get_node_or_null("VisualInstance") != null:
			$VisualInstance.queue_free()
		return

	if get_node_or_null("VisualInstance") == null:
		create_visual_instance()


func create_visual_instance():
	#print("creating visual instance")
	var visualInstanceResource = null
	if visualInstancePath != "":
		visualInstanceResource = load(visualInstancePath)
	if visualInstanceResource == null:
		visualInstanceResource = load("res://Resources/Basic/Signals/Default.tscn")
	var visualInstance = visualInstanceResource.instance()
	add_child(visualInstance)
	visualInstance.name = "VisualInstance"
	visualInstance.owner = self
	connect_visual_instance()


func connect_visual_instance():
	var visualInstance = get_node_or_null("VisualInstance")
	self.connect("status_changed", visualInstance, "update_status")
	self.connect("speed_changed", visualInstance, "update_speed")
	self.connect("warn_speed_changed", visualInstance, "update_warn_speed")


func update():
	if Engine.is_editor_hint() and blockSignal:
		set_status(SignalStatus.GREEN)
	
	if world == null:
		world = find_parent("World")
	
	if signalAfterNode == null and signalAfter != "":
		signalAfterNode = world.get_node("Signals/"+String(signalAfter))
	
	if not did_set_pass and not Engine.is_editor_hint() and world.time != null:
		if world.time[0] >= setPassAtH and world.time[1] >= setPassAtM and world.time[2] >= setPassAtS:
			set_status(SignalStatus.GREEN)
			did_set_pass = true
	
	# set signal orange if next signal is RED and this signal is not RED, but only for Pre- and Combined Signals
	if signal_type != SignalType.MAIN and status == SignalStatus.GREEN and signalAfterNode != null and signalAfterNode.status == SignalStatus.RED:
		set_status(SignalStatus.ORANGE)


func _ready():
	timer = Timer.new()
	timer.connect("timeout", self, "updateVisualInstance")
	self.add_child(timer)
	timer.start()
	
	if get_node_or_null("VisualInstance") != null:
		connect_visual_instance()
	
	# Set Signal while adding to the Signals node
	if Engine.is_editor_hint() and not get_parent().name == "Signals":
		if get_parent().is_in_group("Rail"):
			attachedRail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		update()

	if blockSignal:
		set_status(SignalStatus.GREEN)

	setToRail(true)
	update()

# signals necessary for RailMap to work
func set_status(new_val):
	if signal_type == SignalType.PRESIGNAL and new_val == SignalStatus.RED:
		print(name, ": Cannot set a presignal to red!")
		return
	if signal_type == SignalType.MAIN and new_val == SignalStatus.ORANGE:
		print(name, ": Cannot set a main signal to orange!")
		return
	status = new_val
	emit_signal("status_changed", self)


func set_speed(new_speed):
	speed = new_speed
	emit_signal("speed_changed", new_speed)


func set_warn_speed(new_speed):
	warn_speed = new_speed
	emit_signal("warn_speed_changed", new_speed)


func setToRail(newvar):
	var world = find_parent("World")
	if world == null:
		print(name, ": CAN'T FIND WORLD NODE!")
		return
	if world.has_node("Rails/"+attachedRail) and attachedRail != "":
		var rail = get_parent().get_parent().get_node("Rails/"+attachedRail)
		rail.register_signal(self.name, onRailPosition)
		self.translation = rail.get_pos_at_RailDistance(onRailPosition)
		self.rotation_degrees.y = rail.get_deg_at_RailDistance(onRailPosition)
		if not forward:
			self.rotation_degrees.y += 180


func giveSignalFree():
	if blockSignal:
		set_status(SignalStatus.GREEN)


func get_scenario_data():
	var d = {}
	d.status = status
	d.setPassAtH = setPassAtH
	d.setPassAtM = setPassAtM
	d.setPassAtS = setPassAtS
	d.speed = speed
	d.blockSignal = blockSignal
	return d


func set_scenario_data(d):
	set_status(d.status)
	setPassAtH = d.setPassAtH
	setPassAtM = d.setPassAtM
	setPassAtS = d.setPassAtS
	set_speed(d.speed)
	blockSignal = d.get("blockSignal", false)


func reset():
	set_status(SignalStatus.RED)
	setPassAtH = 25
	setPassAtM = 0
	setPassAtS = 0
	set_speed(-1)
	blockSignal = false

func on_update_block_signal_setting(new_value):
	if new_value == false:
		status = 0
	blockSignal = new_value
