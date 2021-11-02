extends Spatial

# cannot use type Signal, because cyclic dependency... >_>
onready var signal_logic: Node = get_parent()
onready var world: Node = find_parent("World")
onready var hp_anim_fsm := $Hp/AnimationTree.get("parameters/playback")
onready var vo_anim_fsm := $Vo/AnimationTree.get("parameters/playback")

func _ready() -> void:
	# force the signal to be a combined signal
	signal_logic.signal_type = signal_logic.SignalType.COMBINED
	if signal_logic.signal_after == "":
		$Vo.queue_free()
	update_visual_instance(signal_logic)


func update_visual_instance(instance: Node) -> void:
	if instance.status == SignalStatus.RED:
		hp_anim_fsm.travel("Hp0")  # Halt
	else:
		if instance.speed > 0 and instance.speed <= 60:
			hp_anim_fsm.travel("Hp2")  # Langsamfahrt
		else:
			hp_anim_fsm.travel("Hp1")  # Fahrt

	if instance.signal_after_node != null:
		if instance.signal_after_node.status == SignalStatus.RED:
			vo_anim_fsm.travel("Vr0")  # Halt erwarten
		else:
			if instance.signal_after_node.speed > 0 and instance.signal_after_node.speed <= 60:
				vo_anim_fsm.travel("Vr2")  # Langsamfahrt erwarten
			else:
				vo_anim_fsm.travel("Vr1")  # Fahrt erwarten

