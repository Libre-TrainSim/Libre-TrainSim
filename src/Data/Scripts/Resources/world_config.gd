class_name WorldConfig
extends Resource


# I don't like it, but this is what OS.get_date() would return
# so let's stick to Godots chosen way of doing it.
export var release_date := {
	"year": 1989,
	"month": 11,
	"day": 9
}
export var title := "Unknown"
export var author := "Unknown"
export var track_description := "n/a"

export(String, FILE, "*.png,*.jpeg,*.jpg,*.bmp,*.gif") var thumbnail_path := ""

# path to the individual scenario.tres's
export(Array, String, FILE, "*.tres,*.res") var scenarios := []

# shown in the editor
export var editor_notes := ""


func get_release_date_string() -> String:
	return "%d.%d.%d" % [release_date.day, release_date.month, release_date.year]
