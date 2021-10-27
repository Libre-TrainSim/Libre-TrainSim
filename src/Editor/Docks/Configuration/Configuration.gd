extends Control


var save_path := ""


func _ready() -> void:
	save_path = find_parent("Editor").current_track_path + ".trackinfo"
	$jSaveModule.set_save_path(save_path)
	update_save_pathuration()


func save_everything() -> void:
	_on_SaveWorldConfig_pressed()


func _on_SaveWorldConfig_pressed() -> void:
	$jSaveModule.save_value("author", $GridContainer/Author.text)
	$jSaveModule.save_value("release_date", [$GridContainer/ReleaseDate/Day.value, $GridContainer/ReleaseDate/Month.value, $GridContainer/ReleaseDate/Year.value])
	$jSaveModule.save_value("description", $GridContainer/TrackDescription.text)
	$jSaveModule.save_value("editor_notes", $Notes.text)
	$jSaveModule.write_to_disk()
	Logger.log("Trackinfo saved.")


func update_save_pathuration() -> void:
	$GridContainer/ReleaseDate/Day.value = $jSaveModule.get_value("release_date", [1, 1, 2021])[0]
	$GridContainer/ReleaseDate/Month.value = $jSaveModule.get_value("release_date", [1, 1, 2021])[1]
	$GridContainer/ReleaseDate/Year.value = $jSaveModule.get_value("release_date", [1, 1, 2021])[2]
	$GridContainer/Author.text = $jSaveModule.get_value("author", "Unknown")
	$GridContainer/TrackDescription.text = $jSaveModule.get_value("description", "")
	$Notes.text = $jSaveModule.get_value("editor_notes", "")
