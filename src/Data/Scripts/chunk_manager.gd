class_name ChunkManager
extends Node

signal chunks_finished_loading   # emitted when chunks finished loading (loaded_chunks == chunks_to_load)
signal _thread_finished_loading

const world_origin_shift_treshold: int = 5_000  # if further than this from origin, recenter world origin
const chunk_size: int = 1000  # extend of a chunk in all directions
const GRASS_HEIGHT: float = -0.5

var grass_mesh: PlaneMesh

var world
var world_origin := Vector3(0, 0, 0)

var loaded_chunks := []  # chunks that are *actually* loaded
var chunks_to_load := []  # chunks that should be loaded
var are_chunks_loaded: bool = false setget , get_are_chunks_loaded

var active_chunk = null  # chunk the player is currently in (Vector3)

# whatever node tells us *which* chunk to load. Usually player. Maybe editor camera.
var position_provider: Spatial = null

var _thread: Thread
var _thread_semaphore: Semaphore
var _chunk_mutex: Mutex
var _saving_mutex: Mutex
var _kill_thread := false
var _jsavemodule

func position_to_chunk(position: Vector3) -> Vector3:
	position = position - world_origin
	return Vector3(int(position.x / chunk_size), 0, int(position.z / chunk_size))


func chunk_to_position(chunk: Vector3) -> Vector3:
	return chunk * chunk_size + world_origin


# needed for serialisation
func chunk_to_string(chunk: Vector3) -> String:
	return "%s,%s" % [chunk.x, chunk.z]


func is_position_in_loaded_chunk(position: Vector3) -> bool:
	return is_chunk_loaded(position_to_chunk(position))


func is_chunk_loaded(chunk: Vector3) -> bool:
	return chunk in loaded_chunks


func get_are_chunks_loaded() -> bool:
	return chunks_to_load == loaded_chunks


func get_3x3_chunks(around: Vector3):
	return [
		Vector3(around.x - 1, 0, around.z),
		Vector3(around.x - 1, 0, around.z - 1),
		Vector3(around.x - 1, 0, around.z + 1),
		Vector3(around.x + 1, 0, around.z),
		Vector3(around.x + 1, 0, around.z - 1),
		Vector3(around.x + 1, 0, around.z + 1),
		Vector3(around.x, 0, around.z),
		Vector3(around.x, 0, around.z - 1),
		Vector3(around.x, 0, around.z + 1),
	]


func _ready():
	grass_mesh = PlaneMesh.new()
	grass_mesh.size = Vector2(500, 500)
	grass_mesh.material = preload("res://Resources/Materials/Grass_new.tres")

	assert(world != null)

	_jsavemodule = world.j_save_module

	_thread_semaphore = Semaphore.new()
	_chunk_mutex = Mutex.new()
	_saving_mutex = Mutex.new()
	connect("_thread_finished_loading", self, "_finish_chunk_loading")

	# backwards compat.
	if not world.has_node("Landscape"):
		var landscape := Spatial.new()
		landscape.name = "Landscape"
		world.add_child(landscape)
		landscape.owner = world

	_thread = Thread.new()
	_thread.start(self, "_chunk_loader_thread")


func _halt_thread():
	_chunk_mutex.lock()
	_kill_thread = true
	_chunk_mutex.unlock()
	_thread_semaphore.post()
	_thread.wait_to_finish()


# kill thread when ChunkManager gets destroyed
func _exit_tree():
	_halt_thread()


func _process(delta: float):
	assert(world != null)

	# get position of active camera
	position_provider = get_viewport().get_camera()
	if position_provider == null:
		return

	# handle world origin
	var position = position_provider.global_transform.origin
	if position.length() > world_origin_shift_treshold:
		_shift_world_origin_to(-position_to_chunk(position)*chunk_size)

	# handle chunks
	var chunk_position = position_to_chunk(position)
	if chunk_position != active_chunk:
		_chunk_mutex.lock()
		active_chunk = chunk_position
		chunks_to_load = get_3x3_chunks(active_chunk)
		_chunk_mutex.unlock()
		_thread_semaphore.post()


