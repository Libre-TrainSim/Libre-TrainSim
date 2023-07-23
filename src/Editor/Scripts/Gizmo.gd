extends Spatial


export var x_axis_color: Color
export var y_axis_color: Color
export var z_axis_color: Color
export var x_axis_color_hover: Color
export var y_axis_color_hover: Color
export var z_axis_color_hover: Color

var x_active := false
var y_active := false
var z_active := false
var x_rot_active := false
var y_rot_active := false
var z_rot_active := false

var x_hovered := false
var y_hovered := false
var z_hovered := false
var x_rot_hovered := false
var y_rot_hovered := false
var z_rot_hovered := false

var start_position: Vector3
var grab_position: Vector3

func _unhandled_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null and (x_active or y_active or z_active):
		
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
	
	elif mm != null and (x_rot_active or y_rot_active or z_rot_active):
		
		# The player rotates the object by circeling his mouse pointer around the gizmo
		
		var camera := get_viewport().get_camera()
		
		var axis := \
			Vector3(1, 0, 0) if x_rot_active else \
			Vector3(0, 1, 0) if y_rot_active else \
			Vector3(0, 0, 1)
		
		var plane := Plane(axis, get_parent().translation.dot(axis))
		
		var ray_old_mouse_position := camera.project_ray_normal(mm.position - event.relative)
		var ray_new_mouse_position := camera.project_ray_normal(mm.position)
		
		var intersection_old := plane.intersects_ray(camera.translation, ray_old_mouse_position)
		var intersection_new := plane.intersects_ray(camera.translation, ray_new_mouse_position)
		
		# Do nothing when the mouse pointer doesn't hover over the plane
		if intersection_old != null and intersection_new != null:
			var diff: float = (intersection_old - get_parent().translation).signed_angle_to(intersection_new - get_parent().translation, axis)
			get_parent().rotate(axis, diff)

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
			elif y_rot_hovered:
				y_rot_active = true
			elif z_rot_hovered:
				z_rot_active = true
		
		elif any_axis_active():
			# Deactivate all axes
			x_active = false
			y_active = false
			z_active = false
			x_rot_active = false
			y_rot_active = false
			z_rot_active = false
			
			$"x-axis/MeshInstance".get_surface_material(0).emission  = x_axis_color
			$"y-axis/MeshInstance".get_surface_material(0).emission = y_axis_color
			$"z-axis/MeshInstance".get_surface_material(0).emission = z_axis_color
			$"x-rot/MeshInstance".get_surface_material(0).emission  = x_axis_color
			$"y-rot/MeshInstance".get_surface_material(0).emission = y_axis_color
			$"z-rot/MeshInstance".get_surface_material(0).emission = z_axis_color


func _process(delta: float) -> void:
	# Keep the gizmo unrotated while his parent rotates
	global_rotation = Vector3(0, 0, 0)
	# Make the gizmo always have the same size on screen
	scale = Vector3(0.005, 0.005, 0.005) * (get_viewport().get_camera().global_translation - global_translation).length()


func any_axis_active() -> bool:
	return x_active or y_active or z_active or x_rot_active or y_rot_active or z_rot_active


func _on_xaxis_mouse_entered() -> void:
	x_hovered = true
	if not any_axis_active():
		$"x-axis/MeshInstance".get_surface_material(0).emission = x_axis_color_hover

func _on_xaxis_mouse_exited() -> void:
	x_hovered = false
	if not x_active:
		$"x-axis/MeshInstance".get_surface_material(0).emission = x_axis_color


func _on_yaxis_mouse_entered() -> void:
	y_hovered = true
	if not any_axis_active():
		$"y-axis/MeshInstance".get_surface_material(0).emission = y_axis_color_hover

func _on_yaxis_mouse_exited() -> void:
	y_hovered = false
	if not y_active:
		$"y-axis/MeshInstance".get_surface_material(0).emission = y_axis_color


func _on_zaxis_mouse_entered() -> void:
	z_hovered = true
	if not any_axis_active():
		$"z-axis/MeshInstance".get_surface_material(0).emission = z_axis_color_hover

func _on_zaxis_mouse_exited() -> void:
	z_hovered = false
	if not z_active:
		$"z-axis/MeshInstance".get_surface_material(0).emission = z_axis_color


func _on_xrot_mouse_entered() -> void:
	x_rot_hovered = true
	if not any_axis_active():
		$"x-rot/MeshInstance".get_surface_material(0).emission = x_axis_color_hover

func _on_xrot_mouse_exited() -> void:
	x_rot_hovered = false
	if not x_rot_active:
		$"x-rot/MeshInstance".get_surface_material(0).emission = x_axis_color


func _on_yrot_mouse_entered() -> void:
	y_rot_hovered = true
	if not any_axis_active():
		$"y-rot/MeshInstance".get_surface_material(0).emission = y_axis_color_hover

func _on_yrot_mouse_exited() -> void:
	y_rot_hovered = false
	if not y_rot_active:
		$"y-rot/MeshInstance".get_surface_material(0).emission = y_axis_color


func _on_zrot_mouse_entered() -> void:
	z_rot_hovered = true
	if not any_axis_active():
		$"z-rot/MeshInstance".get_surface_material(0).emission = z_axis_color_hover

func _on_zrot_mouse_exited() -> void:
	z_rot_hovered = false
	if not z_rot_active:
		$"z-rot/MeshInstance".get_surface_material(0).emission = z_axis_color


func _on_axis_input_event(_camera: Node, _event: InputEvent, position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not any_axis_active():
		grab_position = position

