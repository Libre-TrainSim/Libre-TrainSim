extends Node

onready var Signal = get_parent()
onready var world = find_parent("World")

var orange = false
var blinking = false

func _ready():
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = $Viewport.get_texture()
	$Screen1.material_override = $Screen1.material_override.duplicate(true)
	$Screen1.material_override.emission_texture = texture
	
	$Viewport2.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = $Viewport2.get_texture()
	$Screen2.material_override = $Screen2.material_override.duplicate(true)
	$Screen2.material_override.emission_texture = texture

var timer = 0
func _process(delta):
	timer += delta
	if timer > 1:
		timer = 0
		update()
		Signal.orange = orange
		
func update():
	if not Signal.is_in_group("Signal"):
		printerr("Visual Instance is not directly attached at a SignalNode")
		return
	orange = false
	if world == null:
		world = find_parent("World")
	update_screen2()
	update_screen1()
	if Signal.warnSpeed != -1 and Signal.status == 1 and not blinking:
		off()
		blinking = true
		return
	blinking = false
	if Signal.status == 0:
		red()
	elif Signal.status == 1:
		if Signal.signalAfterNode !=  world.get_node("Signals") and Signal.signalAfterNode != null and Signal.signalAfterNode.status == 0:
			orange()
			orange = true
			return
		green()
	elif Signal.status < 0:
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
	
	
func update_screen2():
	if Signal.speed != -1:
		if Signal.speed - 100 >= 0:
			var outputSpeed = int(Signal.speed / 10)
			$Viewport2/Node2D/Label.text = String(outputSpeed)
		else: 
			var outputSpeed = int(Signal.speed / 10)
			var string = " " + String(outputSpeed)
			$Viewport2/Node2D/Label.text = string
		$Screen2.visible = true
	else:
		$Screen2.visible = false
		
func update_screen1():
	if Signal.warnSpeed != -1:
		if Signal.warnSpeed - 100 >= 0:
			var outputSpeed = int(Signal.warnSpeed / 10)
			$Viewport/Node2D/Label.text = String(outputSpeed)
		else: 
			var outputSpeed = int(Signal.warnSpeed / 10)
			var string = " " + String(outputSpeed)
			$Viewport/Node2D/Label.text = string
		$Screen1.visible = true
	else:
		$Screen1.visible = false
		
