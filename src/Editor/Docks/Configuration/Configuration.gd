extends WindowDialog


var save_path := ""
var j_save_module := jSaveModule.new()


func _ready() -> void:
	save_path = find_parent("Editor").current_track_path + ".trackinfo"
	j_save_module.set_save_path(save_path)
	load_stored_config()


func _unhandled_key_input(_event: InputEventKey) -> void:
	if Input.is_action_just_released("ui_cancel", true):
		# There seems to be an issue with event propagation
		# Hence we wait for the frame to end before we actually hide it
		# because otherwise we immediately open the pause menu.
		call_deferred("hide")


func save_config() -> void:
	j_save_module.save_value("author", $Configuration/GridContainer/Author.text)
	j_save_module.save_value("release_date", [$Configuration/GridContainer/ReleaseDate/Day.value, $Configuration/GridContainer/ReleaseDate/Month.value, $Configuration/GridContainer/ReleaseDate/Year.value])
	j_save_module.save_value("description", $Configuration/GridContainer/TrackDescription.text)
	j_save_module.save_value("editor_notes", $Configuration/Notes.text)
	j_save_module.write_to_disk()
	Logger.log("Trackinfo saved.")


func load_stored_config() -> void:
	$Configuration/GridContainer/ReleaseDate/Day.value = j_save_module.get_value("release_date", [1, 1, 2021])[0]
	$Configuration/GridContainer/ReleaseDate/Month.value = j_save_module.get_value("release_date", [1, 1, 2021])[1]
	$Configuration/GridContainer/ReleaseDate/Year.value = j_save_module.get_value("release_date", [1, 1, 2021])[2]
	$Configuration/GridContainer/Author.text = j_save_module.get_value("author", "Unknown")
	$Configuration/GridContainer/TrackDescription.text = j_save_module.get_value("description", "")
	$Configuration/Notes.text = j_save_module.get_value("editor_notes", "")


func _on_Cancel_pressed() -> void:
	hide()


func _on_Save_pressed() -> void:
	save_config()
	hide()


func _on_about_to_show() -> void:
	get_tree().paused = true


func _on_popup_hide() -> void:
	get_tree().paused = false
	queue_free()
