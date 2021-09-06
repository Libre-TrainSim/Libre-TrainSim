class_name Pause
extends Control

signal paused
signal unpaused


var _saved_ingame_pause := false
var _saved_mouse_mode := 0
var player


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


func _on_Back_pressed():
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(_saved_mouse_mode)
	Root.ingame_pause = _saved_ingame_pause


func _on_Quit_pressed():
	get_tree().quit()


func _on_QuitMenu_pressed():
	get_tree().paused = false
	jAudioManager.clear_all_sounds()
	jEssentials.remove_all_pending_delayed_calls()
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/main_menu.tscn")


func _on_JumpToStation_pressed():
	$StationJumper.update_list(player)
	$StationJumper.show()


func _on_StationJumper_station_index_selected(station_index):
	_on_Back_pressed()
	find_parent("World").jump_player_to_station(station_index)


func _on_RestartScenario_pressed():
	_on_Back_pressed()
	jEssentials.remove_all_pending_delayed_calls()
	jAudioManager.clear_all_sounds()
	get_tree().reload_current_scene()


func _on_Settings_pressed() -> void:
	jSettings.popup()
