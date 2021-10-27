extends Area2D

var input_handling_node

func _ready():
	var line_points = get_parent().points
	var width = get_parent().width
	var polygon_points = PoolVector2Array()


	# Create right outer line
	for i in range(line_points.size()):
		var direction = 0 # Radians
		if i == 0: # First Point
#			direction = line_points[0].angle_to(line_points[1])
			direction = line_points[0].angle_to_point(line_points[1])

		elif i == line_points.size() -1: # Last Point
#			direction = line_points[line_points.size() -2].angle_to(line_points[line_points.size() -1])
			direction = line_points[line_points.size() -2].angle_to_point(line_points[line_points.size() -1])
#			if rad2deg(direction) > 90:
#				direction -= PI
#			elif rad2deg(direction) < -90:
#				direction += PI
		else: # Other Points
#			direction = line_points[i-1].angle_to_point(line_points[i])
			var direction_1 = line_points[i-1].angle_to_point(line_points[i])
			var direction_2 = line_points[i].angle_to_point(line_points[i+1])
#			var direction_1 = line_points[i-1].angle_to(line_points[i])
#			var direction_2 = line_points[i].angle_to(line_points[i+1])
#			direction = (direction_1 + direction_2) / 2
			direction = deg2rad(Math.angle_distance_deg(rad2deg(direction_1), rad2deg(direction_2)))/2.0
#			print(rad2deg(direction))

		#direction -= deg2rad(90)
		if rad2deg(direction) > 90:
			direction -= PI
		elif rad2deg(direction) < -90:
			direction += PI
#		print(get_parent().name)
#		print(rad2deg(direction))
		polygon_points.append(line_points[i] + Vector2(0, width/2).rotated(direction))
#		print(rad2deg(direction))
#		print(Vector2(0,width/2).rotated(direction))
#		print(Vector2(0,width/2))

	# Create left outer line
	for i in range(line_points.size()):
		i = line_points.size() - 1 - i
		var direction = 0 # Radians
		if i == line_points.size() -1: # First Point
			direction = line_points[line_points.size()-1].angle_to_point(line_points[line_points.size()-2])
#			direction = line_points[line_points.size()-1].angle_to(line_points[line_points.size() -2])
		elif i == 0: # Last Point
			direction = line_points[1].angle_to_point(line_points[0])
#			direction = line_points[1].angle_to(line_points[0])
		else: # Other Points
#			direction = line_points[i+1].angle_to_point(line_points[i])
			var direction_1 = line_points[i+1].angle_to_point(line_points[i])
			var direction_2 = line_points[i].angle_to_point(line_points[i-1])
#			direction = (line_points[i+1].angle_to(line_points[i]) + line_points[i].angle_to(line_points[i-1]))/2.0
#			direction = (direction_1 + direction_2) / 2
			direction = deg2rad(Math.angle_distance_deg(rad2deg(direction_1), rad2deg(direction_2)))/2.0
#			print(rad2deg(direction_1))
#			print(rad2deg(direction_2))
#			print(rad2deg(direction))
#			print("###")


#		direction -= deg2rad(90)
		if rad2deg(direction) > 90:
			direction -= PI
		elif rad2deg(direction) < -90:
			direction += PI
		polygon_points.append(line_points[i] - Vector2(0, width/2).rotated(direction))

	$CollisionPolygon2D.polygon = polygon_points
#
#func _input(event):
#	if event is InputEventMouseButton and event.pressed:
#		_ready()


func _on_RailCollider_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		input_handling_node._item_selected(get_parent().name, get_parent().get_parent().name)
