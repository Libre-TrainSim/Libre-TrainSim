class_name ChunkManager
extends Node

signal chunks_finished_loading   # emitted when chunks finished loading (loaded_chunks == chunks_to_load)
signal _thread_finished_loading

const world_origin_shift_treshold: int = 5_000  # if further than this from origin, recenter world origin
const chunk_size: int = 1000  # extend of a chunk in all directions
const chunk_prefab := preload("res://Data/Modules/chunk_prefab.tscn")

var world = null
var editor = null
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


func position_to_chunk(position: Vector3) -> Vector3:
	position = position - world_origin
	return Vector3(int(position.x / chunk_size), 0, int(position.z / chunk_size))


func chunk_to_position(chunk: Vector3) -> Vector3:
	return chunk * chunk_size + world_origin


# needed for serialisation
static func chunk_to_string(chunk: Vector3) -> String:
	return "chunk_%d_%d" % [chunk.x, chunk.z]


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
	assert(world != null)
	if Root.Editor:
		editor = find_parent("Editor")
		assert(editor != null)

	_thread_semaphore = Semaphore.new()
	_chunk_mutex = Mutex.new()
	_saving_mutex = Mutex.new()
	connect("_thread_finished_loading", self, "_finish_chunk_loading")

	# backwards compat.
	if not world.has_node("Chunks"):
		var chunks_node := Spatial.new()
		chunks_node.name = "Chunks"
		world.add_child(chunks_node)
		chunks_node.owner = world

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


func _process(_delta: float):
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
	Root.world_origin_shifted(delta)
	_chunk_mutex.unlock()


func _save_chunks(chunks: Array):
	_chunk_mutex.lock()
	for chunk in chunks:
		if chunk in loaded_chunks:
			_save_chunk(chunk)
	_chunk_mutex.unlock()


func _save_chunk(chunk_pos: Vector3):
	assert(Root.Editor)

	# get chunks dir
	var base_path = editor.current_track_path.get_base_dir().plus_file("chunks")
	var dir = Directory.new()
	if not dir.dir_exists(base_path):
		dir.make_dir_recursive(base_path)

	# find the chunk
	var chunk: Chunk = world.get_node("Chunks").get_node_or_null(chunk_to_string(chunk_pos))
	if not is_instance_valid(chunk):
		Logger.err("Trying to save chunk that has been free()'d: %s" % chunk_to_string(chunk_pos), self)
		return

	# add rails to chunk
	chunk.rails = []
	chunk.is_empty = true
	for rail in world.get_node("Rails").get_children():
		if not rail.has_meta("chunk_pos"):
			rail.set_meta("chunk_pos", position_to_chunk(rail.global_transform.origin))
		if rail.get_meta("chunk_pos") == chunk_pos:
			chunk.rails.append(rail.name)
			chunk.is_empty = false

	# don't save empty chunks
	if chunk.is_empty:
		return

	# write chunk to disk
	chunk._prepare_saving()

	var packed_chunk = PackedScene.new()
	if packed_chunk.pack(chunk) != OK:
		Logger.err("Could not pack chunk to tscn!", self)
		return

	var file = base_path.plus_file(chunk.name) + ".tscn"
	if ResourceSaver.save(file, packed_chunk) != OK:
		Logger.err("Could not save chunk tscn!", self)
		return

	# delete the chunk from scene tree, it's reloaded later
	chunk.queue_free()

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
	_unload_old_chunks(true) # this also saves the chunks :)


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
func _add_chunk_to_scene_tree(chunk: Chunk):
	if world.get_node("Chunks").has_node(chunk.name):
		Logger.err("Chunk already loaded: %s" % chunk.name, self)
		chunk.queue_free()
		return

	world.get_node("Chunks").add_child(chunk)
	chunk.owner = world
	chunk._on_world_origin_shifted(world_origin)
	chunk.update()


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

	# unload rails (they aren't chunked)
	for rail in world.get_node("Rails").get_children():
		if not rail.has_meta("chunk_pos"):
			rail.set_meta("chunk_pos", position_to_chunk(rail.global_transform.origin))
		if rail.get_meta("chunk_pos") in chunks_to_unload:
			rail.unload_visible_instance()

	# remove unloaded chunks
	for chunk_pos in chunks_to_unload:
		var chunk = world.get_node("Chunks").get_node_or_null(chunk_to_string(chunk_pos))
		if is_instance_valid(chunk):
			chunk.queue_free()
		loaded_chunks.erase(chunk_pos)

	_chunk_mutex.unlock()


# handle loading chunks from disk on a separate thread to avoid lags
func _chunk_loader_thread(_void):
	var dir = Directory.new()
	if dir.open("res://") != OK:
		Logger.err("Cannot open resource directory.", self)
		return

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

			var chunk_file := ""
			if Root.Editor:
				chunk_file = editor.current_track_path.get_base_dir().plus_file("chunks")
			else:
				chunk_file = Root.current_track.get_base_dir().plus_file("chunks")
			chunk_file = chunk_file.plus_file(chunk_to_string(chunk_pos)) + ".tscn"

			var chunk: Chunk
			if dir.file_exists(chunk_file):
				chunk = load(chunk_file).instance() as Chunk
			else:
				# load empty chunk
				chunk = chunk_prefab.instance() as Chunk
				chunk.name = chunk_to_string(chunk_pos)
				chunk.chunk_position = chunk_pos

			call_deferred("_add_chunk_to_scene_tree", chunk)

		_chunk_mutex.unlock()
		_saving_mutex.unlock()
		call_deferred("_emit_thread_finished_loading")


func _emit_thread_finished_loading() -> void:
	emit_signal("_thread_finished_loading")
