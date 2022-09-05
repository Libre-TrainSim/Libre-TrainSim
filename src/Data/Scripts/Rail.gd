extends WorldObject

## Documentation Notes:
# Please be aware of the parallel Mode:
# If 'parallel_rail_name != ""' All local train Settings apart from 'railType' and 'distance_to_parallel_rail' are deprecated. The Rail gets the rest information from parallel rail.


export (String, FILE, "*.tscn,*.scn") var rail_type_path: String = "res://Resources/RailTypes/Default.tscn"
export (float) var length: float
export (float) var radius: float
export (float) var build_distance: float = 1
export (int) var visible_segments: int
export (bool) var manual_moving: bool = false

var track_objects: Array = []

const MAX_LENGTH: float = 1000.0

export (float) var start_rot: float  # Radians
export (float) var end_rot: float  # Radians
export (Vector3) var start_pos: Vector3
export (Vector3) var end_pos: Vector3


## Steep
export (float) var start_slope: float = 0  # % (meters / 100 meters)
export (float) var end_slope: float = 0  # % (meters / 100 meters)

export (float) var start_tend: float = 0
export (float) var tend1_pos: float = -1
export (float) var tend1: float = 0
export (float) var tend2_pos: float = 0
export (float) var tend2: float = 0
export (float) var end_tend: float
export (bool) var automatic_tend: bool = false

export (String) var parallel_rail_name: String = ""
export (float) var distance_to_parallel_rail: float = 0

export (bool) var has_overhead_line: bool = true
var overhead_line_height1: float = 5.3
var overhead_line_height2: float = 6.85
var overhead_line_thickness: float = 0.02
var overhead_line_height_factor: float = 0.9

var parallel_rail: Spatial

onready var world: Node = find_parent("World")
onready var buildings: Spatial = world.get_node("Buildings")

var attached_signals: Array = []


func _ready() -> void:
	update_parallel_rail_settings()
	manual_moving = false
	_update()
	if not Root.Editor:
		$Beginning.queue_free()
		$Ending.queue_free()
		$Mid.queue_free()


func _exit_tree() -> void:
	for track_object in track_objects:
		track_object.queue_free()


func rename(new_name: String) -> void:
	var _unused = Root.name_node_appropriate(self, new_name, get_parent())
	for track_object in track_objects:
		track_object.name = name + " " + track_object.description
		track_object.attached_rail = name


func update_parallel_rail_settings() -> void:
	if parallel_rail_name == "":
		return
	parallel_rail = get_parent().get_node(parallel_rail_name)
	if parallel_rail == null:
		Logger.err("Cant find parallel rail. Updating Rail canceled..", self)
		return

	if parallel_rail.radius == 0:
		radius = 0
		length = parallel_rail.length
	else:
		radius = parallel_rail.radius + distance_to_parallel_rail
		length = parallel_rail.length * ((radius)/(parallel_rail.radius))
	translation = parallel_rail.get_shifted_pos_at_distance(0, distance_to_parallel_rail) ## Hier verstehe ich das minus nicht
	rotation.y = parallel_rail.rotation.y


