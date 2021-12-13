extends Control


var save_path := ""

var j_save_module = jSaveModule.new()


func _ready() -> void:
	save_path = find_parent("Editor").current_track_path + ".trackinfo"
	j_save_module.set_save_path(save_path)
	update_save_pathuration()


func save_everything() -> void:
	_on_SaveWorldConfig_pressed()


func _on_SaveWorldConfig_pressed() -> void:
	j_save_module.save_value("author", $GridContainer/Author.text)
	j_save_module.save_value("release_date", [$GridContainer/ReleaseDate/Day.value, $GridContainer/ReleaseDate/Month.value, $GridContainer/ReleaseDate/Year.value])
	j_save_module.save_value("description", $GridContainer/TrackDescription.text)
	j_save_module.save_value("editor_notes", $Notes.text)
	j_save_module.write_to_disk()
	Logger.log("Trackinfo saved.")


func update_save_pathuration() -> void:
	$GridContainer/ReleaseDate/Day.value = j_save_module.get_value("release_date", [1, 1, 2021])[0]
	$GridContainer/ReleaseDate/Month.value = j_save_module.get_value("release_date", [1, 1, 2021])[1]
	$GridContainer/ReleaseDate/Year.value = j_save_module.get_value("release_date", [1, 1, 2021])[2]
	$GridContainer/Author.text = j_save_module.get_value("author", "Unknown")
	$GridContainer/TrackDescription.text = j_save_module.get_value("description", "")
	$Notes.text = j_save_module.get_value("editor_notes", "")