func _shift_world_origin_to(position: Vector3):
	_chunk_mutex.lock()
	var delta: Vector3 = position - world_origin
	world_origin = position
	Root.emit_signal("world_origin_shifted", delta)
	_chunk_mutex.unlock()


func _save_chunks(chunks: Array):
	_chunk_mutex.lock()
	for chunk in chunks:
		if chunk in loaded_chunks:
			_save_chunk(chunk)
	_chunk_mutex.unlock()


func _save_chunk(chunk_pos: Vector3):
	var chunk := {
		"position": chunk_pos,
		"Rails": [],
		"Buildings": {},
		"TrackObjects": {}
	}

	for rail in world.get_node("Rails").get_children():
		var rail_pos = position_to_chunk(rail.global_transform.origin)
		if rail_pos == chunk_pos:
			chunk.Rails.append(rail.name)

	for building in world.get_node("Buildings").get_children():
		var building_pos = position_to_chunk(building.global_transform.origin)
		if building_pos == chunk_pos:
			var surface_arr := []
			for i in range(building.get_surface_material_count()):
				surface_arr.append(building.get_surface_material(i))
			chunk.Buildings[building.name] = {
				"name": building.name,
				"transform": building.transform,
				"mesh_path": building.mesh.resource_path,
				"surfaceArr": surface_arr
			}

	for track_object in world.get_node("TrackObjects").get_children():
		var to_pos = position_to_chunk(track_object.global_transform.origin)
		if to_pos == chunk_pos:
			chunk.TrackObjects[track_object.name] = {
				"name": track_object.name,
				"transform": track_object.transform,
				"data": track_object.get_data()
			}

	_jsavemodule.save_value(chunk_to_string(chunk_pos), null)
	_jsavemodule.save_value(chunk_to_string(chunk_pos), chunk)

	world.world_origin_on_last_save = world_origin

	Logger.log("Saved Chunk " + chunk_to_string(chunk_pos))


func _get_all_chunks() -> Array:
	var _all_chunks := []
	for rail in world.get_node("Rails").get_children():
		var pos: Vector3 = position_to_chunk(rail.global_transform.origin)
		for chunk in get_3x3_chunks(pos):
			_all_chunks.append(chunk)
	_all_chunks = jEssentials.remove_duplicates(_all_chunks)
	return _all_chunks


# needed for editor only
func save_and_unload_all_chunks():
	assert(Root.Editor)

	_saving_mutex.lock()
	chunks_to_load = []
	_unload_old_chunks(true)


# this is the missing unlock from `save_and_unload_all_chunks()` - needed for Editor purposes
func resume_chunking():
	chunks_to_load = get_3x3_chunks(active_chunk)
	_thread_semaphore.post()
	_saving_mutex.unlock()


# do finishing touches sync. on main thread (tree is not thread safe!)
func _finish_chunk_loading():
	_chunk_mutex.lock()
	var new_chunks = without(chunks_to_load, loaded_chunks)
	for rail in world.get_node("Rails").get_children():
		var rail_pos = position_to_chunk(rail.global_transform.origin)
		if rail_pos in new_chunks:
			rail._update()
	_chunk_mutex.unlock()

	# append, but remove duplicates
	append_deduplicated(loaded_chunks, chunks_to_load)

	emit_signal("chunks_finished_loading")
	_unload_old_chunks()


# called deferred from Thread
func _add_node_to_scene_tree(parent: String, instance: Spatial):
	if world.get_node(parent).get_node_or_null(instance.name) != null:
		Logger.err("Tried to ad an object to world, which is already loaded. Skip loading this object.", instance)
		return

	world.get_node(parent).add_child(instance)
	instance.owner = world
	instance.translation += world_origin
	if instance.has_method("update"):
		instance.update()


func append_deduplicated(A: Array, B: Array):
	for b in B:
		if not b in A:
			A.append(b)


func without(A: Array, B: Array) -> Array:
	var retval = A.duplicate()
	for b in B:
		retval.erase(b)
	return retval


