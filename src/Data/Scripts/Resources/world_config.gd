class_name WorldConfig
extends Resource


# I don't like it, but this is what OS.get_date() would return
# so let's stick to Godots chosen way of doing it.
@export var release_date: Dictionary = {
	"year": 1989,
	"month": 11,
	"day": 9
}
@export var title: String = "Untitled"  # right now, the filename is used I think
@export var author: String = "Unknown"
@export var track_description: String = "n/a"

# set this to false if you want to make underground maps, for example
@export var generate_grass: bool = true

# AFAIK this is a hardcoded path anyways
#export(String, FILE, "*.png,*.jpeg,*.jpg,*.bmp,*.gif") var thumbnail_path := ""

# shown in the editor
@export var editor_notes: String = ""


func get_release_date_string() -> String:
	return "%d.%d.%d" % [release_date.day, release_date.month, release_date.year]
