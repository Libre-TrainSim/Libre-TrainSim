extends Spatial

export (float) var walkingSpeed: float = 1.5

var attachedStation: Spatial = null
var attachedWagon: Spatial = null
var attachedSeat: Spatial = null
var assignedDoor: Spatial = null
var destinationIsSeat: bool = false

var transitionToWagon: bool = false
var transitionToStation: bool = false

var status: int = 0
#0 Walking To Position
#1: Sitting

var destinationPos := []

var stopping: bool = false # Used, if for example doors where closed to early

var debug_color := Color(randf(), randf(), randf(), 0.75)

func _ready() -> void:
	walkingSpeed = rand_range(walkingSpeed, walkingSpeed+0.3)


func _process(delta: float) -> void:
	handleWalk(delta)


var leave_wagon_timer: float = 0
func handleWalk(delta: float) -> void:
	# If Doors where closed to early, and the person is at the station..
	if transitionToWagon == true and not (attachedWagon.lastDoorRight or attachedWagon.lastDoorLeft):
		if attachedWagon.player.current_station_node != attachedStation:
			transitionToWagon = false
			destinationPos.clear()
		else:
			stopping = true
			if $VisualInstance/AnimationPlayer.current_animation != "Standing":
				$VisualInstance/AnimationPlayer.play("Standing")
	else:
		stopping = false

	if destinationPos.size() == 0:
		if transitionToWagon:
			attachedStation.deregisterPerson(self)
			attachedStation = null
			transitionToWagon = false
			attachedWagon.registerPerson(self, assignedDoor)
			assignedDoor = null
		if transitionToStation and attachedWagon.player.whole_train_in_station \
				and (attachedWagon.lastDoorRight or attachedWagon.lastDoorLeft):
			leave_wagon_timer += delta
			if leave_wagon_timer > 1.8:
				leave_wagon_timer = 0
				transitionToStation = false
				leave_current_wagon()
		if destinationIsSeat and attachedSeat != null and \
				translation.distance_to(attachedSeat.translation) < 0.1:
			destinationIsSeat = false
			rotation_degrees.y = attachedSeat.rotation_degrees.y + 90

			## Animation Sitting
			$VisualInstance/AnimationPlayer.play("Sitting")
		elif !$VisualInstance/AnimationPlayer.is_playing() and attachedSeat == null:
			$VisualInstance/AnimationPlayer.play("Standing")

		return

	if !$VisualInstance/AnimationPlayer.is_playing():
		$VisualInstance/AnimationPlayer.play("Walking")


	if transitionToStation or destinationIsSeat:
		if translation.distance_to(destinationPos[0]) < 0.1:
			destinationPos.pop_front()
			return
	elif global_transform.origin.distance_to(destinationPos[0]) < 0.1:
		destinationPos.pop_front()
		return

	if stopping:
		return

	var vector_delta := Vector3.ZERO

	if transitionToStation or destinationIsSeat:
		translation = translation.move_toward(destinationPos[0], delta*walkingSpeed)
		vector_delta = destinationPos[0] - translation
	else:
		global_transform.origin = global_transform.origin \
				.move_toward(destinationPos[0], delta*walkingSpeed)
		vector_delta = destinationPos[0] - global_transform.origin

	_debug_draw_path()
	if vector_delta.z != 0:
		if vector_delta.z > 0:
			rotation_degrees.y = rad2deg(atan(vector_delta.x/vector_delta.z))
		else:
			rotation_degrees.y = rad2deg(atan(vector_delta.x/vector_delta.z))+180


func leave_current_wagon()-> void:
	destinationPos.append(assignedDoor.global_transform.origin)
	var old_position := global_transform.origin
	attachedWagon.deregisterPerson(self)
	attachedStation.registerPerson(self)
	global_transform.origin = old_position
	transitionToStation = false
	attachedWagon = null
	assignedDoor = null


func deSpawn() -> void:
	if attachedStation:
		attachedStation.deregisterPerson(self)
	if attachedWagon:
		attachedWagon.deregisterPerson(self)
	queue_free()


func clear_destinations() -> void:
	destinationPos.clear()


func _debug_draw_path() -> void:
	if !ProjectSettings["game/debug/draw_paths"]:
		return
	var parent := get_parent_spatial()
	var last_position := global_transform.origin
	for position in destinationPos:
		var new_position := parent.to_global(position) \
				if transitionToStation or destinationIsSeat \
				else position
		DebugDraw.draw_line_3d(last_position, new_position, debug_color)
		last_position = new_position
