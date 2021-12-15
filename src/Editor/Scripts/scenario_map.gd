extends Node

const LINE_POINT_INTERVAL = 15

var mouse_motion = Vector2(0,0)

var world

var signal_icon = preload("res://Data/Misc/Signal_Icon.png")
var signal_icon_block = preload("res://Data/Misc/Signal_Icon_block.png")
var signal_icon_station = preload("res://Data/Misc/Signal_Icon_station.png")
var station_image = preload("res://Data/Misc/Station_Icon.png")
var station_image_selected = preload("res://Data/Misc/Station_Icon_selected.png")
var contact_point_image = preload("res://Data/Misc/ContactPoint_Icon.png")
var spawn_point_icon = preload("res://Data/Misc/spawn_point_icon.png")
var despawn_point_icon = preload("res://Data/Misc/despawn_point_icon.png")
var waypoint_icon = preload("res://Data/Misc/waypoint_icon.png")


var label_mask: Dictionary = {
	rails = true,
	signals = true,
	stations = true,
	contact_points = true,
	other = true
}


signal item_selected(path)


func _process(delta : float) -> void:
	var movement = mouse_motion * $Camera2D.zoom.x
	$Camera2D.position += movement
	mouse_motion = Vector2(0,0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("zoom_in"):
		var zoom = $Camera2D.zoom
		zoom.x = clamp(zoom.x*0.8, 0.05, 50)
		zoom.y = clamp(zoom.y*0.8, 0.05, 50)
		$Camera2D.zoom = zoom
		get_tree().set_input_as_handled()

	if event.is_action("zoom_out"):
		var zoom = $Camera2D.zoom
		zoom.x = clamp(zoom.x*1.25, 0.05, 50)
		zoom.y = clamp(zoom.y*1.25, 0.05, 50)
		$Camera2D.zoom = zoom
		get_tree().set_input_as_handled()

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_MIDDLE):
		mouse_motion -= event.relative
		get_tree().set_input_as_handled()


func set_label_mask(_label_mask: Dictionary):
	label_mask = _label_mask
	update_map()

func create_signal(signal_instance):
	var sprite = generate_rail_icon_at(signal_instance.attached_rail, signal_instance.on_rail_position, signal_instance.forward)
	sprite.name = signal_instance.name
	var collider = preload("res://Editor/Modules/Collider2D.tscn").instance()
	if signal_instance.type == "Signal":
		match find_parent("ScenarioEditor").get_node("CanvasLayer/ScenarioConfiguration").get_operation_mode_of_signal(signal_instance.name):
			SignalOperationMode.BLOCK:
				sprite.texture = signal_icon_block
			SignalOperationMode.STATION:
				sprite.texture = signal_icon_station
			SignalOperationMode.MANUAL:
				sprite.texture = signal_icon
		collider.set_radius(50)
		sprite.add_to_group("Signal")
	elif signal_instance.type == "Station":
		sprite.texture = station_image
		collider.set_radius(50)
		sprite.add_to_group("Station")
	elif signal_instance.type == "ContactPoint":
		sprite.texture = contact_point_image
		collider.set_radius(50)
		sprite.add_to_group("ContactPoint")
	collider.input_handling_node = self
	sprite.add_child(collider)
	$Signals.add_child(sprite)
	sprite.owner = $Signals


func _item_selected(name : String, parent : String):
	emit_signal("item_selected", parent + "/" + name)
	Logger.log(name + " in " + parent + " Node selected.")





func calculate_2d_points_from_rail(rail) -> Array:
	var points = []

	var length
	if rail.parRail != null:
		length = rail.parRail.length
	else:
		length = rail.length

	# detailed rail for curves
	if rail.radius != 0:
		var point_count = int(length / LINE_POINT_INTERVAL) + 1
		# add point count many points along track
		for i in range(0,point_count):
			var rail_transform = rail.get_global_transform_at_rail_distance(i*LINE_POINT_INTERVAL)
			points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
		# add end point
		var rail_transform = rail.get_global_transform_at_rail_distance(rail.length)
		points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
	# only 2 points for straight rails
	else:
		# Start Point
		var rail_transform = rail.get_global_transform_at_rail_distance(0)
		points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
		# End Point
		rail_transform = rail.get_global_transform_at_rail_distance(rail.length)
		points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))

	return points


func create_line2d_from_rail(rail, special: bool = false):
	var line = Line2D.new()

	# Note: we do not need a "map scale"
	# the rails are probably 100s of meters long, so that would make a very
	# large map, but! line points are measured in pixels. No problem! :)
	var points = calculate_2d_points_from_rail(rail)
	line.points = points
	line.width = 1.435
	line.antialiased = true
	line.name = rail.name

	line.set_script(Rail2DCollider)
	line.input_handling_node = self

	if not special:
		$Rails.add_child(line)
		line.default_color = Color("1e6c93")
	else:
		$RailsSelection.add_child(line)
		line.default_color = Color("2891c5")

