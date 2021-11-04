extends Spatial

onready var signal_logic: Node = get_parent()
onready var world: Node = find_parent("World")


func _ready() -> void:
	# force the signal to be a main signal
	signal_logic.signal_type = signal_logic.SignalType.MAIN
	# initialize signal
	update_visual_instance(signal_logic)


# main signal CANNOT be orange!
func update_visual_instance(instance: Node) -> void:
	match instance.status:
		SignalStatus.RED: red()
		SignalStatus.GREEN: green()
		SignalStatus.OFF: off()


# if the signal is not "STOP", but shows a speed limit, show Hp2
func green() -> void:
	$Red1.visible = false
	$Red2.visible = false
	$Green.visible = true
	$Orange.visible = signal_logic.speed > 0 and signal_logic.speed <= 60


func red() -> void:
	$Red1.visible = true
	$Red2.visible = true
	$Orange.visible = false
	$Green.visible = false


func off() -> void:
	$Red1.visible = false
	$Red2.visible = false
	$Orange.visible = false
	$Green.visible = false
