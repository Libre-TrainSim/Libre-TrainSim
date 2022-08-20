extends WindowDialog

var world_config: WorldConfig
var save_path: String

func _ready() -> void:
	save_path = find_parent("Editor").current_track_path + "_config.tres"
	world_config = load(save_path) as WorldConfig
	load_stored_config()


func _unhandled_key_input(_event: InputEventKey) -> void:
	if Input.is_action_just_released("ui_cancel", true):
		# There seems to be an issue with event propagation
		# Hence we wait for the frame to end before we actually hide it
		# because otherwise we immediately open the pause menu.
		call_deferred("hide")


func save_config() -> void:
	world_config.author = $Configuration/GridContainer/Author.text
	world_config.release_date = {
		"day": $Configuration/GridContainer/ReleaseDate/Day.value,
		"month": $Configuration/GridContainer/ReleaseDate/Month.value,
		"year": $Configuration/GridContainer/ReleaseDate/Year.value
	}
	world_config.track_description = $Configuration/GridContainer/TrackDescription.text
	world_config.editor_notes = $Configuration/Notes.text

	if ResourceSaver.save(save_path, world_config) != OK:
		Logger.err("Error saving world config at '%s'" % save_path, self)
		return
	Logger.log("World Config saved.")


func load_stored_config() -> void:
	$Configuration/GridContainer/ReleaseDate/Day.value = world_config.release_date["day"]
	$Configuration/GridContainer/ReleaseDate/Month.value = world_config.release_date["month"]
	$Configuration/GridContainer/ReleaseDate/Year.value = world_config.release_date["year"]
	$Configuration/GridContainer/Author.text = world_config.author
	$Configuration/GridContainer/TrackDescription.text = world_config.track_description
	$Configuration/Notes.text = world_config.editor_notes


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
