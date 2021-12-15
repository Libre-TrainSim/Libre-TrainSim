extends Area2D


var input_handling_node: Node


func _on_Collider_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		input_handling_node._item_selected(get_parent().name, get_parent().get_parent().name)

func set_radius(new_radius) -> void:
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate(true)
	$CollisionShape2D.shape.radius = new_radius
