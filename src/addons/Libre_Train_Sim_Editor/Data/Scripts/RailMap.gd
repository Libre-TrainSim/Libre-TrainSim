extends Viewport

const LINE_POINT_INTERVAL = 10 # 1 line point for every 10 meters of track

onready var train_world = find_parent("World")
onready var camera = $Camera2D

var follow_player = true
var overlay = false


func init_map():
	if train_world == null:
		print("RAILMAP: Could not find world! Despawning!")
		queue_free()
	
	var rails = train_world.get_node("Rails").get_children()
	for rail in rails:
		create_line2d_from_rail(rail)
	
	close_map()
	camera.current = true

func open_full_map():
	self.set_process(true)
	self.set_process_input(true)
	self.size = OS.window_size * 0.5
	overlay = false

func open_overlay_map():
	self.set_process(true)
	self.set_process_input(true)
	follow_player = true
	self.size = Vector2(360,640)
	overlay = true

func close_map():
	self.set_process(false)
	self.set_process_input(false)

var mouse_motion = Vector2(0,0)
func _input(event: InputEvent) -> void:
	if event.is_action("zoom_in"):
		var zoom = $Camera2D.zoom
		zoom.x = clamp(zoom.x*0.8, 0.05, 2.5)
		zoom.y = clamp(zoom.y*0.8, 0.05, 2.5)
		$Camera2D.zoom = zoom
		
	if event.is_action("zoom_out"):
		var zoom = $Camera2D.zoom
		zoom.x = clamp(zoom.x*1.25, 0.05, 2.5)
		zoom.y = clamp(zoom.y*1.25, 0.05, 2.5)
		$Camera2D.zoom = zoom
	
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
		camera.position += mouse_motion
		mouse_motion = Vector2(0,0)


func create_line2d_from_rail(rail):
	var line = Line2D.new()
	
	# Note: we do not need a "map scale"
	# the rails are probably 100s of meters long, so that would make a very
	# large map, but! line points are measured in pixels. No problem! :)
	var points = build_rail(rail)
	line.points = points
	
	line.antialiased = true
	line.name = rail.name
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
	var point_count = int(rail.length / LINE_POINT_INTERVAL) + 1
	
	# add point count many points along track
	for i in range(0,point_count):
		var rail_transform = rail.get_transform_at_rail_distance(i*LINE_POINT_INTERVAL)
		points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
		pass
	
	# add end point
	var rail_transform = rail.get_transform_at_rail_distance(rail.length)
	points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
	return points
