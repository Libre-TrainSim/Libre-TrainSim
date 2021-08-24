tool
extends Spatial
const type = "Signal" # Never change this type!!
onready var world = find_parent("World")



export var status = 0 setget set_status # 0: Red, 1: Green, -1: Off,
signal status_changed(signal_instance)

var signalAfter = "" # SignalName of the following signal. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!
var signalAfterNode # Reference to the signal after it. Set by the route manager from the players train. Just works for the players route. Should only be used for visuals!!

export var setPassAtH = -1 # If these 3 variables represent a real time (24h format), the signal will be turned green at this specified time.
export var setPassAtM = 0
export var setPassAtS = 0

export var speed = -1 # SpeedLimit, which will be applied to the train. If -1: Speed Limit won't be changed by overdriving.
var warnSpeed = -1 # Displays the speed of the following speedlimit. Just used for the player train. It doesn't affect any train..

export var blockSignal = false

var orange = false setget set_orange



export var visualInstancePath = ""
export (String) var attachedRail # Internal. Never change this via script.
var attachedRailNode
export var forward = true # Internal. Never change this via script.
export (int) var onRailPosition # Internal. Never change this via script.

export (bool) var update setget setToRail # Just uesd for the editor. If it will be pressed, then the function set_get rail will be

var timer = 0
func _process(delta):
	timer += delta
	if timer < 0.5:
		return
	timer = 0

	if not Engine.is_editor_hint():
		if world.time[0] == setPassAtH and world.time[1] == setPassAtM and world.time[2] == setPassAtS:
			set_status(1)
	updateVisualInstance()

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
		# Load Visual Instance:
		var visualInstanceResource = null
		if visualInstancePath != "":
			visualInstanceResource = load(visualInstancePath)
		if visualInstanceResource == null:
			visualInstanceResource = load("res://Resources/Basic/Signals/Default.tscn")
		var visualInstance = visualInstanceResource.instance()
		add_child(visualInstance)
		visualInstance.name = "VisualInstance"
		visualInstance.owner = self



func update():
	if Engine.is_editor_hint() and blockSignal:
		set_status(1)
	if world == null:
		world = find_parent("World")
	if signalAfterNode == null and signalAfter != "":
		signalAfterNode = world.get_node("Signals/"+String(signalAfter))



func _ready():
	# Set Signal while adding to the Signals node
	if Engine.is_editor_hint() and not get_parent().name == "Signals":
		if get_parent().is_in_group("Rail"):
			attachedRail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		update()
	
	if blockSignal:
		set_status(1)
	
	setToRail(true)
	update()

# signals necessary for RailMap to work
func set_status(new_val):
	status = new_val
	emit_signal("status_changed", self)

func set_orange(new_val):
	orange = new_val
	emit_signal("status_changed", self)

func setToRail(newvar):
	var world = find_parent("World")
	if world == null:
		print("Signal CANT FIND WORLD NODE!")
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
		set_status(1)


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
	speed = d.speed
	blockSignal = d.get("blockSignal", false)


func reset():
	set_status(0)
	setPassAtH = 25
	setPassAtM = 0
	setPassAtS = 0
	speed = -1
	blockSignal = false
