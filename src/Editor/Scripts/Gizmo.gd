extends Spatial


var x_active := false
var y_active := false
var z_active := false
var x_rot_active := false

var x_hovered := false
var y_hovered := false
var z_hovered := false
var x_rot_hovered := false

var start_position: Vector3
var grab_position: Vector3

func _unhandled_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null and any_movement_axis_active():
		
		# The difference to the start position is calculated by using the law of sines
		# on the triangle between the origin of the camera, the position where the gizmo is grabbed
		# and the position where the grabbed point is moved to
		
		var direction := Vector3(x_active, y_active, z_active)
		
		var camera := get_viewport().get_camera()
		
		var grab_position_on_screen := camera.unproject_position(grab_position)
		var direction_on_screen := (camera.unproject_position(grab_position + direction) - grab_position_on_screen).normalized()
		
		# If the axis is dragged in the negative direction
		if (mm.position - grab_position_on_screen).dot(direction_on_screen) < 0:
			direction *= -1
		
		# The object has to be moved to the perpendicular of the mouse position on the axis on screen
		# We calculate this point:
		var perpendicular_screen_point := (mm.position - grab_position_on_screen).dot(direction_on_screen) * direction_on_screen + grab_position_on_screen;
		
		var cam_to_grab_position := grab_position - camera.global_transform.origin
		var cam_to_new_position := camera.project_ray_normal(perpendicular_screen_point)
		
		# The angle at the camera between the vectors to the grab position and the new position
		var angle_grab_cam_new := cam_to_grab_position.angle_to(cam_to_new_position)
		# The angle at the object between the vectors to the camera and the new position
		var angle_cam_object_new := PI - cam_to_grab_position.angle_to(direction)
		
		# Limit if the moused is moved beyond the limits of the axis
		if angle_grab_cam_new + angle_cam_object_new >= PI:
			angle_grab_cam_new = PI - angle_cam_object_new - 0.01
		
		# We get the diff with the law of sines
		var diff := cam_to_grab_position.length() \
			/ sin(PI - angle_grab_cam_new - angle_cam_object_new) \
			* sin(angle_grab_cam_new)
		
		get_parent().translation = start_position + diff * direction
	
	elif mm != null and x_rot_active:
		get_parent().rotation.y += event.relative.x * 0.1 * deg2rad(1)
		rotation.y = - get_parent().rotation.y

	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			start_position = get_parent().global_transform.origin
			
			# Ensure only one axis is active at a time
			if x_hovered:
				x_active = true
			elif y_hovered:
				y_active = true
			elif z_hovered:
				z_active = true
			elif x_rot_hovered:
				x_rot_active = true
		
		elif any_movement_axis_active() or x_rot_active:
			# Deactivate all axes
			x_active = false
			y_active = false
			z_active = false
			x_rot_active = false


func any_movement_axis_active() -> bool:
	return x_active or y_active or z_active


func _on_xaxis_mouse_entered() -> void:
	x_hovered = true

func _on_xaxis_mouse_exited() -> void:
	x_hovered = false


func _on_yaxis_mouse_entered() -> void:
	y_hovered = true

func _on_yaxis_mouse_exited() -> void:
	y_hovered = false


func _on_zaxis_mouse_entered() -> void:
	z_hovered = true

func _on_zaxis_mouse_exited() -> void:
	z_hovered = false


func _on_x_rot_mouse_entered() -> void:
	x_rot_hovered = true

func _on_x_rot_mouse_exited() -> void:
	x_rot_hovered = false


func _on_axis_input_event(_camera: Node, _event: InputEvent, position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not any_movement_axis_active():
		grab_position = position

