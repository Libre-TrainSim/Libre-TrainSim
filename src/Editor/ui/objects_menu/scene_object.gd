extends Button

signal favourite_toggled(is_favourite)


var scene: PackedScene = null setget set_scene
var multiselectable := false setget set_multiselectable
var block_hover_select := false


# Why _input, you may be asking...
# It was a quiet night when a lonely programmer wanted to implement
# holding the left mouse button to select any scene object button.
# However, he had to quickly realise _gui_input fires only whenever the left
# mouse button motion press is started in void. There was even a difference
# between the ignore and pass filter settings leading to a frustrated search
# into the depths of the viewports input magic.
# (https://github.com/godotengine/godot/blob/3.5/scene/main/viewport.cpp#L1850)
# Dumbfounded, he randomly wrote bits or more precisely bytes forming words
# and the story he refers as "logic". Let's just trust him and execute "logic".
func _input(event: InputEvent) -> void:
	if block_hover_select || Input.mouse_mode == Input.MOUSE_MODE_CAPTURED || !visible:
		return
	var mm := event as InputEventMouseMotion
	if mm != null and mm.button_mask == BUTTON_LEFT and _mouse_in_bounds() and event.shift:
		pressed = !pressed
		block_hover_select = true
		_free_mouse_on_exit()


func set_scene(value: PackedScene) -> void:
	scene = value
	$Label.text = scene.resource_path.get_file().get_basename()


func set_favourite(is_favourite: bool) -> void:
	$MarkFavourite.pressed = is_favourite


func get_text() -> String:
	return $Label.text


func _on_MarkFavourite_toggled(button_pressed: bool) -> void:
	emit_signal("favourite_toggled", button_pressed)


func set_multiselectable(value: bool) -> void:
	multiselectable = value
	if multiselectable:
		group = null
	else:
		group = preload("res://Editor/ui/objects_menu/object_button_group.tres")


func _mouse_in_bounds() -> bool:
	return Rect2(Vector2(), rect_size).has_point(get_local_mouse_position())


func _free_mouse_on_exit() -> void:
	while _mouse_in_bounds() and block_hover_select:
		yield(get_tree(), "idle_frame")
	block_hover_select = false
