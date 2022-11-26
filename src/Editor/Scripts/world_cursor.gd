class_name WorldCursor
extends Spatial


func _unhandled_input(_event: InputEvent) -> void:
	update_position()


func update_position() -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var plane := Plane.PLANE_XZ
	var camera := get_viewport().get_camera()
	var new_position := plane.intersects_ray(camera.project_ray_origin(mouse_pos), \
			camera.project_ray_normal(mouse_pos))
	if new_position != null:
		translation = new_position
