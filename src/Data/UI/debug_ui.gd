extends CanvasLayer


var debug_camera: DebugCamera


onready var fps_label := $DebugContainer/FPSContainer/FPSLabel as Label
onready var camera_target_list := $DebugContainer/DebugCameraTargets as ColoredItemList


func _ready() -> void:
	$DebugContainer.hide()


func _process(_delta: float) -> void:
	fps_label.text = str(int(Engine.get_frames_per_second()))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_debug_ui", false, true):
		if $DebugContainer.visible:
			$DebugContainer.hide()
			set_process(false)
		else:
			$DebugContainer.show()
			set_process(true)
			update_camera_targets()
			$DebugContainer/TimeScale.value = Engine.time_scale
	if event.is_action_pressed("free_cursor", false, true):
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func update_camera_targets() -> void:
	camera_target_list.clear()
	for player in get_tree().get_nodes_in_group("Player"):
		if not (player is LTSPlayer):
			continue
		camera_target_list.add_item(player.name)
		camera_target_list.set_item_metadata(camera_target_list.get_item_count() - 1, player)


func _on_DebugCameraTargets_item_selected(index: int) -> void:
	if is_instance_valid(debug_camera):
		debug_camera.queue_free()
	debug_camera = DebugCamera.new()
	get_tree().root.add_child(debug_camera)
	debug_camera.current = true
	debug_camera.follow_target = camera_target_list.get_item_metadata(index)
	Logger.err(camera_target_list.get_item_metadata(index), self)


func _on_DeactivateDebugCamera_pressed() -> void:
	if not is_instance_valid(debug_camera):
		return
	debug_camera.queue_free()


func _on_TimeScale_value_changed(value: float) -> void:
	Engine.time_scale = value
