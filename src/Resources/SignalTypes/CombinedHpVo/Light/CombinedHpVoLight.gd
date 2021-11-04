extends Spatial

onready var signal_logic: Node = get_parent()
onready var world: Node = find_parent("World")


func _ready() -> void:
	# force the signal to be a combined signal
	signal_logic.signal_type = signal_logic.SignalType.COMBINED
	# initialize signal
	update_visual_instance(signal_logic)


func update_visual_instance(instance: Node) -> void:
	match instance.status:
		SignalStatus.RED: hp0()
		SignalStatus.GREEN: hp1()
		SignalStatus.OFF: off()

	if instance.signal_after_node != null:
		match instance.signal_after_node.status:
			SignalStatus.RED: vr0()
			SignalStatus.GREEN: vr1()
			SignalStatus.OFF: off()


func hp0() -> void:
	$Red1.visible = true
	$Red2.visible = true
	$OrangeHp.visible = false
	$GreenHp.visible = false


func hp1() -> void:
	$Red1.visible = false
	$Red2.visible = false
	$OrangeHp.visible = signal_logic.speed > 0 and signal_logic.speed <= 60 # Hp2
	$GreenHp.visible = true


func vr0() -> void:
	$OrangeVo1.visible = true
	$OrangeVo2.visible = true
	$GreenVo1.visible = false
	$GreenVo2.visible = false


func vr1() -> void:
	#Vr2
	if signal_logic.signal_after_node.speed > 0 and signal_logic.signal_after_node.speed <= 60:
		$OrangeVo1.visible = true
		$OrangeVo2.visible = false
		$GreenVo1.visible = false
		$GreenVo2.visible = true
	else:
		$OrangeVo1.visible = false
		$OrangeVo2.visible = false
		$GreenVo1.visible = true
		$GreenVo2.visible = true


func off() -> void:
	$Red1.visible = false
	$Red2.visible = false
	$OrangeHp.visible = false
	$OrangeVo1.visible = false
	$OrangeVo2.visible = false
	$GreenHp.visible = false
	$GreenVo1.visible = false
	$GreenVo2.visible = false

