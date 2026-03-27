extends Node3D


var updateTimer: float = 0
func _process(delta: float) -> void:
	if Root.Editor:
		set_process(false)
		return
	updateTimer += delta
	if updateTimer > 0.5:
		updateTimer = 0
		var world: Node = get_parent()
		for child in get_children():
			if child.get_children().size() != 0 and child.is_class("MeshInstance3D"):
				for child2 in child.get_children():
					Logger.vlog("Correcting MeshInstance3D Position in Scene Tree...")
					child.remove_child(child2)
					add_child(child2)
					child2.owner = world
					child2.position = child.position + child2.global_transform.origin

	pass
