extends Viewport

const LINE_POINT_INTERVAL = 10 # 1 line point for every 10 meters of track

onready var train_world = find_parent("World")
onready var camera = $Camera2D

onready var signal_green = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/GreenSignal.png")
onready var signal_red = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/RedSignal.png")
onready var signal_orange = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/OrangeSignal.png")

var follow_player = true
var overlay = false


func init_map():
	if train_world == null:
		print("RAILMAP: Could not find world! Despawning!")
		queue_free()
	
	var rails = train_world.get_node("Rails").get_children()
	for rail in rails:
		create_line2d_from_rail(rail)
	
	var signals = train_world.get_node("Signals").get_children()
	for signal_i in signals:
		if signal_i.type == "Signal":
			create_signal(signal_i)
		elif signal_i.type == "Station":
			create_station(signal_i)
	
	close_map()
	camera.current = true


func open_full_map():
	self.set_process(true)
	self.set_process_input(true)
	self.size = OS.window_size
	overlay = false
	$RouteLines.show()
	$RailLines.show()
	$Signals.show()


func open_overlay_map():
	self.set_process(true)
	self.set_process_input(true)
	var os_size = OS.window_size
	self.size = Vector2(os_size.x*0.33,os_size.y)
	overlay = true
	$Signals.hide()
	$RailLines.hide()
	$RouteLines.show()


func close_map():
	self.set_process(false)
	self.set_process_input(false)


var mouse_motion = Vector2(0,0)
func _input(event: InputEvent) -> void:
	if event.is_action("zoom_in"):
		var zoom = $Camera2D.zoom
		zoom.x = clamp(zoom.x*0.8, 0.01, 2.5)
		zoom.y = clamp(zoom.y*0.8, 0.01, 2.5)
		$Camera2D.zoom = zoom
		for node in $Stations.get_children():
			node.scale = zoom.clamped(1)*0.33
		
	if event.is_action("zoom_out"):
		var zoom = $Camera2D.zoom
		zoom.x = clamp(zoom.x*1.25, 0.01, 3)
		zoom.y = clamp(zoom.y*1.25, 0.01, 3)
		$Camera2D.zoom = zoom
		for node in $Stations.get_children():
			node.scale = zoom.clamped(1)*0.33
	
	if event.is_action_pressed("map_center_player") and not overlay:
		follow_player = true
	
	if event is InputEventMouseButton and not overlay:
		if event.button_index == BUTTON_MIDDLE:
			follow_player = false
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_MIDDLE):
		mouse_motion -= event.relative


func _process(delta: float) -> void:
	var player_pos = train_world.player.translation
	var player_pos_2d = Vector2(player_pos.x, player_pos.z)
	
	$PlayerPolygon.position = player_pos_2d
	$PlayerPolygon.rotation_degrees = -train_world.player.rotation_degrees.y
	
	if follow_player == true:
		camera.position = player_pos_2d
	else:
		camera.position += mouse_motion * $Camera2D.zoom.x * 0.5
		mouse_motion = Vector2(0,0)


func create_station(signal_instance):
	var index = train_world.player.stations["nodeName"].find(signal_instance.name)
	if index < 0:
		print("Station Name not found!")
		return
	
	var node = Node2D.new()
	node.rotation_degrees = -45
	#node.scale = Vector2(0.1, 0.1)
	node.position = Vector2(signal_instance.translation.x, signal_instance.translation.z)
	node.name = signal_instance.name
	$Stations.add_child(node)
	node.owner = $Stations
	
	var label = $LabelPrototype.duplicate()
	node.add_child(label)
	label.owner = node
	label.show()
	label.rect_position.y = -140
	label.text = train_world.player.stations["stationName"][index]


func create_signal(signal_instance):
	var sprite = Sprite.new()
	sprite.position = Vector2(signal_instance.translation.x, signal_instance.translation.z)
	sprite.scale = Vector2(0.2, 0.2)
	sprite.name = signal_instance.name
	$Signals.add_child(sprite)
	sprite.owner = $Signals
	signal_instance.connect("status_changed", self, "_on_signal_changed")
	_on_signal_changed(signal_instance) # call once to init


func _on_signal_changed(signal_instance):
	var sprite: Sprite = $Signals.get_node(signal_instance.name)
	if signal_instance.status == 0:
		sprite.texture = signal_red
	elif signal_instance.orange == true:
		sprite.texture = signal_orange
	else:
		sprite.texture = signal_green


func create_line2d_from_rail(rail):
	var line = Line2D.new()
	
	# Note: we do not need a "map scale"
	# the rails are probably 100s of meters long, so that would make a very
	# large map, but! line points are measured in pixels. No problem! :)
	var points = build_rail(rail)
	line.points = points
	line.width = 1.435
	line.antialiased = true
	line.name = rail.name
	
	if train_world.player.baked_route.has(rail.name):
		line.default_color = Color.yellow
		$RouteLines.add_child(line)
		line.owner = $RouteLines
	else:
		line.default_color = Color.cornflower
		$RailLines.add_child(line)
		line.owner = $RailLines
	


# like Curve2D.tesselate 
# reduces the amount of points per rail
# if a rail is 100% straight, it will only output 2 points (start & end)
# the stronger the curve is, the more points it will output in that area
func tessellate_rail(rail):
	# TODO: not super complicated, but I cba right now
	pass


func build_rail(rail) -> Array:
	var points = []

	if rail.parRail != null:
		var length = rail.parRail.length
		var point_count = int(length / LINE_POINT_INTERVAL) + 1
		# add point count many points along track
		for i in range(0,point_count):
			var rail_pos = rail.get_shifted_pos_at_RailDistance(i*LINE_POINT_INTERVAL, rail.distanceToParallelRail)
			points.append(Vector2(rail_pos.x, rail_pos.z))
		# add end point
		var rail_pos = rail.get_shifted_pos_at_RailDistance(length, rail.distanceToParallelRail)
		points.append(Vector2(rail_pos.x, rail_pos.z))
	else:
		var length = rail.length
		var point_count = int(length / LINE_POINT_INTERVAL) + 1
		# add point count many points along track
		for i in range(0,point_count):
			var rail_transform = rail.get_transform_at_rail_distance(i*LINE_POINT_INTERVAL)
			points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
		# add end point
		var rail_transform = rail.get_transform_at_rail_distance(rail.length)
		points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
	return points
