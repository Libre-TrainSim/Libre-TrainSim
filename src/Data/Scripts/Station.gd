class_name Station
extends RailLogic

var personsNode: Spatial

export (int) var length: int # Length of platform


export (PlatformSide.TypeHint) var platform_side: int = PlatformSide.NONE
export (bool) var personSystem: bool = true
export (float) var platformHeight: float = 1.2
export (float) var platformStart: float = 2.5
export (float) var platformEnd: float = 4.5

export var assigned_signal: String = ""

var waitingPersonCount: int = 5
var _attached_persons: Array = []

# We assume there is only one train at the station as of now
# Spatial for now, but we should switch to LTSTrain at some point
var current_train: Spatial = null


func _get_type() -> String:
	return RailLogicTypes.STATION


func _ready():
	set_to_rail()
	update_operation_mode_of_assigned_signal()

	if not Root.Editor:
		$Mesh.queue_free()
		$SelectCollider.queue_free()
		personSystem = personSystem and ProjectSettings["game/gameplay/enable_persons"] and not Root.mobile_version

	if Root.Editor or not personSystem or not is_instance_valid(rail):
		set_process(false)

	if personSystem:
		personsNode = Spatial.new()
		add_child(personsNode)
		personsNode.owner = self


func _on_world_origin_shifted(shift: Vector3) -> void:
	._on_world_origin_shifted(shift)
	for person in _attached_persons:
		person._on_world_origin_shifted(shift)


func _process(_delta: float) -> void:
	handle_persons()
	_debug_passenger_state()
	pass


func spawn_persons_at_beginning() -> void:
	if not personSystem:
		return
	if platform_side == PlatformSide.NONE:
		return
	while(rail.visible and _attached_persons.size() < waitingPersonCount):
		spawn_random_person()


func set_waiting_persons(count: int) -> void:
	waitingPersonCount = count
	spawn_persons_at_beginning()


func handle_persons() -> void:
	if platform_side == PlatformSide.NONE:
		return
	assert(rail != null)

	if rail.visible and _attached_persons.size() < waitingPersonCount:
		spawn_random_person()
	elif not rail.visible:
		for person in _attached_persons:
			person.despawn()


func spawn_random_person() -> void:
	var person: Person = world.get_new_person_instance()
	person.spawn_at_station(self)


func get_random_transform_at_platform() -> Transform:
	if forward:
		var randRailDistance = int(rand_range(on_rail_position, on_rail_position+length))
		if platform_side == PlatformSide.LEFT:
			return Transform(Basis( \
					Vector3(0, rail.get_rad_at_distance(randRailDistance), 0)), \
					rail.get_shifted_global_pos_at_distance( \
					randRailDistance, rand_range(-platformStart, -platformEnd)) \
					+ Vector3(0, platformHeight, 0))
		if platform_side == PlatformSide.RIGHT:
			return Transform(Basis(Vector3(0, \
					rail.get_rad_at_distance(randRailDistance)+PI, 0)), \
					rail.get_shifted_global_pos_at_distance( \
					randRailDistance, rand_range(platformStart, platformEnd)) \
					+ Vector3(0, platformHeight, 0))
	else:
		var randRailDistance = int(rand_range(on_rail_position, on_rail_position-length))
		if platform_side == PlatformSide.LEFT:
			return Transform(Basis(Vector3(0, \
					rail.get_rad_at_distance(randRailDistance)+PI, 0)), \
					rail.get_shifted_global_pos_at_distance(randRailDistance, \
					rand_range(platformStart, platformEnd)) + Vector3(0, platformHeight, 0))
		if platform_side == PlatformSide.RIGHT:
			return Transform(Basis(Vector3(0, \
					rail.get_rad_at_distance(randRailDistance), 0)), \
					rail.get_shifted_global_pos_at_distance(randRailDistance, \
					rand_range(-platformStart, -platformEnd)) + Vector3(0, platformHeight, 0))
	Logger.warn("Unsupported platform type %s" % platform_side, self)
	#assert(false) # Unsupported platform type. I don't wanna fix here
	return global_transform


func train_arrived(train: Spatial) -> void:
	current_train = train

	# TODO: not all passengers should board train when person will have destination
	# Notify waiting passangers on arrived train
	for person in _attached_persons:
		person.try_board_train()


func train_departured(_train: Spatial) -> void:
	current_train = null


func is_person_registered(person: Spatial) -> bool:
	return _attached_persons.has(person)


func deregister_person(personToDelete: Spatial) -> void:
	assert(_attached_persons.has(personToDelete), "Trying to deregister unknown Person")
	_attached_persons.erase(personToDelete)
	# Reduce waiting person count to prevent spawning new persons
	waitingPersonCount -= 1


# return route path for the person
func register_person(personNode: Spatial) -> Array:
	_attached_persons.append(personNode)
	personNode.get_parent().remove_child(personNode)
	personsNode.add_child(personNode)
	personNode.owner = self
	return [get_random_transform_at_platform().origin]


func update_operation_mode_of_assigned_signal():
	var signal_node: Node = world.get_signal(assigned_signal)
	if signal_node == null:
		return
	signal_node.operation_mode = SignalOperationMode.STATION


func get_perfect_halt_distance_on_rail(train_length: int):
	if forward:
		return on_rail_position + (length - (length-train_length)/2.0)
	else:
		return on_rail_position - (length - (length-train_length)/2.0)


func set_data(d: StationSettings) -> void:
	if not d.overwrite:
		return
	assigned_signal = d.assigned_signal_name
	personSystem = d.enable_person_system


var _debug_passenger_state_label: Label = null
func _debug_passenger_state() -> void:
	if !ProjectSettings["game/debug/draw_labels/station"] or !personSystem:
		if _debug_passenger_state_label:
			_debug_passenger_state_label.queue_free()
			_debug_passenger_state_label = null
		return
	if not _debug_passenger_state_label:
		_debug_passenger_state_label = DebugLabel.new(self, 100, Vector3(0, 6, 0))

	if _debug_passenger_state_label.is_visible():
		_debug_passenger_state_label.set_text( "S:%s\nPassenger: %d" % [name, _attached_persons.size()])
