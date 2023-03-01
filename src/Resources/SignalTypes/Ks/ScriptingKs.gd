extends Node

onready var signal_logic: Node = get_parent()
onready var world: Node = find_parent("World")

var blink_timer: Timer

func _ready() -> void:
	blink_timer = Timer.new()
	blink_timer.wait_time = 0.5 # blink twice a second
	var _unused = blink_timer.connect("timeout", self, "blink")
	self.add_child(blink_timer)

	match signal_logic.signal_type:
		signal_logic.SignalType.MAIN:
			$HpTafel.visible = true
			$VoTafel.visible = false
			$KsTafel.visible = false
			$Zs3v.visible = false
			$Zs3.visible = true
		signal_logic.SignalType.PRESIGNAL:
			$HpTafel.visible = false
			$VoTafel.visible = true
			$KsTafel.visible = false
			$Zs3.visible = false
			$Zs3v.visible = true
		signal_logic.SignalType.COMBINED:
			$HpTafel.visible = true
			$VoTafel.visible = false
			$KsTafel.visible = true
			$Zs3v.visible = true
			$Zs3.visible = true

	# initialize signal
	update_visual_instance(signal_logic)
	$Screen2.text = make_speed_str(signal_logic.speed)
	$Screen1.text = make_speed_str(signal_logic.warn_speed)


func blink() -> void:
	$Green.visible = !$Green.visible


func update_visual_instance(instance: Node) -> void:
	$Screen2.text = make_speed_str(instance.speed)
	$Screen1.text = make_speed_str(instance.warn_speed)

	match instance.status:
		SignalStatus.RED: red()
		SignalStatus.GREEN: green()
		SignalStatus.ORANGE: orange()
		SignalStatus.OFF: off()


func green() -> void:
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = true
	$Screen1.visible = signal_logic.warn_speed > 0
	$Screen2.visible = signal_logic.speed > 0
	if signal_logic.warn_speed != -1:
		blink_timer.start()


func red() -> void:
	$Red.visible = true
	$Orange.visible = false
	$Green.visible = false
	$Screen1.visible = false
	$Screen2.visible = false
	blink_timer.stop()


func orange() -> void:
	$Red.visible = false
	$Orange.visible = true
	$Green.visible = false
	$Screen1.visible = signal_logic.warn_speed > 0
	$Screen2.visible = signal_logic.speed > 0
	blink_timer.stop()


func off() -> void:
	$Red.visible = false
	$Orange.visible = false
	$Green.visible = false
	$Screen1.visible = false
	$Screen2.visible = false
	blink_timer.stop()


func make_speed_str(speed: float) -> String:
	var outputSpeed: int = int(speed / 10)
	return str(outputSpeed)

