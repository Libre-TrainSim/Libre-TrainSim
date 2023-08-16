## Debug labels to output debug information on top of objects
class_name DebugLabel
extends Label

var _visibility_threshold: float
var _mount_point: Spatial
var _mount_offset: Vector3

func _init(mount_point: Spatial, visibility_threshold: float = 50.0, offset: Vector3 = Vector3(0,0,0)):
	assert(visibility_threshold > 0, "Visibility Threshold should be positive")
	_visibility_threshold = visibility_threshold
	_mount_point = mount_point
	_mount_offset = offset
	mount_point.add_child(self)


func _debug_get_camera():
	return Root.get_viewport().get_camera()


func is_visible() -> bool:
	var camera = _debug_get_camera()
	var test_point:Vector3 = _mount_point.global_transform.origin + _mount_offset

	if not camera.is_position_behind(test_point):
		if test_point.distance_to(camera.global_transform.origin) < _visibility_threshold:
			var cam_pos = camera.translation
			var x_offset = Vector2(get_size().x/2, 0)
			rect_position = camera.unproject_position(test_point) - x_offset
			visible = true
		else:
			visible = false
	else:
		visible = false
	return visible
