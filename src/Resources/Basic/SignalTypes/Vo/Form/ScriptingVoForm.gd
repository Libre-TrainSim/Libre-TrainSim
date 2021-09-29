extends Spatial

onready var signal_logic = get_parent()
onready var world = find_parent("World")
onready var anim_fsm = $AnimationTree.get("parameters/playback")

func _ready():
	# force the signal to be a pre-signal
	signal_logic.signal_type = signal_logic.SignalType.PRESIGNAL
	update_visual_instance(signal_logic)

# this is a MAIN signal, it CANNOT be orange!
func update_visual_instance(instance):
	match instance.status:
		SignalStatus.ORANGE: orange()
		SignalStatus.GREEN: green()

func green():
	if signal_logic.warn_speed > 0 and signal_logic.warn_speed <= 60:
		anim_fsm.travel("Vr2")  # Langsamfahrt erwarten
		$formsignal_vo/Armature/Skeleton/lowerLight/Orange.visible = true
		$formsignal_vo/Armature/Skeleton/upperLight/Green.visible = true
		$formsignal_vo/Armature/Skeleton/upperLight/Orange.visible = false
		$formsignal_vo/Armature/Skeleton/lowerLight/Green.visible = false
	else:
		anim_fsm.travel("Vr1")  # Fahrt erwarten
		$formsignal_vo/Armature/Skeleton/lowerLight/Green.visible = true
		$formsignal_vo/Armature/Skeleton/upperLight/Green.visible = true
		$formsignal_vo/Armature/Skeleton/lowerLight/Orange.visible = false
		$formsignal_vo/Armature/Skeleton/upperLight/Orange.visible = false

func orange():
	anim_fsm.travel("Vr0")  # Halt erwarten
	$formsignal_vo/Armature/Skeleton/lowerLight/Orange.visible = true
	$formsignal_vo/Armature/Skeleton/upperLight/Orange.visible = true
	$formsignal_vo/Armature/Skeleton/lowerLight/Green.visible = false
	$formsignal_vo/Armature/Skeleton/upperLight/Green.visible = false
