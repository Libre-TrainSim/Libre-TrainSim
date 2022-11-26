class_name ObjectGroup
extends Resource


export var group_name := ""
export(Array, PackedScene) var scenes := []
export var is_building := false
export var is_vegetation := false
export var is_infrastructure := false
export var is_decorative := false

var thumbnails := {} # Path -> ImageTexture
