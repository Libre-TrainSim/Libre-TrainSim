class_name Rail2DCollider
extends Line2D

var input_handling_node: Node


func _ready():
	var area_2d = Area2D.new()
	add_child(area_2d)
	area_2d.connect("input_event", self, "_on_RailCollider_input_event")

	var line_points = points
	for i in range(line_points.size() - 1):
		var shape = CollisionShape2D.new()
		shape.position = 0.5 * (points[i] + points[i+1])
		shape.rotation = points[i].angle_to_point(points[i+1])

		var length = points[i].distance_to(points[i+1])
		var rect = RectangleShape2D.new()
		rect.extents = Vector2(length/2, width)

		shape.shape = rect
		area_2d.add_child(shape)


func _on_RailCollider_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		input_handling_node._item_selected(name, get_parent().name)