func _update() -> void:
	var rail_type_node: Spatial = load(rail_type_path).instance()

	build_distance = rail_type_node.build_distance
	overhead_line_height1 = rail_type_node.overhead_line_height1
	overhead_line_height2 = rail_type_node.overhead_line_height2
	overhead_line_thickness = rail_type_node.overhead_line_thickness
	overhead_line_height_factor = rail_type_node.overhead_line_height_factor

	if parallel_rail_name.empty():
		update_automatic_tend()
	else:
		update_parallel_rail_settings()

	if length > MAX_LENGTH:
		length = MAX_LENGTH
		Logger.warn(self.name + ": The max length is " + String(MAX_LENGTH) + ". Shrinking the length to maximal length.", self)

	visible_segments = int(length / build_distance) + 1

	# Ensure visible Instance:
	visible = true
	var multimesh_instance: MultiMeshInstance = get_node_or_null("MultiMeshInstance")
	if multimesh_instance == null:
		multimesh_instance = MultiMeshInstance.new()
		multimesh_instance.name = "MultiMeshInstance"
		add_child(multimesh_instance)
		multimesh_instance.set_owner(self)

	if multimesh_instance.multimesh == null or not multimesh_instance.multimesh.has_meta("is_unique"):
		multimesh_instance.multimesh = MultiMesh.new()
		multimesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh_instance.multimesh.set_meta("is_unique", true)

	multimesh_instance.multimesh.instance_count = visible_segments

	if multimesh_instance.multimesh.mesh == null:
		multimesh_instance.multimesh.mesh = rail_type_node.get_child(0).mesh
		for i in range(rail_type_node.get_child(0).get_surface_material_count()):
			multimesh_instance.multimesh.mesh.surface_set_material(i, rail_type_node.get_child(0).get_surface_material(i))

	for i in range(visible_segments):
		multimesh_instance.multimesh.set_instance_transform(i, get_local_transform_at_distance(i*build_distance))

	if has_overhead_line:
		update_overhead_line(calculate_overhead_line_mesh())
	else:
		# Fix overhead line being visible on load despite being disabled
		var that_overhead_line = get_node_or_null("OverheadLine")
		if that_overhead_line != null:
			that_overhead_line.queue_free()

	if Root.Editor and visible:
		$Ending.transform = get_local_transform_at_distance(length)
		$Mid.transform = get_local_transform_at_distance(length/2.0)
		update_connection_arrows()
		for track_object in track_objects:
			track_object.update()

	rail_type_node.queue_free()


func unload_visible_instance() -> void:
	visible = false
	if get_node_or_null("MultiMeshInstance") != null:
		$MultiMeshInstance.queue_free()
	if get_node_or_null("OverheadLine") != null:
		$OverheadLine.queue_free()
	for track_object in track_objects:
		if is_instance_valid(track_object):
			track_object.queue_free()
	track_objects.clear()


func update() -> void:
	update_positions_and_rotations()
	if not visible:
		unload_visible_instance()
	else:
		_update()


func get_track_object(track_object_name : String) -> Spatial: # (Searches for the description of track objects
	for track_object in track_objects:
		if not is_instance_valid(track_object):
			continue
		if track_object.description == track_object_name:
			return track_object
	return null



# local to "Rails" node
func get_transform_at_distance(distance: float) -> Transform:
	var locTransform: Transform = get_local_transform_at_distance(distance)
	return Transform(locTransform.basis.rotated(Vector3(0,1,0), rotation.y) ,translation + locTransform.origin.rotated(Vector3(0,1,0), rotation.y))


# completely global
func get_global_transform_at_distance(distance: float) -> Transform:
	var locTransform: Transform = get_local_transform_at_distance(distance)
	var global_rot: Vector3 = global_transform.basis.get_euler()
	var global_pos: Vector3 = global_transform.origin
	return Transform(locTransform.basis.rotated(Vector3(0,1,0), global_rot.y), global_pos + locTransform.origin.rotated(Vector3(0,1,0), global_rot.y))

# local to this rail
func get_local_transform_at_distance(distance: float) -> Transform:
	if parallel_rail_name == "":
		return Transform( \
			Basis() \
				.rotated(Vector3(1,0,0), get_tend_at_distance(distance)) \
				.rotated(Vector3(0,0,1), get_height_rot(distance)) \
				.rotated(Vector3(0,1,0), circle_get_rad(radius, distance)), \
			 get_local_pos_at_distance(distance) \
		)
	else:
		if parallel_rail == null:
			update_parallel_rail_settings()
		var parDistance: float = distance/length * parallel_rail.length
		return Transform(\
			Basis()\
				.rotated(Vector3(1,0,0), parallel_rail.get_tend_at_distance(parDistance))\
				.rotated(Vector3(0,0,1), parallel_rail.get_height_rot(parDistance))\
				.rotated(Vector3(0,1,0), parallel_rail.circle_get_rad(parallel_rail.radius, parDistance)),\
			parallel_rail.get_shifted_local_pos_at_distance(parDistance, distance_to_parallel_rail)\
			+ ((parallel_rail.start_pos-start_pos).rotated(Vector3(0,1,0), -rotation.y))\
		)


func register_signal(name: String, distance: float) -> void:
	Logger.vlog("Signal " + name + " registered at rail.")
	attached_signals.append({"name": name, "distance": distance})


