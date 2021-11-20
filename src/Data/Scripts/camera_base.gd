class_name CameraBase
extends Camera


var rot: Vector2 = Vector2.ZERO # is in screen coordinates
var capture_mouse_position: Vector2 = Vector2.ZERO

var zoom_level: float = 80
var orbit_rotation_helper: Spatial = Spatial.new()


func _ready() -> void:
	Root.connect("world_origin_shifted", self, "_on_world_origin_shifted")


func _on_world_origin_shifted(delta: Vector3):
	translation += delta


func _prepare_orbit() -> void:
	assert(get_parent() != orbit_rotation_helper)
	get_parent().add_child(orbit_rotation_helper)
	var target_point := Plane.PLANE_XZ.intersects_ray(\
			global_transform.origin, project_ray_normal(get_viewport().size/2))
	if target_point == null:
		# Set point with zoom_level distance in direction of camera
		target_point = project_position(get_viewport().size/2, zoom_level)
	var old_transform = global_transform
	get_parent().remove_child(self)
	orbit_rotation_helper.global_transform.origin = target_point
	orbit_rotation_helper.global_transform.basis = old_transform.basis
	orbit_rotation_helper.add_child(self)
	global_transform = old_transform


func _remove_orbit() -> void:
	assert(get_parent() == orbit_rotation_helper)
	var old_transform = global_transform
	orbit_rotation_helper.remove_child(self)
	orbit_rotation_helper.get_parent().add_child(self)
	get_parent().remove_child(orbit_rotation_helper)
	global_transform = old_transform


func _zoom(offset: float) -> void:
	var prev_zoom_level := zoom_level
	zoom_level = clamp(zoom_level - offset, 0.2, 250)
	translate(Vector3(0,0, prev_zoom_level - zoom_level))


func _rotate_local(offset: Vector2) -> void:
	rot -= offset
	# Prevent the world being upside down
	rot.y = clamp(rot.y, -0.5*PI, 0.5*PI)
	transform.basis = Basis()
	rotate_object_local(Vector3.UP, rot.x)
	rotate_object_local(Vector3.RIGHT, rot.y)


func _rotate_orbit(offset: Vector2) -> void:
		if get_parent() != orbit_rotation_helper:
			_prepare_orbit()
		rot -= offset
		# Prevent the world being upside down
		rot.y = clamp(rot.y, -0.5*PI, 0.5*PI)
		orbit_rotation_helper.transform.basis = Basis()
		orbit_rotation_helper.rotate_object_local(Vector3.UP, rot.x)
		orbit_rotation_helper.rotate_object_local(Vector3.RIGHT, rot.y)


func _pan_local(offset: Vector2) -> void:
	translate(Vector3(-offset.x, offset.y, 0))


func _pan_global(offset: Vector2) -> void:
	transform.basis = Basis()
	rotate_object_local(Vector3.UP, rot.x)
	translate(Vector3(-offset.x, 0, \
		-offset.y))
	rotate_object_local(Vector3.RIGHT, rot.y)


func _capture_mouse() -> void:
	capture_mouse_position = get_viewport().get_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _free_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_viewport().warp_mouse(capture_mouse_position)
