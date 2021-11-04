class_name Pause
extends Control

signal paused
signal unpaused


var _saved_ingame_pause: bool = false
var _saved_mouse_mode: int = 0
var player: LTSPlayer


func _unhandled_input(_event) -> void:
	if Input.is_action_just_pressed("Escape"):
		get_tree().paused = !get_tree().paused
		visible = !visible
		if visible:
			_saved_ingame_pause = Root.ingame_pause
			Root.ingame_pause = false
			_saved_mouse_mode = Input.get_mouse_mode()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			emit_signal("paused")
		else:
			Input.set_mouse_mode(_saved_mouse_mode)
			Root.ingame_pause = _saved_ingame_pause
			emit_signal("unpaused")


func _on_Back_pressed() -> void:
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(_saved_mouse_mode)
	Root.ingame_pause = _saved_ingame_pause


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _on_QuitMenu_pressed() -> void:
	get_tree().paused = false
	jAudioManager.clear_all_sounds()
	jEssentials.remove_all_pending_delayed_calls()
	LoadingScreen.load_main_menu()


func _on_JumpToStation_pressed() -> void:
	$StationJumper.update_list(player)
	$StationJumper.show()


func _on_StationJumper_station_index_selected(station_index: int) -> void:
	_on_Back_pressed()
	find_parent("World").jump_player_to_station(station_index)


func _on_RestartScenario_pressed() -> void:
	_on_Back_pressed()
	jEssentials.remove_all_pending_delayed_calls()
	jAudioManager.clear_all_sounds()
	var _unused = get_tree().reload_current_scene()


func _on_Settings_pressed() -> void:
	jSettings.popup()
