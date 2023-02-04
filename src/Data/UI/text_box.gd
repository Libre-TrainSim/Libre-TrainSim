class_name TextBox
extends PanelContainer

signal closed


var _previous_mouse_mode: int
var opened := false

func _unhandled_key_input(_event) -> void:
	if Input.is_action_just_released("ui_accept"):
		_on_Ok_pressed()


func message(text: String) -> void:
	_previous_mouse_mode = Input.get_mouse_mode()
	assert(_previous_mouse_mode != null)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$MarginContainer/VBoxContainer/Message.text = text
	visible = true
	get_tree().paused = true
	opened = true
	$MarginContainer/VBoxContainer/Ok.grab_click_focus()


func _on_Ok_pressed():
	visible = false
	get_tree().paused = false
	opened = false
	Input.set_mouse_mode(_previous_mouse_mode)
	emit_signal("closed")