func get_pos_at_distance(distance: float) -> Vector3:
	var circlePos: Vector2 = circle_get_pos(radius, distance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y)).rotated(Vector3(0,1,0), start_rot) + start_pos


func get_local_pos_at_distance(distance: float) -> Vector3:
	var circlePos: Vector2 = circle_get_pos(radius, distance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y))


func get_rad_at_distance(distance: float) -> float:
	return circle_get_rad(radius, distance) + start_rot


func get_local_rad_at_distance(distance: float) -> float:
	return circle_get_rad(radius, distance)


# completely global
func get_shifted_global_pos_at_distance(distance: float, shift: float) -> Vector3:
	var local_pos = get_shifted_local_pos_at_distance(distance, shift)
	var global_rot = global_transform.basis.get_euler()
	var global_pos = global_transform.origin
	return global_pos + local_pos.rotated(Vector3(0,1,0), global_rot.y)


# local to "Rails" node
func get_shifted_pos_at_distance(distance: float, shift: float) -> Vector3:
	return get_shifted_local_pos_at_distance(distance, shift).rotated(Vector3(0,1,0),rotation.y) + start_pos


# local to this rail
func get_shifted_local_pos_at_distance(distance: float, shift: float) -> Vector3:
	var new_radius: float = radius + shift
	var newDistance: float = distance
	if radius == 0:
		new_radius = 0
	else:
		newDistance = distance * (new_radius/radius)
	var circlePos: Vector2 = circle_get_pos(new_radius, newDistance)
	return(Vector3(circlePos.x, get_height(distance), -circlePos.y+shift))


func calculate_from_start_end(new_end_pos: Vector3) -> void:
	var end = (new_end_pos - start_pos).rotated(Vector3.UP, -start_rot)
	end.z = -end.z  # fix because in godot -z is forward, not +z
	end.x = max(end.x, 0)  # do not allow negative x, max angle is 180°!

	if abs(end.z) < 0.01:
		radius = 0
		length = end.length()
		update()
		return

	# m = end.z / end.x
	# m2 = - 1 / m
	# b = z - m2 * x
	var b = end.z + (end.x / end.z) * end.x

	radius = b/2
	# minimum radius! TODO: sensible value?
	if radius < 0 and radius > -10:
		radius = -10
	elif radius > 0 and radius < 10:
		radius = 10

	var angle = 2 * asin(end.length() / b)  # asin( (len/2) / r )
	length = radius * angle
	end_rot = start_rot + angle
	update()


func circle_get_pos(r: float, dist: float) -> Vector2:
	if r == 0:
		return Vector2(dist, 0)
	## Calculate: Coordinate:
	var rad = circle_get_rad(r, dist)
	var middleOfCircle = Vector2(0, r)
	var a = cos(rad) * r
	var b = sin(rad) * r
	return middleOfCircle + Vector2(b, -a)  ## See HowACircleIsCalculated.pdf in github repository


func circle_get_rad(r: float, distance: float) -> float:
	if r == 0:
		return 0.0
	return distance / r


#### Height Functions:
func get_height(distance: float) -> float:
	if is_instance_valid(parallel_rail):
		var new_radius: float = radius - distance_to_parallel_rail
		if radius == 0:
			new_radius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * (new_radius/radius)
		return parallel_rail.get_height(newDistance)
	var start_gradient: float = atan(start_slope/100)
	var end_gradient: float = atan(end_slope/100)

	var basicHeight: float = tan(start_gradient) * distance
	if end_gradient - start_gradient == 0:
		return basicHeight
	var heightRadius: float = length/(end_gradient - start_gradient)
	return circle_get_pos(heightRadius, distance).y + basicHeight


func get_height_rot(distance: float) -> float: ## Get Slope
	if is_instance_valid(parallel_rail):
		var new_radius = radius - distance_to_parallel_rail
		if radius == 0:
			new_radius = 0
		var newDistance = distance
		if radius != 0:
			newDistance = distance * (new_radius / radius)
		return parallel_rail.get_height_rot(newDistance)

	var start_gradient = atan(start_slope/100)
	var end_gradient = atan(end_slope/100)
	var basicRot = start_gradient
	if end_gradient - start_gradient == 0:
		return basicRot
	var heightRadius = length / (end_gradient - start_gradient)
	return circle_get_rad(heightRadius, distance) + basicRot