func init(world : Node):
	self.world = world
	var rails = world.get_node("Rails").get_children()
	for rail in rails:
		create_line2d_from_rail(rail)

	var signals = world.get_node("Signals").get_children()
	for signal_instance in signals:
		if signal_instance.type == "Station" or signal_instance.type == "Signal"\
				or  signal_instance.type == "ContactPoint":
			create_signal(signal_instance)


func update_map():
	var scenario_config_instance = find_parent("ScenarioEditor").get_node("CanvasLayer/ScenarioConfiguration")
	var route_manager = scenario_config_instance.route_manager
	$Rails.visible = label_mask.rails

	for signal_instance in $Signals.get_children():
		if signal_instance.is_in_group("Signal"):
			signal_instance.visible = label_mask.signals
		if signal_instance.is_in_group("Station"):
			signal_instance.visible = label_mask.stations
		if signal_instance.is_in_group("ContactPoint"):
			signal_instance.visible = label_mask.contact_points

	# Clear old selection:
	for child in $Special.get_children():
		child.free()
	for child in $RailsSelection.get_children():
		child.free()

	if label_mask.signals:
		for signal_instance in $Signals.get_children():
			if signal_instance.is_in_group("Signal"):
				match scenario_config_instance.get_operation_mode_of_signal(signal_instance.name):
					SignalOperationMode.BLOCK:
						signal_instance.texture = signal_icon_block
					SignalOperationMode.STATION:
						signal_instance.texture = signal_icon_station
					SignalOperationMode.MANUAL:
						signal_instance.texture = signal_icon

	if not label_mask.other:
		return

	var route_data: Array = route_manager.get_route_data()
	var baked_route: Array = route_manager.get_calculated_rail_route(world)
	if baked_route.size() == 0:
		return

	# Mark rails of route
	for entry in baked_route:
		create_line2d_from_rail(entry.rail, true)

	# Mark stations at route and add waypoints:
	for route_point in route_data:
		if route_point.type == RoutePointType.STATION:
			var sprite: Sprite
			var station = world.get_signal(route_point.node_name)
			sprite = generate_rail_icon_at(station.attached_rail, station.on_rail_position, station.forward)
			sprite.name = route_point.node_name
			sprite.texture = station_image_selected
			$Special.add_child(sprite)
		if route_point.type == RoutePointType.WAY_POINT:
			var forward = true
			for entry in baked_route:
				if entry.rail.name == route_point.rail_name:
					forward = entry.forward
			var sprite: Sprite
			if forward:
				sprite = generate_rail_icon_at(route_point.rail_name, 0, true)
			else:
				sprite = generate_rail_icon_at(route_point.rail_name, world.get_rail(route_point.rail_name).length, false)
			sprite.texture = waypoint_icon
			$Special.add_child(sprite)

	# Special Points:

	# Spawn Point:
	var spawn_point: Dictionary = {}
	if route_data.size() > 0:
		spawn_point = route_data[0]
	if spawn_point != {}:
		var sprite: Sprite
		if spawn_point.type == RoutePointType.STATION:
			var station = world.get_signal(spawn_point.node_name)
			sprite = generate_rail_icon_at(station.attached_rail, station.on_rail_position, station.forward)
		elif spawn_point.type == RoutePointType.SPAWN_POINT:
			sprite = generate_rail_icon_at(spawn_point.rail_name, spawn_point.distance, baked_route[0].forward)

		sprite.name = "SpawnPoint"
		sprite.texture = spawn_point_icon
		$Special.add_child(sprite)
	# Despawn Point:
	var despawn_point = route_manager.get_despawn_information()
	if despawn_point.type == RoutePointType.STATION or despawn_point.type == RoutePointType.DESPAWN_POINT:
		var sprite: Sprite
		if despawn_point.type == RoutePointType.STATION:
			var station = world.get_signal(despawn_point.node_name)
			sprite = generate_rail_icon_at(station.attached_rail, station.on_rail_position, station.forward)
		elif despawn_point.type == RoutePointType.DESPAWN_POINT:
			sprite = generate_rail_icon_at(despawn_point.rail_name, despawn_point.distance, baked_route.back().forward)
		sprite.name = "DespawnPoint"
		sprite.texture = despawn_point_icon
		$Special.add_child(sprite)



func generate_rail_icon_at(rail_name: String, distance: float, forward: bool) -> Sprite:
	var sprite = Sprite.new()
	var position_3d = world.get_rail(rail_name).get_pos_at_RailDistance(distance)
	var rotation_degrees =  world.get_rail(rail_name).get_deg_at_RailDistance(distance)
	if not forward:
		rotation_degrees += 180
	sprite.position = Vector2(position_3d.x, position_3d.z)
	sprite.scale = Vector2(0.1, 0.1)
	sprite.rotation_degrees = -rotation_degrees + 90
	return sprite
