tool
extends Node

onready var signal_logic = get_parent()
onready var world = find_parent("World")

var blink_timer

func _ready():
	blink_timer = Timer.new()
	blink_timer.wait_time = 0.5 # blink twice a second
	blink_timer.connect("timeout", self, "blink")
	self.add_child(blink_timer)
	
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = $Viewport.get_texture()
	$Screen1.material_override = $Screen1.material_override.duplicate(true)
	$Screen1.material_override.emission_texture = texture
	
	$Viewport2.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = $Viewport2.get_texture()
	$Screen2.material_override = $Screen2.material_override.duplicate(true)
	$Screen2.material_override.emission_texture = texture
	
	
	match signal_logic.signal_type:
		signal_logic.SignalType.MAIN:
			$HpTafel.visible = true
			$VoTafel.visible = false
			$KsTafel.visible = false
		signal_logic.SignalType.PRESIGNAL:
			$HpTafel.visible = false
			$VoTafel.visible = true
			$KsTafel.visible = false
		signal_logic.SignalType.COMBINED:
			$HpTafel.visible = true
			$VoTafel.visible = false
			$KsTafel.visible = true
	
	# initialize signal
	update_visual_instance(signal_logic)
	$Viewport2/Node2D/Label.text = make_speed_str(signal_logic.speed)
	$Viewport/Node2D/Label.text = make_speed_str(signal_logic.warn_speed)


func blink():
	$Green.visible = !$Green.visible


func update_visual_instance(instance):
	match instance.status:
		SignalStatus.RED: red()
		SignalStatus.GREEN: green()
		SignalStatus.ORANGE: orange()
		SignalStatus.OFF: off()
	
	if instance.speed < 0:
		$Screen2.visible = false
	else:
		$Viewport2/Node2D/Label.text = make_speed_str(instance.speed)
		$Screen2.visible = true
	
	if instance.warn_speed < 0:
		$Screen1.visible = false
	else:
		$Viewport/Node2D/Label.text = make_speed_str(instance.warn_speed)
		$Screen1.visible = true


func green():
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = true
	$Screen1.visible = signal_logic.warn_speed > 0
	$Screen2.visible = signal_logic.speed > 0
	if signal_logic.warn_speed != -1:
		blink_timer.start()

func red():
	$Red.visible = true
	$Orange.visible = false
	$Green.visible = false
	$Screen1.visible = false
	$Screen2.visible = false
	blink_timer.stop()

func orange():
	$Red.visible = false
	$Orange.visible = true
	$Green.visible = false
	$Screen1.visible = signal_logic.warn_speed > 0
	$Screen2.visible = signal_logic.speed > 0
	blink_timer.stop()
	
func off():
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = false
	$Screen1.visible = false
	$Screen2.visible = false
	blink_timer.stop()

func make_speed_str(speed):
	var string
	if speed - 100 >= 0:
		var outputSpeed = int(speed / 10)
		string = str(outputSpeed)
	else: 
		var outputSpeed = int(speed / 10)
		string = " " + str(outputSpeed)
	return string

