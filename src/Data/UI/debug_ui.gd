extends CanvasLayer


var debug_camera: DebugCamera


onready var fps_label := $DebugContainer/FPSContainer/FPSLabel as Label
onready var camera_target_list := $DebugContainer/DebugCameraTargets as ColoredItemList

onready var draw_passenger_label := $DebugContainer/PassengerDebugContainer/DrawPassengerLabel as CheckBox
onready var draw_station_label := $DebugContainer/PassengerDebugContainer/DrawStationLabel as CheckBox
onready var draw_wagon_label := $DebugContainer/PassengerDebugContainer/DrawWagonLabel as CheckBox


func _ready() -> void:
	$DebugContainer.hide()
	draw_passenger_label.pressed = ProjectSettings.get_setting("game/debug/draw_labels/passenger")
	draw_station_label.pressed = ProjectSettings.get_setting("game/debug/draw_labels/station")
	draw_wagon_label.pressed = ProjectSettings.get_setting("game/debug/draw_labels/wagon")


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


func _get_player_train() -> LTSPlayer:
	for player in get_tree().get_nodes_in_group("Player"):
		if not (player is LTSPlayer) or player.ai:
			continue
		if player.current_station_node != null:
			return player
	return null


func _on_SpawnPassengers_pressed():
	var player := _get_player_train()
	if player:
		player.update_waiting_persons_on_next_station()


func _on_BoardToTrain_pressed():
	var player := _get_player_train()
	if player:
		player.arrived_to_current_station()


func _on_ExitToStation_pressed():
	var player := _get_player_train()
	if player:
		player.send_persons_to_station()


func _on_DrawPassengerLabel_pressed():
	ProjectSettings.set_setting("game/debug/draw_labels/passenger", draw_passenger_label.pressed)


func _on_DrawWagonLabel_pressed():
	ProjectSettings.set_setting("game/debug/draw_labels/wagon", draw_wagon_label.pressed)


func _on_DrawStationLabel_pressed():
	ProjectSettings.set_setting("game/debug/draw_labels/station", draw_station_label.pressed)
