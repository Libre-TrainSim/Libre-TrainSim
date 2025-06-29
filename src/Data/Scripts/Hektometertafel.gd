extends Node3D

@export var distance: int = 0

func _ready() -> void:
	if not Engine.is_editor_hint():
		var km = int(distance / 1000)
		var m = int((distance - km*1000) / 100)
		$LabelTop.text = str(km)
		$LabelBottom.text = str(m)
