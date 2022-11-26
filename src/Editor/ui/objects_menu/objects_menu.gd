extends PanelContainer


signal object_added(node, global_position)


export var cursor_path: NodePath


var entries := {} # group_name: GroupEntry
var groups := [] # of ObjectGroup
var editor_info: EditorInfo = null

var selected_objects := {} # Scene
var current_object: PackedScene = null
var preview_object: Spatial = null
var moving_camera := false
var select_random := false

var filter_building := false
var filter_vegetation := false
var filter_infrastructure := false
var filter_decorative := false
var filter_favourites := false
var filter_common := false
var filter_recent := false

var header_only := false setget set_header_only


onready var content := $MarginContainer/Content/ScrollContainer/Content as VBoxContainer
onready var thumbnail_generator := $ThumbnailGenerator
onready var cursor := get_node(cursor_path) as WorldCursor
onready var search := $MarginContainer/Content/Search as LineEdit


func _ready() -> void:
	yield(get_tree(), "idle_frame")
	assert(editor_info)

	find_groups()
	populate_content()
	generate_thumbnails()


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if !mb or mb.pressed or !current_object:
		return

	# Only release events

	if mb.button_index == BUTTON_LEFT:
		if moving_camera:
			return
		var position := preview_object.global_translation
		cursor.remove_child(preview_object)
		editor_info.push_object(current_object)
		emit_signal("object_added", preview_object, position)
		preview_object = null
		select_object()
	elif mb.button_index == BUTTON_RIGHT:
		if moving_camera:
			preview_object.show()
			moving_camera = false
			select_object(0)
			return

		# Deselect through signal
		for entry in entries:
			entries[entry].deselect_all()
		select_object_scene(null)
	elif mb.button_index == BUTTON_WHEEL_UP and mb.shift:
		if moving_camera:
			return
		select_object(1)
	elif mb.button_index == BUTTON_WHEEL_DOWN and mb.shift:
		if moving_camera:
			return
		select_object(-1)


func filter(query: String) -> void:
	var regex := RegEx.new()
	if regex.compile(query) != OK:
		Logger.warn("Failed to compile query \"%s\"" % query, self)
		regex = null

	for entry in entries.values():
		# Apply group filters (the top four)
		var object_group = entry.object_group as ObjectGroup
		entry.visible = (filter_building and object_group.is_building) \
					or (filter_vegetation and object_group.is_vegetation) \
					or (filter_infrastructure and object_group.is_infrastructure) \
					or (filter_decorative and object_group.is_decorative) \
					or !(filter_building or filter_vegetation \
							or filter_infrastructure or filter_decorative)
		if !entry.visible:
			entry.deselect_all()
			continue
		var favourites := {}
		var common := {}
		var recent := []
		if filter_favourites:
			favourites = editor_info.favourites
		if filter_common:
			common = editor_info.common
		if filter_recent:
			recent = editor_info.recent
		entry.filter(regex, favourites, common, recent)


func find_groups() -> void:
	var paths := []
	for folder in ContentLoader.repo.object_folders:
		Root.crawl_directory(paths, folder, ["tres", "res"])
	var loaded_paths := {}
	for path in paths:
		if loaded_paths.has(path):
			continue
		loaded_paths[path] = true
		var ressource := load(path)
		if ressource is ObjectGroup:
			groups.append(ressource)


func generate_thumbnails() -> void:
	for group in groups:
		thumbnail_generator.generate_thumbnails(group)
		yield(thumbnail_generator, "group_finished")
		# Load the thumbnails here? or use the texture created callback
		entries[group.group_name].set_thumbnails()


func populate_content() -> void:
	for group in groups:
		var entry := preload("res://Editor/ui/objects_menu/group_entry.tscn").instance()
		entry.set_objects(group, self, "_on_object_scene_changed", \
				"_on_favourite_changed", editor_info.favourites)
		entry.connect("header_pressed", self, "_on_header_pressed")
		entries[group.group_name] = entry
		content.add_child(entry)


func select_object(offset := 1) -> void:
	if selected_objects.size() == 0:
		select_object_scene(null)
		return

	var objects := selected_objects.keys()
	if select_random:
		select_object_scene(objects[randi() % objects.size()])
		return
	select_object_scene(objects[(objects.find(current_object) + offset) % objects.size()])


func select_object_scene(scene: PackedScene) -> void:
	current_object = null
	if preview_object:
		cursor.remove_child(preview_object)
		preview_object.queue_free()
		preview_object = null

	if scene == null:
		return

	current_object = scene
	preview_object = current_object.instance()
	cursor.add_child(preview_object)


func set_header_only(value := true) -> void:
	header_only = value
	for entry in entries.values():
		entry.set_header_mode(value)


func _on_header_pressed(group_name: String, focus_target: Control) -> void:
	set_header_only(!header_only)
	focus_target.grab_focus()


func _on_object_scene_changed(added: bool, scene: PackedScene) -> void:
	if added:
		selected_objects[scene] = true
		select_object_scene(scene)
	else:
		selected_objects.erase(scene)
		if current_object == scene:
			select_object(0)


func _on_favourite_changed(added: bool, scene: PackedScene) -> void:
	if added:
		editor_info.favourites[scene] = true
	else:
		editor_info.favourites.erase(scene)


func _on_search_text_changed(query: String) -> void:
	filter(query)


func _on_buildings_toggled(button_pressed: bool) -> void:
	filter_building = button_pressed
	filter(search.text)


func _on_vegetation_toggled(button_pressed: bool) -> void:
	filter_vegetation = button_pressed
	filter(search.text)


func _on_infrastructure_toggled(button_pressed: bool) -> void:
	filter_infrastructure = button_pressed
	filter(search.text)


func _on_decorative_toggled(button_pressed: bool) -> void:
	filter_decorative = button_pressed
	filter(search.text)


func _on_favourites_toggled(button_pressed: bool) -> void:
	filter_favourites = button_pressed
	filter(search.text)


func _on_most_common_toggled(button_pressed: bool) -> void:
	filter_common = button_pressed
	filter(search.text)


func _on_most_recent_toggled(button_pressed: bool) -> void:
	filter_recent = button_pressed
	filter(search.text)


func _on_random_toggled(button_pressed: bool) -> void:
	select_random = button_pressed


func _on_Camera_first_person_movement_started() -> void:
	if preview_object:
		preview_object.hide()


func _on_first_person_was_moved() -> void:
	moving_camera = true
