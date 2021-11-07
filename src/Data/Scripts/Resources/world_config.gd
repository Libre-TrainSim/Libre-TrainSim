class_name WorldConfig
extends Resource


# I don't like it, but this is what OS.get_date() would return
# so let's stick to Godots chosen way of doing it.
export var release_date := {
	"year": 1989,
	"month": 11,
	"day": 9
}
export var title := ""
export var author := ""
export var track_description := ""

export(String, FILE, "*.png,*.jpeg,*.jpg,*.bmp,*.gif") var thumbnail_path := ""

# path to the individual scenario.tres's
export(Array, String, FILE, "*.tres,*.res") var scenarios := []

# shown in the editor
export var notes := ""