# delete old nodes from main thread (tree is not thread safe!)
func _unload_old_chunks(all: bool = false):
	_chunk_mutex.lock()

	# chunks_to_unload = all chunks further away than treshold
	var chunks_to_unload = loaded_chunks.duplicate()
	if not all:
		for chunk in loaded_chunks:
			if active_chunk.distance_to(chunk) <= ProjectSettings["game/gameplay/chunk_unload_distance"]:
				chunks_to_unload.erase(chunk)

	if Root.Editor:
		_save_chunks(chunks_to_unload)

	for rail in world.get_node("Rails").get_children():
		var rail_pos = position_to_chunk(rail.global_transform.origin)
		if rail_pos in chunks_to_unload:
			rail.unload_visible_instance()

	for group in ["TrackObjects", "Buildings", "Landscape"]:
		var parent = world.get_node(group)
		for child in parent.get_children():
			if all or (child.get_meta("chunk_pos") in chunks_to_unload):
				child.free()

	# remove unloaded chunks
	for chunk in chunks_to_unload:
		loaded_chunks.erase(chunk)
	_chunk_mutex.unlock()


# handle loading chunks from disk on a separate thread to avoid lags
func _chunk_loader_thread(_void):
	while true:
		_thread_semaphore.wait()
		#yield(get_tree(), "idle_frame")  # uncomment this for debugging

		_saving_mutex.lock()
		_chunk_mutex.lock()
		if _kill_thread:
			_chunk_mutex.unlock()
			return

		for chunk_pos in chunks_to_load:
			if chunk_pos in loaded_chunks:
				continue
			var chunk: Dictionary = _jsavemodule.get_value(chunk_to_string(chunk_pos), {"empty": true})

			_generate_landscape(chunk, chunk_pos)

			if chunk.has("empty"):
				continue

			## Buildings:
			if chunk.has("Buildings"):
				for building in chunk["Buildings"].values():
					if not building.has_all(["name", "mesh_path", "transform", "surfaceArr"]):
						Logger.warn("Building is missing some keys!", self)
						continue

					var instance := MeshInstance.new()
					instance.set_script(load("res://Data/Scripts/world_object.gd"))
					instance.name = building.name
					instance.set_mesh(load(building.mesh_path))
					instance.transform = building.transform
					var surface_arr: Array = building.get("surfaceArr", [])
					for i in range (surface_arr.size()):
						instance.set_surface_material(i, surface_arr[i])
					instance.set_meta("chunk_pos", chunk_pos)
					var old_script = instance.get_script()
					instance.set_script(preload("res://Data/Scripts/aabb_to_collider.gd"))
					instance.target = NodePath(".")
					instance.generate_collider()
					instance.set_script(old_script)
					call_deferred("_add_node_to_scene_tree", "Buildings", instance)

			## TrackObjects:
			var track_object_prefab: PackedScene = preload("res://Data/Modules/TrackObjects.tscn")
			if chunk.has("TrackObjects"):
				for track_object in chunk["TrackObjects"].values():
					if not track_object.has_all(["name", "data", "transform"]):
						Logger.warn("TrackObject is missing some keys!", self)
						continue

					var instance: Spatial = track_object_prefab.instance()
					instance.name = track_object.name
					instance.set_data(track_object.data)
					instance.transform = track_object.transform
					instance.set_meta("chunk_pos", chunk_pos)
					call_deferred("_add_node_to_scene_tree", "TrackObjects", instance)

		_chunk_mutex.unlock()
		_saving_mutex.unlock()
		call_deferred("emit_signal", "_thread_finished_loading")


func _generate_landscape(chunk, chunk_pos):
	var has_landscape: bool = chunk.has("Landscape") and not chunk["Landscape"].empty()
	if not has_landscape:
		for v in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var mi = MeshInstance.new()
			mi.set_script(load("res://Data/Scripts/world_object.gd"))
			mi.mesh = grass_mesh
			mi.translation = (chunk_pos * chunk_size) + (Vector3(250 * v.x, GRASS_HEIGHT, 250 * v.y))
			mi.set_meta("chunk_pos", chunk_pos)
			call_deferred("_add_node_to_scene_tree", "Landscape", mi)
	else:
		# TODO: load landscape (heightmap, whatever), not implemented yet
		pass