# I do not understand this calculation, so I will leave it as is and use deg2rad() instead...
func get_tend_at_distance(distance: float) -> float:
	if is_instance_valid(parallel_rail):
		var new_radius: float = radius - distance_to_parallel_rail
		var newDistance: float = distance
		if radius == 0:
			new_radius = 0
		else:
			newDistance = distance * (new_radius/radius)
		return parallel_rail.get_tend_at_distance(newDistance)

	if distance >= tend1_pos and distance < tend2_pos:
		return deg2rad(-(tend1 + (tend2-tend1) * (distance - tend1_pos)/(tend2_pos - tend1_pos)))

	if distance <= tend1_pos:
		return deg2rad(-(start_tend + (tend1-start_tend) * (distance)/(tend1_pos)))

	if tend2_pos > 0 and distance >= tend2_pos:
		return deg2rad(-(tend2 + (end_tend-tend2) * (distance -tend2_pos)/(length-tend2_pos)))

	return deg2rad(-(start_tend + (end_tend-start_tend) * (distance/length)))


func get_tendSlopeData() -> Dictionary:
	var d: Dictionary = {}
	d.start_slope = start_slope
	d.end_slope = end_slope
	d.start_tend = start_tend
	d.end_tend = end_tend
	d.tend1_pos = tend1_pos
	d.tend1 = tend1
	d.tend2_pos = tend2_pos
	d.tend2 = tend2
	d.automatic_tend = automatic_tend
	return d

func set_tendSlopeData(d: Dictionary) -> void:
	start_slope = d.start_slope
	end_slope = d.end_slope
	start_tend = d.start_tend
	end_tend = d.end_tend
	tend1_pos = d.tend1_pos
	tend1 = d.tend1
	tend2_pos = d.tend2_pos
	tend2 = d.tend2
	automatic_tend = d.automatic_tend


var automatic_point_distance: float = 50
func update_automatic_tend() -> void:
	if automatic_tend and radius != 0 and length > 3*automatic_point_distance:
		tend1_pos = automatic_point_distance
		tend2_pos = length -automatic_point_distance
		var tendency := 300.0/radius * 5.0
		tend1 = tendency
		tend2 = tendency
	elif automatic_tend and radius == 0:
		tend1 = 0
		tend2 = 0


###############################################################################
## Overhad Line
var vertices: PoolVector3Array
var indices: PoolIntArray

func update_overhead_line(mesh: ArrayMesh) -> void:
	if mesh == null and has_node("OverheadLine"):
		get_node("OverheadLine").queue_free()
		return

	if get_node_or_null("OverheadLine") == null:
		var overhead_line_mesh_instance: MeshInstance = MeshInstance.new()
		overhead_line_mesh_instance.name = "OverheadLine"
		self.add_child(overhead_line_mesh_instance)
		overhead_line_mesh_instance.owner = self
	$OverheadLine.mesh = mesh


func calculate_overhead_line_mesh() -> ArrayMesh:
	vertices = PoolVector3Array()
	indices = PoolIntArray()

	## Get Pole Points:
	var pole_positions: Array = []
	pole_positions.append(0)

	for track_object in track_objects:
		if not is_instance_valid(track_object):
			continue
		if track_object.description.begins_with("Pole"):
			var pos = 0
			if track_object.on_rail_position == 0:
				pos += track_object.distanceLength
			while pos <= track_object.length:
				pole_positions.append(pos + track_object.on_rail_position)
				pos += track_object.distanceLength
			if not track_object.placeLast and pole_positions.size() > 1:
				pole_positions.remove(pole_positions.size()-1)
			## Maybe here comes a break in. (If we only want to search for one trackobkject which begins with "pole"
	pole_positions.append(length)
	pole_positions = jEssentials.remove_duplicates(pole_positions)
	for i in range (pole_positions.size()-2):
		var _unused = build_overhead_line_segment(pole_positions[i], pole_positions[i+1])

	if pole_positions[pole_positions.size()-2] != length:
		var _unused = build_overhead_line_segment(pole_positions[pole_positions.size()-2], length)

	var mesh: ArrayMesh = ArrayMesh.new()

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, preload("res://Resources/Materials/Overhead_Line.tres"))
	return mesh


