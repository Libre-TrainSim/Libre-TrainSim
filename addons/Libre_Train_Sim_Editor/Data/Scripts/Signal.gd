tool
extends Spatial
var type = "Signal"
export var status = 0# 0: Red, 1: Green, -1: Off
var signalAfter = ""
onready var world = find_parent("World")
var signalAfterNode
export var setPassAtH = 25
export var setPassAtM = 0
export var setPassAtS = 0
export var speed = -1
var warnSpeed = -1
export var forward = true

export (String) var attachedRail
export (int) var onRailPosition
export (bool) var update setget setToRail

var blinking = false
var timer = 0
func _process(delta):
	if not Engine.is_editor_hint():
		if world.time[0] >= setPassAtH and world.time[2] >= setPassAtS and world.time[1] >= setPassAtM:
			status = 1
	timer += delta
	if timer > 1:
		timer = 0
		update()


func _ready():
	if Engine.is_editor_hint() and not get_parent().name == "Signals":
		if get_parent().is_in_group("Rail"):
			attachedRail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		update()
		
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = $Viewport.get_texture()
	$Screen1.material_override = $Screen1.material_override.duplicate(true)
	$Screen1.material_override.emission_texture = texture
	
	$Viewport2.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = $Viewport2.get_texture()
	$Screen2.material_override = $Screen2.material_override.duplicate(true)
	$Screen2.material_override.emission_texture = texture
	setToRail(true)
	update()
	pass

		
func update():
	if world == null:
		world = find_parent("World")
	if signalAfterNode == null and signalAfter != "":
		signalAfterNode = world.get_node("Signals/"+String(signalAfter))
	update_screen2()
	update_screen1()
	if warnSpeed != -1 and status == 1 and not blinking:
		off()
		blinking = true
		return
	blinking = false
	if status == 0:
		red()
	elif status == 1:
		signalAfterNode = world.get_node("Signals/"+signalAfter)
		if signalAfterNode !=  world.get_node("Signals") and signalAfterNode != null and signalAfterNode.status == 0:
			orange()
			return
		green()
	elif status < 0:
		off()

func green():
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = true

func red():
	$Red.visible = true
	$Orange.visible = false
	$Green.visible = false
	$Screen1.visible = false
	$Screen2.visible = false

func orange():
	$Red.visible = false
	$Orange.visible = true
	$Green.visible = false
	
func off():
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = false
	
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

func update_screen2():
	if speed != -1:
		if speed - 100 >= 0:
			var outputSpeed = int(speed / 10)
			$Viewport2/Node2D/Label.text = String(outputSpeed)
		else: 
			var outputSpeed = int(speed / 10)
			var string = " " + String(outputSpeed)
			$Viewport2/Node2D/Label.text = string
		$Screen2.visible = true
	else:
		$Screen2.visible = false
		
func update_screen1():
	if warnSpeed != -1:
		if warnSpeed - 100 >= 0:
			var outputSpeed = int(warnSpeed / 10)
			$Viewport/Node2D/Label.text = String(outputSpeed)
		else: 
			var outputSpeed = int(warnSpeed / 10)
			var string = " " + String(outputSpeed)
			$Viewport/Node2D/Label.text = string
		$Screen1.visible = true
	else:
		$Screen1.visible = false
		
func get_scenario_data():
	var d = {}
	d.status = status
	d.setPassAtH = setPassAtH
	d.setPassAtM = setPassAtM
	d.setPassAtS = setPassAtS 
	d.speed = speed
	return d

func set_scenario_data(d):
	status = d.status
	setPassAtH = d.setPassAtH
	setPassAtM = d.setPassAtM
	setPassAtS = d.setPassAtS 
	speed = d.speed
	

func reset():
	status = 0
	setPassAtH = 25
	setPassAtM = 0
	setPassAtS = 0
	speed = -1

	
	
