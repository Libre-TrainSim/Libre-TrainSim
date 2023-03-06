class_name TextBox
extends PanelContainer

signal closed


var _previous_mouse_mode: int


func message(text: String) -> void:
	_previous_mouse_mode = Input.get_mouse_mode()
	assert(_previous_mouse_mode != null)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$MarginContainer/VBoxContainer/Message.set_text(text)
	visible = true
	Root.set_game_pause("message", true)
	$MarginContainer/VBoxContainer/Ok.grab_focus()
	$MarginContainer/VBoxContainer/Ok.grab_click_focus()


func _on_Ok_pressed():
	visible = false
	Root.set_game_pause("message", false)
	Input.set_mouse_mode(_previous_mouse_mode)
	emit_signal("closed")


func _on_unpaused():
	if visible:
		$MarginContainer/VBoxContainer/Ok.grab_focus()