func build_overhead_line_segment(start: float, end: float) -> Dictionary:
	var start_pos = get_local_pos_at_distance(start)+Vector3(0,overhead_line_height1,0)
	var end_pos = get_local_pos_at_distance(end)+Vector3(0,overhead_line_height1,0)
	var direct_vector = (end_pos-start_pos).normalized()
	var direct_distance = start_pos.distance_to(end_pos)

	create_3D_line(get_local_pos_at_distance(start)+Vector3(0,overhead_line_height1,0), get_local_pos_at_distance(end)+Vector3(0,overhead_line_height1,0), overhead_line_thickness)

	var segments = int(direct_distance/10)
	if segments == 0:
		segments = 1
	var segment_distance = direct_distance/segments
	var current_pos1 = start_pos
	var current_pos2 = start_pos + direct_vector*segment_distance
	for i in range(segments):
		create_3D_line(current_pos1+Vector3(0,overhead_line_height2-overhead_line_height1-sin(i*segment_distance/direct_distance*PI)*overhead_line_height_factor,0), current_pos2+Vector3(0,overhead_line_height2-overhead_line_height1-sin((i+1)*segment_distance/direct_distance*PI)*overhead_line_height_factor,0), overhead_line_thickness)

		var line_height_change_at_half = sin((i+1)*segment_distance/direct_distance*PI)*overhead_line_height_factor - (sin((i+1)*segment_distance/direct_distance*PI)*overhead_line_height_factor - sin(i*segment_distance/direct_distance*PI)*overhead_line_height_factor)/2.0
		create_3D_line_up(current_pos1+direct_vector*segment_distance/2, current_pos1+direct_vector*segment_distance/2+Vector3(0,overhead_line_height2-overhead_line_height1-line_height_change_at_half,0), overhead_line_thickness)
		current_pos1+=direct_vector*segment_distance
		current_pos2+=direct_vector*segment_distance
	return {"vertices" : vertices, "indices" : indices}


func create_3D_line(start: Vector3, end: Vector3, thickness: float) -> void:
	var x = vertices.size()
	vertices.push_back(start + Vector3(0,thickness,0))
	vertices.push_back(start + Vector3(0,0,-thickness))
	vertices.push_back(start + Vector3(0,-thickness,0))
	vertices.push_back(start + Vector3(0,0,thickness))

	vertices.push_back(end + Vector3(0,thickness,0))
	vertices.push_back(end + Vector3(0,0,-thickness))
	vertices.push_back(end + Vector3(0,-thickness,0))
	vertices.push_back(end + Vector3(0,0,thickness))

	var indices_array := PoolIntArray([0+x, 2+x, 4+x,  2+x, 4+x, 6+x,  1+x, 5+x, 7+x,  1+x, 7+x, 3+x])

	indices.append_array(indices_array)


func create_3D_line_up(start: Vector3, end: Vector3, thickness: float) -> void:
	var x: int = vertices.size()
	vertices.push_back(start + Vector3(thickness,0,0))
	vertices.push_back(start + Vector3(0,0,-thickness))
	vertices.push_back(start + Vector3(-thickness,0,0))
	vertices.push_back(start + Vector3(0,0,thickness))

	vertices.push_back(end + Vector3(thickness,0,0))
	vertices.push_back(end + Vector3(0,0,-thickness))
	vertices.push_back(end + Vector3(-thickness,0,0))
	vertices.push_back(end + Vector3(0,0,thickness))

	var indices_array := PoolIntArray([0+x, 2+x, 4+x,  2+x, 4+x, 6+x,  1+x, 5+x, 7+x,  1+x, 7+x, 3+x])

	indices.append_array(indices_array)


###############################################################################
func update_positions_and_rotations() -> void:
	start_pos = self.get_translation()
	start_rot = self.rotation.y
	end_rot = get_rad_at_distance(length)
	end_pos = get_pos_at_distance(length)


