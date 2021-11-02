extends Spatial

export (int) var distance: int = 0

func _ready() -> void:
	if not Engine.editor_hint:
		$Mesh.set_surface_material(1, $Mesh.get_surface_material(1).duplicate(true))
		$Mesh.get_surface_material(1).albedo_texture = $Viewport.get_texture()
		var km = int(distance / 1000)
		var m = int((distance - km*1000) / 100)
		$Viewport/Control/VBoxContainer/km.text = str(km)
		$Viewport/Control/VBoxContainer/m.text = str(m)
