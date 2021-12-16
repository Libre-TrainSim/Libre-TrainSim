class_name Rail2DCollider
extends Line2D

var input_handling_node: Node

func _ready():
	var area_2d = Area2D.new()
	add_child(area_2d)
	var collision_polygon_2d = CollisionPolygon2D.new()
	collision_polygon_2d.name = "CollisionPolygon2D"
	area_2d.add_child(collision_polygon_2d)
	area_2d.connect("input_event", self, "_on_RailCollider_input_event")


	var line_points = points
	var polygon_points = PoolVector2Array()

	# Create right outer line
	for i in range(line_points.size()):
		var direction = 0 # Radians
		if i == 0: # First Point
			direction = line_points[0].angle_to_point(line_points[1])
		elif i == line_points.size() -1: # Last Point
			direction = line_points[line_points.size() -2].angle_to_point(line_points[line_points.size() -1])
		else: # Other Points
			var direction_1 = line_points[i-1].angle_to_point(line_points[i])
			var direction_2 = line_points[i].angle_to_point(line_points[i+1])
			direction = deg2rad(Math.angle_distance_deg(rad2deg(direction_1), rad2deg(direction_2)))/2.0

		if rad2deg(direction) > 90:
			direction -= PI
		elif rad2deg(direction) < -90:
			direction += PI
		polygon_points.append(line_points[i] + Vector2(0, width/2).rotated(direction))


	# Create left outer line
	for i in range(line_points.size()):
		i = line_points.size() - 1 - i
		var direction = 0 # Radians
		if i == line_points.size() -1: # First Point
			direction = line_points[line_points.size()-1].angle_to_point(line_points[line_points.size()-2])
		elif i == 0: # Last Point
			direction = line_points[1].angle_to_point(line_points[0])
		else: # Other Points
			var direction_1 = line_points[i+1].angle_to_point(line_points[i])
			var direction_2 = line_points[i].angle_to_point(line_points[i-1])
			direction = deg2rad(Math.angle_distance_deg(rad2deg(direction_1), rad2deg(direction_2)))/2.0

		if rad2deg(direction) > 90:
			direction -= PI
		elif rad2deg(direction) < -90:
			direction += PI
		polygon_points.append(line_points[i] - Vector2(0, width/2).rotated(direction))

	collision_polygon_2d.polygon = polygon_points


func _on_RailCollider_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		input_handling_node._item_selected(name, get_parent().name)
