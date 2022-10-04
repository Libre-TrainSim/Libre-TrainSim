extends Spatial


var x_active := false
var y_active := false
var z_active := false
var x_rot_active := false

var x_hovered := false
var y_hovered := false
var z_hovered := false
var x_rot_hovered := false

var mouse_position_before_capture := Vector2(0,0)

var mouseMotion := Vector2(0,0)

func _input(event):
	if event is InputEventMouseMotion:
		mouseMotion += event.relative * (-1 if z_active else 1)

	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			# Reset mouse motion
			mouseMotion = Vector2(0,0)

			# Ensure only one axis is active at a time
			if x_hovered:
				x_active = true
			elif y_hovered:
				y_active = true
			elif z_hovered:
				z_active = true
			elif x_rot_hovered:
				x_rot_active = true

			# Capture mouse
			if any_axis_active():
				mouse_position_before_capture = get_viewport().get_mouse_position()
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		elif any_axis_active():
			# Deactivate all axes
			x_active = false
			y_active = false
			z_active = false
			x_rot_active = false

			# Release mouse
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_viewport().warp_mouse(mouse_position_before_capture)


func _process(_delta):
	rotation.y = - get_parent().rotation.y

	if Input.is_mouse_button_pressed(BUTTON_LEFT) and any_axis_active():
		if x_active:
			get_parent().translation.x += mouseMotion.x * 0.01
		if y_active:
			get_parent().translation.y -= mouseMotion.y * 0.01
		if z_active:
			get_parent().translation.z += mouseMotion.x * 0.01

		if x_rot_active:
			get_parent().rotation.y += mouseMotion.x * 0.1 * deg2rad(1)

		mouseMotion = Vector2(0,0)


func any_axis_active() -> bool:
	return x_active or y_active or z_active or x_rot_active


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
