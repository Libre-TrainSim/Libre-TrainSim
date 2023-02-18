extends Control

signal save_requested


func show() -> void:
	$VBoxContainer/Back.grab_focus()
	.show()


func _unhandled_input(event: InputEvent) -> void:
	if visible and Input.is_action_just_released("pause", true):
		# There seems to be an issue with event propagation
		# Hence we wait for the frame to end before we actually hide it
		# because otherwise we immediately open the menu again.
		call_deferred("hide")


func _on_SaveAndExit_pressed():
	emit_signal("save_requested")
	get_tree().paused = false
	LoadingScreen.load_main_menu()


func _on_Back_pressed() -> void:
	hide()


func _on_hide() -> void:
	get_tree().paused = false


func _on_ExitWithoutSave_pressed() -> void:
	get_tree().paused = false
	LoadingScreen.load_main_menu()
