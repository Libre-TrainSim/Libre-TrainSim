extends Spatial

onready var signal_logic = get_parent()
onready var world = find_parent("World")
onready var anim_fsm = $AnimationTree.get("parameters/playback")

func _ready():
	# force the signal to be a main signal
	signal_logic.signal_type = signal_logic.SignalType.MAIN
	update_visual_instance(signal_logic)

# this is a MAIN signal, it CANNOT be orange!
func update_visual_instance(instance):
	match instance.status:
		SignalStatus.RED: red()
		SignalStatus.GREEN: green()

func green():
	if signal_logic.speed > 0 and signal_logic.speed <= 60:
		anim_fsm.travel("Hp2") # Langsamfahrt
		$formsignal_hp/Armature/Skeleton/upperLightAttachment/Red.visible = false
		$formsignal_hp/Armature/Skeleton/upperLightAttachment/Green.visible = true
		$formsignal_hp/Armature/Skeleton/lowerLightAttachment/Orange.visible = true
	else:
		anim_fsm.travel("Hp1") # Fahrt
		$formsignal_hp/Armature/Skeleton/upperLightAttachment/Green.visible = true
		$formsignal_hp/Armature/Skeleton/upperLightAttachment/Red.visible = false
		$formsignal_hp/Armature/Skeleton/lowerLightAttachment/Orange.visible = false

func red():
	anim_fsm.travel("Hp0") # Halt
	$formsignal_hp/Armature/Skeleton/upperLightAttachment/Red.visible = true
	$formsignal_hp/Armature/Skeleton/upperLightAttachment/Green.visible = false
	$formsignal_hp/Armature/Skeleton/lowerLightAttachment/Orange.visible = false