export(Array, String) var switch_part: Array = ["", ""]
# 0: is Rail at beginning part of switch? 1: is the rail at end part of switch if not
# It is saved the name of the other rail which is part of switch
func update_is_switch_part() -> void:
	switch_part = ["", ""]
	var found_rails_start: Array = []
	var found_rails_end: Array = []
	for rail in world.get_node("Rails").get_children():
		if rail == self:
			continue
		# Check for beginning
		if start_pos.distance_to(rail.start_pos) < 0.1 and Math.angle_distance_rad(start_rot, rail.start_rot) < deg2rad(1):
			found_rails_start.append(rail.name)
		elif start_pos.distance_to(rail.end_pos) < 0.1 and Math.angle_distance_rad(start_rot, rail.end_rot + PI) < deg2rad(1):
			found_rails_start.append(rail.name)
		#check for ending
		if end_pos.distance_to(rail.start_pos) < 0.1 and Math.angle_distance_rad(end_rot, rail.start_rot + PI) < deg2rad(1):
			found_rails_end.append(rail.name)
		elif end_pos.distance_to(rail.end_pos) < 0.1 and Math.angle_distance_rad(end_rot, rail.end_rot) < deg2rad(1):
			found_rails_end.append(rail.name)

	if found_rails_start.size() > 0:
		switch_part[0] = found_rails_start[0]
		pass

	if found_rails_end.size() > 0:
		switch_part[1] = found_rails_end[0]
		pass


var _connected_rails_at_beginning: Array = [] # Array of rail nodes
var _connected_rails_at_ending: Array = [] # Array of rail nodes
# The code of update_connections and update_is_switch_part can't be summarized, because
# we are searching for different rails in these functions. (Rotation of searched
# rails differs by 180 degrees)

# This function should be called before get_connected_rails_at_beginning()
# or get_connected_rails_at_ending once.
func update_connections() -> void:
	_connected_rails_at_beginning = []
	_connected_rails_at_ending = []
	for rail in world.get_node("Rails").get_children():
		if rail == self or start_pos.distance_to(rail.start_pos) > 1500:
			continue
		# Check for beginning
		if start_pos.distance_to(rail.start_pos) < 0.1 and Math.angle_distance_rad(start_rot, rail.start_rot + PI) < deg2rad(1):
			_connected_rails_at_beginning.append(rail)
		elif start_pos.distance_to(rail.end_pos) < 0.1 and Math.angle_distance_rad(start_rot, rail.end_rot) < deg2rad(1):
			_connected_rails_at_beginning.append(rail)
		#check for ending
		if end_pos.distance_to(rail.start_pos) < 0.1 and Math.angle_distance_rad(end_rot, rail.start_rot) < deg2rad(1):
			_connected_rails_at_ending.append(rail)
		elif end_pos.distance_to(rail.end_pos) < 0.1 and Math.angle_distance_rad(end_rot, rail.end_rot + PI) < deg2rad(1):
			_connected_rails_at_ending.append(rail)


# Returns array of rail nodes
func get_connected_rails_at_beginning() -> Array:
	return _connected_rails_at_beginning


# Returns array of rail nodes
func get_connected_rails_at_ending() -> Array:
	return _connected_rails_at_ending


func update_connection_arrows():
	_update_connection_arrows_not_recursive()
	for rail in _connected_rails_at_beginning:
		rail._update_connection_arrows_not_recursive()
	for rail in _connected_rails_at_ending:
		rail._update_connection_arrows_not_recursive()


var _last_calculation_of_update_connection_arrows = 0
func _update_connection_arrows_not_recursive():
	if _last_calculation_of_update_connection_arrows == get_tree().get_frame():
		return
	if not Root.Editor:
		return
	if world == null:
		# Hack (but what follows is so broken and hacky...)
		yield(self, "ready")
	update_connections()
	if not _connected_rails_at_beginning.empty():
		$Beginning/Beginning.material_override = preload("res://Data/Misc/Rail_Beginning_connected.tres")
	else:
		$Beginning/Beginning.material_override = preload("res://Data/Misc/Rail_Beginning_disconnected.tres")

	if not _connected_rails_at_ending.empty():
		$Ending/Ending.material_override = preload("res://Data/Misc/Rail_Ending_connected.tres")
	else:
		$Ending/Ending.material_override = preload("res://Data/Misc/Rail_Ending_disconnected.tres")

	_last_calculation_of_update_connection_arrows = get_tree().get_frame()
