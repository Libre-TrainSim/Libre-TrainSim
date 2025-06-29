extends VBoxContainer


signal header_pressed(group_name, focus_target)


var object_group: ObjectGroup = null
var using_multiselect := false


func deselect_all() -> void:
	_on_select_all(false)


func filter(regex: RegEx, favourites: Dictionary,
		common: Dictionary, recent: Array) -> void:
	if regex == null:
		hide()
		deselect_all()
		return
	var visible_count := 0
	for object in get_objects():
		object.visible = regex.search(object.get_text()) and \
				(favourites.is_empty() and common.is_empty() and recent.is_empty()) \
				or object.scene in favourites \
				or object.scene in common \
				or object.scene in recent
		if !object.visible and object.pressed:
			object.multiselectable = true
			object.button_pressed = false
		visible_count += 1 if object.visible else 0
	visible = visible_count != 0


func get_objects() -> Array:
	return $Objects.get_children()


func set_header_mode(value: bool) -> void:
	$Objects.visible = !value


func set_objects(value: ObjectGroup, toggle_target: Object, toggle_target_name: String, \
		favourite_toggle_name: String, favourites: Dictionary) -> void:
	object_group = value
	$Header/Description.text = object_group.group_name
	var objects := $Objects
	for scene in object_group.scenes:
		var object := preload("res://Editor/ui/objects_menu/object.tscn").instantiate() as Button
		object.scene = scene
		object.multiselectable = false
		object.set_favourite(scene in favourites)
		if object_group.thumbnails.has(scene.resource_path):
			object.icon = scene.resource_path
		else:
			# Register thumbnail update ???
			pass
		objects.add_child(object)
		object.connect("toggled", Callable(toggle_target, toggle_target_name).bind(scene))
		object.connect("favourite_toggled", Callable(toggle_target, favourite_toggle_name).bind(scene))
		object.connect("toggled", Callable(self, "_on_object_toggled"))


func set_thumbnails() -> void:
	for child in get_objects():
		child.icon = object_group.thumbnails[child.scene.resource_path]


# See object button for more info why we use _input
func _input(event: InputEvent) -> void:
	var m := event as InputEventMouse
	if !m or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or m.button_mask != MOUSE_BUTTON_LEFT || using_multiselect == m.shift:
		return
	using_multiselect = m.shift
	for child in get_objects():
		child.multiselectable = using_multiselect


func _on_select_all(toggled: bool) -> void:
	for child in get_objects():
		child.multiselectable = true
		child.button_pressed = toggled


func _on_object_toggled(toggled: bool) -> void:
	var all_pressed: bool = $Objects.get_child(0).pressed
	for child in get_objects():
		if child.pressed != all_pressed:
			$Header/SelectAll.set_pressed_no_signal(false)
			# TODO: Make a cool three state checkbox!
			return
	$Header/SelectAll.set_pressed_no_signal(all_pressed)


func _on_description_pressed() -> void:
	emit_signal("header_pressed", object_group.group_name, $Header/Description)
