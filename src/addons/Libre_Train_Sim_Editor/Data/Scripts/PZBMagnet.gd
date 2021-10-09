tool
extends Spatial

const type = "PZBMagnet"

enum Hz {
	Hz500 = 500,
	Hz1000 = 1000,
	Hz2000 = 2000
}
export(Hz) var hz
export(int) var on_rail_position = 0
export(bool) var forward = true

export(NodePath) var attached_rail setget set_attached_rail
var attached_rail_node
func set_attached_rail(val):
	attached_rail = val
	attached_rail_node = self.get_node(val)

export(NodePath) var attached_signal setget set_attached_signal
var attached_signal_node
func set_attached_signal(val):
	attached_signal = val
	attached_signal_node = self.get_node(val)

var is_active = false

func _ready():
	if attached_signal_node == null:
		attached_signal_node = get_node(attached_signal)
		#print(name, ": Attached to: ", attached_signal_node.name)
		if attached_signal_node == null:
			print(name, ": CAN'T FIND ATTACHED SIGNAL NODE! (", attached_signal,")")
			#queue_free()
			return
	
	attached_signal_node.connect("signal_changed", self, "update_active")
	
	set_to_rail(true)
	update_active(true)

func update_active(_signal_instance):
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
		is_active = (attached_signal_node.status == SignalStatus.ORANGE) or (attached_signal_node.warn_speed > 0 and attached_signal_node.warn_speed < Math.kmHToSpeed(80))
		# TODO: special case: warn_speed 80 or 90 still need Ack, but limit to different speeds
		# warn speeds 100 and above are NOT checked and don't require PZB Ack

func set_to_rail(newvar):
	if attached_rail_node == null:
		attached_rail_node = get_node(attached_rail)
		if attached_rail_node == null:
			print(name, ": CAN'T FIND ATTACHED RAIL NODE! (", attached_rail, ")")
			#queue_free()
			return

	attached_rail_node.register_signal(self.name, on_rail_position)
	self.translation = attached_rail_node.get_pos_at_RailDistance(on_rail_position)
	self.rotation_degrees.y = attached_rail_node.get_deg_at_RailDistance(on_rail_position)
	if not forward:
		self.rotation_degrees.y += 180
