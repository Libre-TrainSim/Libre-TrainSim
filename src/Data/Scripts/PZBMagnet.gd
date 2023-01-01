class_name PZBMagnet
extends RailLogic


func _get_type() -> String:
	return RailLogicTypes.PZB_MAGNET


enum Hz {
	Hz500 = 500,
	Hz1000 = 1000,
	Hz2000 = 2000
}
export(Hz) var hz: int


export(NodePath) var attached_signal: NodePath setget set_attached_signal
var attached_signal_node: Spatial
func set_attached_signal(val: NodePath) -> void:
	attached_signal = val
	attached_signal_node = get_node(val)


var is_active: bool = false


func _ready() -> void:
	if attached_signal_node == null:
		attached_signal_node = get_node(attached_signal)
		#print(name, ": Attached to: ", attached_signal_node.name)
		if attached_signal_node == null:
			print(name, ": CAN'T FIND ATTACHED SIGNAL NODE! (", attached_signal,")")
			#queue_free()
			return

	var _unused = attached_signal_node.connect("signal_changed", self, "update_active")

	set_to_rail()
	update_active(attached_signal_node)


func update_active(_signal_instance: Spatial) -> void:
	#print(name, ": Updating is_active!")
	# handle combined magnets (yes, they exist, at Ks signals)
	if attached_signal_node.signal_type == attached_signal_node.SignalType.COMBINED:
		if attached_signal_node.status == SignalStatus.RED:
			hz = 2000
		else:
			hz = 1000

	# handle activation
	if hz == 500 or hz == 2000:
		is_active = (attached_signal_node.status == SignalStatus.RED)
	elif hz == 1000:
		is_active = (attached_signal_node.status == SignalStatus.ORANGE) or (attached_signal_node.warn_speed > 0 and attached_signal_node.warn_speed < Math.kmh_to_speed(80))
		# TODO: special case: warn_speed 80 or 90 still need Ack, but limit to different speeds
		# warn speeds 100 and above are NOT checked and don't require PZB Ack
