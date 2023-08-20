class_name Person
extends Spatial

export (float) var walking_speed: float = 1.5

var _attached_station: Spatial = null
var _attached_wagon: Spatial = null
var _attached_seat: Spatial = null
var _assigned_door: Spatial = null

enum Destination {
	NONE, # Initial state
	DOOR_OUTSIDE, # Station -> Door
	DOOR_INSIDE, # Seat -> Door
	SEAT, # Door -> Seat
	SEAT_IDLE, # Seat -> Seat
	STATION, # Door -> Station
	STATION_IDLE, # Station -> Station
}

enum Action {
	IDLE,
	WALK,
	SIT
}

var _destination: int = Destination.NONE
var _destination_path := []
const _destination_tolerance := 0.1
var _action: int = Action.IDLE

var _debug_color := Color(randf(), randf(), randf(), 0.75)

func _ready() -> void:
	walking_speed = rand_range(walking_speed, walking_speed+0.3)
	_destination = Destination.STATION_IDLE


func _process(delta: float) -> void:
	_handle_walk(delta)


func _on_world_origin_shifted(delta: Vector3) -> void:
	# Although person is not an World Object,
	# it is still affected by world origin shift when routing outside of the train
	if not _is_destination_train_bound():
		for i in range(_destination_path.size()):
			_destination_path[i] += delta


func _is_destination_reached() -> bool:
	if not _destination_path.empty():
		var current_pos := translation if _is_destination_train_bound() else global_transform.origin
		return current_pos.distance_to(_destination_path[0]) < _destination_tolerance
	return false


func _handle_walk(delta: float) -> void:

	_debug_draw_state()

	# Handle next _destination point if required. if we change _destination type, exit.
	match _destination:
		Destination.NONE:
			assert(false, "Some person has no _destination. Spawn failure?")
			return
		Destination.DOOR_OUTSIDE:
			# We supposed to board the train, but it's gone.
			if _attached_wagon.player.current_station_node != _attached_station:
				_destination = Destination.STATION_IDLE
				return
			# Person is ready to board the train
			if _destination_path.empty() and is_assigned_door_open():
				# If wagon is full, restart boarding
				if not try_board_assigned_wagon():
					if try_board_train():
						return
		Destination.DOOR_INSIDE:
			# Supposed to exit on this station, but train departed already
			if _attached_wagon.player.current_station_node != _attached_station:
				navigate_to_assigned_seat()
				return
			# We reached the door
			if _destination_path.empty():
				# If opened we can transit, overwise idle
				if _attached_wagon.player.whole_train_in_station and is_assigned_door_open():
					if try_leave_current_wagon():
						return
		Destination.STATION:
			# Proceed to next point
			if _destination_path.empty():
				_destination = Destination.STATION_IDLE
				return
		Destination.SEAT:
			if _destination_path.empty():
				_destination = Destination.SEAT_IDLE
		Destination.SEAT_IDLE:
			rotation.y = _attached_seat.rotation.y + (0.5 * PI)
		Destination.STATION_IDLE:
			# Just walk around and wait for the train
			if not _attached_station:
				# Something gone really bad
				assert(false)
				return
			if _destination_path.empty():
				_destination_path.append(_attached_station.get_random_transform_at_platform().origin)

	if _is_destination_reached():
		_destination_path.pop_front()
		return

	if _destination_path.empty():
		match _destination:
			Destination.SEAT_IDLE:
				_action = Action.SIT
			_:
				_action = Action.IDLE
	else:
		_action = Action.WALK

	# TODO: - check if it is too crowdy around and stop even if supposed to walk
	# something like get all collisions (if any other person heading same direction then stop)
	# If there will be problems inside wagons -> limit scope to same destinations only
	# _action = Action.IDLE or return to keep the animations playing
	# adjust walking speed accordingly

	_update_action_animation()

	# No need to move
	if _action != Action.WALK:
		return

	# Move Person if required
	var vector_delta := Vector3.ZERO
	if _is_destination_train_bound():
		translation = translation.move_toward(_destination_path[0], delta*walking_speed)
		vector_delta = _destination_path[0] - translation
	else:
		global_transform.origin = global_transform.origin \
				.move_toward(_destination_path[0], delta*walking_speed)
		vector_delta = _destination_path[0] - global_transform.origin

	# Set rotation torwards destination pos
	if vector_delta.z != 0:
		if vector_delta.z > 0:
			rotation.y = atan(vector_delta.x / vector_delta.z)
		else:
			rotation.y = atan(vector_delta.x / vector_delta.z) + PI

	# Adjust rotation based on WorldObject
	if not _is_destination_train_bound():
		rotation.y = rotation.y - _attached_station.rotation.y

	_debug_draw_path()


func _update_action_animation() -> void:
	match _action:
		Action.SIT:
			_update_visual_animation("Sitting")
		Action.IDLE:
			_update_visual_animation("Standing")
		Action.WALK:
			_update_visual_animation("Walking")


