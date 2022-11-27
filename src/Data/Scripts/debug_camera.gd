class_name DebugCamera
extends CameraBase


var follow_target: Spatial = null


export var mouse_sensitivity: float = 0.003
export var normal_speed: float = 1
export var fast_speed: float = 3
export var pan_move_sensitivity: float = 0.25
export var control_path: NodePath


var velocity := Vector3.ZERO
var is_moving_first_person := false
var is_panning := false
var in_movement_time: float = 0
var focus_owner: Control = null
var significantly_moved := false
var start_rotation := Quat()


func load_from_transform(new_transform: Transform) -> void:
	transform = new_transform
	rot = Vector2(rotation.y, rotation.x)


# TODO: F to focus on selected object
# TODO: Fix Pan speed depending on distance to ground or zoom
#	needs object picking
func _unhandled_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null and is_moving_first_person:
		_rotate_local(mm.relative * mouse_sensitivity)
		if !significantly_moved and start_rotation.angle_to(transform.basis.get_rotation_quat()) > 0.01:
			significantly_moved = true
			emit_signal("first_person_was_moved")
	elif mm != null and is_panning:
#		if get_parent() == orbit_rotation_helper and (mm.shift || mm.alt || mm.control):
#			_remove_orbit()
		if mm.alt:
			_pan_local(mm.relative * pan_move_sensitivity)
		elif mm.shift:
			_pan_global(mm.relative * pan_move_sensitivity)
		elif mm.control:
			_zoom(-mm.relative.y * pan_move_sensitivity)
		else:
			_rotate_orbit(mm.relative * mouse_sensitivity)

	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == BUTTON_RIGHT:
		if mb.pressed and !is_moving_first_person:
			_capture_mouse()
			significantly_moved = false
			start_rotation = transform.basis.get_rotation_quat()
			emit_signal("first_person_movement_started")
		elif !mb.pressed and is_moving_first_person:
			_free_mouse()
			velocity = Vector3()
		is_moving_first_person = mb.pressed
	elif mb != null and mb.button_index == BUTTON_MIDDLE:
		if mb.pressed and !is_panning:
			_capture_mouse()
#			if mb.shift and get_parent() != orbit_rotation_helper:
#				_prepare_orbit()
		elif !mb.pressed and is_panning:
			_free_mouse()
#			if get_parent() == orbit_rotation_helper:
#				_remove_orbit()
		is_panning = mb.pressed
	elif mb != null and mb.button_index == BUTTON_WHEEL_DOWN and _no_modifier(mb):
		_zoom(10 * max(mb.factor, 1))
	elif mb != null and mb.button_index == BUTTON_WHEEL_UP and _no_modifier(mb):
		_zoom(-10 * max(mb.factor, 1))


func _physics_process(delta: float) -> void:
	_update_base_position()
	if !is_moving_first_person:
		in_movement_time = 0
		return
	Logger.warn("Hello from editor cam", self)
	var direction = Vector3(\
		Input.get_action_strength("right") - Input.get_action_strength("left"), \
		Input.get_action_strength("up") - Input.get_action_strength("down"), \
		Input.get_action_strength("backward") - Input.get_action_strength("forward")\
		).normalized()
	in_movement_time += delta
	direction *= fast_speed if Input.is_action_pressed("shift") else normal_speed
	direction *= max(1, in_movement_time / 3)
	direction = lerp(velocity, direction, 0.3)
	velocity = direction
	if !significantly_moved and direction.length_squared() > 0.01:
		significantly_moved = true
		emit_signal("first_person_was_moved")
	translate_object_local(direction)


func _exit_tree() -> void:
	pass
#	if is_instance_valid(orbit_rotation_helper):
#		orbit_rotation_helper.queue_free()


func _capture_mouse() -> void:
	._capture_mouse()


func _free_mouse() -> void:
	._free_mouse()


func _no_modifier(ev: InputEventWithModifiers) -> bool:
	return !ev.shift and !ev.alt and !ev.control and !ev.command and !ev.meta


func _update_base_position() -> void:
	if !is_instance_valid(follow_target):
		return
	if get_parent() != orbit_rotation_helper:
		_prepare_orbit()
	orbit_rotation_helper.global_transform.origin = follow_target.global_transform.origin
