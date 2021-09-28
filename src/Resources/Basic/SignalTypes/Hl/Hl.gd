extends Spatial

onready var signal_logic = get_parent()
onready var world = find_parent("World")

var green1_blink = false
var orange1_blink = false

var timer

func _ready():
	# force the signal to be a combined signal
	signal_logic.signal_type = signal_logic.SignalType.COMBINED
	
	if signal_logic.speed == -1:
		printerr(signal_logic.name, ": HL Signals cannot have Speed -1! Please set a speed limit for this Signal! Setting to 160 km/h")
		signal_logic.speed = 160
	
	# Hl signals ALWAYS have a speed limit! NEVER -1 !!!
	if signal_logic.signal_after_node != null and signal_logic.signal_after_node.speed == -1:
		signal_logic.signal_after_node.speed = signal_logic.speed
		signal_logic.warn_speed = signal_logic.speed
	
	timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect("timeout", self, "_blink")
	self.add_child(timer)
	
	update_visual_instance(signal_logic)


func _blink():
	if green1_blink:
		$Green1.visible = !$Green1.visible
	if orange1_blink:
		$Orange1.visible = !$Orange1.visible


func update_visual_instance(instance):
	if instance.signal_after_node == null:
		instance.status = SignalStatus.RED
	
	# signal = red
	if instance.status == SignalStatus.RED:
		hl13()  # halt  (main signal)
	# signal = yellow, next signal = red
	elif instance.signal_after_node.status == SignalStatus.RED:
		if instance.speed > 100:
			hl10()  # max speed, expect halt  (presignal)
		elif instance.speed == 100:
			hl11()  # 100 km/h now, expect halt
		elif instance.speed == 40:
			hl12a()  # 40 km/h now, expect halt
		elif instance.speed == 60:
			hl12b()  # 60 km/h now, expect halt
	# signal = green, next signal = green or yellow
	elif instance.speed > 100 and instance.signal_after_node.speed > 100:
		hl1()  # go full speed
	elif instance.speed == 100 and instance.signal_after_node.speed > 100:
		hl2()  # 100 km/h now, full speed next
	elif instance.speed == 40 and instance.signal_after_node.speed > 100:
		hl3a()  # 40 km/h now, full speed next
	elif instance.speed == 60 and instance.signal_after_node.speed > 100:
		hl3b()  # 60 km/h now, full speed next
	elif instance.speed > 100 and instance.signal_after_node.speed == 100:
		hl4()   # full speed now, slow down to 100 km/h
	elif instance.speed == 100 and instance.signal_after_node.speed == 100:
		hl5()   # go 100 km/h
	elif instance.speed == 40 and instance.signal_after_node.speed == 100:
		hl6a()  # 40 km/h now, 100 km/h next
	elif instance.speed == 60 and instance.signal_after_node.speed == 100:
		hl6b()  # 60 km/h now, 100 km/h next
	elif instance.speed > 100 and instance.signal_after_node.speed <= 60:
		hl7()  # full speed now, slow down to 40 or 60 km/h (not specified which)
	elif instance.speed == 100 and instance.signal_after_node.speed <= 60:
		hl8()  # 100km/h now, slow down to 40 or 60 km/h
	elif instance.speed == 40 and instance.signal_after_node.speed <= 60:
		hl9a()  # 40 km/h now, 40 or 60 km/h next
	elif instance.speed == 60 and instance.signal_after_node.speed <= 60:
		hl9b()  # 60 km/h now, 40 or 60 km/h next


func hl1():
	$Red.visible = false
	$Green1.visible = true
	$Orange1.visible = false
	$Orange2.visible = false
	$OrangeStripe.visible = false
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = false

func hl2():
	$Red.visible = false
	$Green1.visible = true
	$Orange1.visible = false
	$Orange2.visible = true
	$OrangeStripe.visible = false
	$GreenStripe.visible = true
	orange1_blink = false
	green1_blink = false

func hl3a():
	$Red.visible = false
	$Green1.visible = true
	$Orange1.visible = false
	$Orange2.visible = true
	$OrangeStripe.visible = false
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = false

func hl3b():
	$Red.visible = false
	$Green1.visible = true
	$Orange1.visible = false
	$Orange2.visible = true
	$OrangeStripe.visible = true
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = false

func hl4():
	$Red.visible = false
	$Green1.visible = true
	$Orange1.visible = false
	$Orange2.visible = false
	$OrangeStripe.visible = false
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = true

func hl5():
	$Red.visible = false
	$Green1.visible = true
	$Orange1.visible = false
	$Orange2.visible = true
	$OrangeStripe.visible = false
	$GreenStripe.visible = true
	orange1_blink = false
	green1_blink = true

func hl6a():
	$Red.visible = false
	$Green1.visible = true
	$Orange1.visible = false
	$Orange2.visible = true
	$OrangeStripe.visible = false
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = true

func hl6b():
	$Red.visible = false
	$Green1.visible = true
	$Orange1.visible = false
	$Orange2.visible = true
	$OrangeStripe.visible = true
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = true

func hl7():
	$Red.visible = false
	$Green1.visible = false
	$Orange1.visible = true
	$Orange2.visible = false
	$OrangeStripe.visible = false
	$GreenStripe.visible = false
	orange1_blink = true
	green1_blink = false

func hl8():
	$Red.visible = false
	$Green1.visible = false
	$Orange1.visible = true
	$Orange2.visible = true
	$OrangeStripe.visible = false
	$GreenStripe.visible = true
	orange1_blink = true
	green1_blink = false

func hl9a():
	$Red.visible = false
	$Green1.visible = false
	$Orange1.visible = true
	$Orange2.visible = true
	$OrangeStripe.visible = false
	$GreenStripe.visible = false
	orange1_blink = true
	green1_blink = false

func hl9b():
	$Red.visible = false
	$Green1.visible = false
	$Orange1.visible = true
	$Orange2.visible = true
	$OrangeStripe.visible = true
	$GreenStripe.visible = false
	orange1_blink = true
	green1_blink = false

func hl10():
	$Red.visible = false
	$Green1.visible = false
	$Orange1.visible = true
	$Orange2.visible = false
	$OrangeStripe.visible = false
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = false

func hl11():
	$Red.visible = false
	$Green1.visible = false
	$Orange1.visible = true
	$Orange2.visible = true
	$OrangeStripe.visible = false
	$GreenStripe.visible = true
	orange1_blink = false
	green1_blink = false

func hl12a():
	$Red.visible = false
	$Green1.visible = false
	$Orange1.visible = true
	$Orange2.visible = true
	$OrangeStripe.visible = false
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = false

func hl12b():
	$Red.visible = false
	$Green1.visible = false
	$Orange1.visible = true
	$Orange2.visible = true
	$OrangeStripe.visible = true
	$GreenStripe.visible = false
	orange1_blink = false
	green1_blink = false

func hl13():
	$Red.visible = true
	$Green1.visible = false
	$Orange1.visible = false
	$Orange2.visible = false
	$GreenStripe.visible = false
	$OrangeStripe.visible = false
	orange1_blink = false
	green1_blink = false