func _update_visual_animation(animation: String) -> void:
	if $VisualInstance/AnimationPlayer.current_animation != animation:
		$VisualInstance/AnimationPlayer.play(animation)


func is_assigned_door_open() -> bool:
	assert(_destination == Destination.DOOR_OUTSIDE or _destination == Destination.DOOR_INSIDE)
	match _assigned_door.side:
		DoorSide.RIGHT:
			return _attached_wagon.door_right.is_opened()
		DoorSide.LEFT:
			return _attached_wagon.door_left.is_opened()
	return false


# Called by train/wagon when arrived to station
func arriving_to_station(current_station: Node) -> void:
	var door_info: Array = _attached_wagon.get_route_from_seat_to_door(_attached_seat)
	if door_info.empty():
		assert(false, "Unable to unboard at the station. Side mismatch?")
		return

	assert(len(door_info) == 2)
	_attached_station = current_station
	_assigned_door = door_info[0]
	_destination_path = door_info[1]
	_destination = Destination.DOOR_INSIDE


func try_board_train() -> bool:
	var door_info: Array = _attached_station.current_train.get_route_to_free_wagon(global_transform.origin)
	if door_info.empty():
		# train do not have free wagons, thats not an issue,
		# as some persons might still unboarding the train so no assert here
		return false
	assert(len(door_info) == 3)

	_attached_wagon = door_info[0]
	_assigned_door = door_info[1]
	_destination_path = door_info[2]
	_destination = Destination.DOOR_OUTSIDE

	return true


func try_board_assigned_wagon() -> bool:
	var seat_info = _attached_wagon.register_person(self, _assigned_door)
	if seat_info.empty():
		return false
	assert(len(seat_info) == 2)
	_attached_station.deregister_person(self)
	_attached_seat = seat_info[0]
	_destination_path = seat_info[1]
	_destination = Destination.SEAT
	return true


# So far we do not expect any fails when leaving the wagon
func try_leave_current_wagon() -> bool:
	# Keep outside door position for proper transition to station
	_destination_path.append(_assigned_door.global_transform.origin)

	# We have to restore position becase we switch from Spatial to World Object
	var old_position := global_transform.origin
	_attached_wagon.deregister_person(self)
	var route_path: Array = _attached_station.register_person(self)
	global_transform.origin = old_position

	assert(len(route_path) > 0)
	_destination_path.append_array(route_path)
	_destination = Destination.STATION
	_attached_seat = null
	_attached_wagon = null
	_assigned_door = null

	return true


func navigate_to_assigned_seat() -> void:
	# We need to get back to seat
	var route: Array = _attached_wagon.get_path_from_to(_assigned_door, _attached_seat)
	# We do not need to go outside, so remove first point, but use it for closest waypoint check
	var distance := translation.distance_to(route.front())
	route.pop_front()
	# we need to find closest route point, and omit all prior to it
	while(translation.distance_to(route.front()) < distance and route.size() > 1):
		distance = translation.distance_to(route.front())
		route.pop_front()
	_destination_path = route
	_destination = Destination.SEAT


func spawn_at_station(station: Spatial) -> void:
	_attached_station = station
	var route_info: Array = _attached_station.register_person(self)
	assert(len(route_info) > 0)
	global_transform.origin = route_info.back()


func despawn() -> void:
	if _attached_station and _attached_station.is_person_registered(self):
		_attached_station.deregister_person(self)
	if _attached_wagon and _attached_wagon.is_person_registered(self):
		_attached_wagon.deregister_person(self)
	queue_free()


func _is_destination_train_bound() -> bool:
	match _destination:
		Destination.SEAT_IDLE, Destination.SEAT, Destination.DOOR_INSIDE:
			return true
	return false


func _debug_draw_path() -> void:
	if !ProjectSettings["game/debug/draw_paths"]:
		return
	var parent := get_parent_spatial()
	var last_position := global_transform.origin
	for position in _destination_path:
		var new_position := parent.to_global(position) \
				if _is_destination_train_bound() \
				else position
		DebugDraw.draw_line_3d(last_position, new_position, _debug_color)
		last_position = new_position

	if _destination == Destination.DOOR_OUTSIDE:
		DebugDraw.draw_box(_assigned_door.global_transform.origin, Vector3(2,2,2), _debug_color)


var _debug_state_label: Label = null
func _debug_draw_state() -> void:
	if !ProjectSettings["game/debug/draw_labels/passenger"]:
		if _debug_state_label:
			_debug_state_label.queue_free()
			_debug_state_label = null
		return
	if _debug_state_label == null:
		_debug_state_label = DebugLabel.new(self, 50, Vector3(0, 1.5, 0))

	if _debug_state_label.is_visible():
		_debug_state_label.set_text( "P:%d\n%s\n%s" % [get_instance_id(), Destination.keys()[_destination], Action.keys()[_action]])
