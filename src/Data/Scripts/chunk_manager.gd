class_name ChunkManager
extends Node

const world_origin_shift_treshold: int = 5_000  # if further than this from origin, recenter world origin
const chunk_size: int = 1000  # extend of a chunk in all directions

var loader: ChunkLoaderInteractive = null
var world = null
var editor = null
var world_origin := Vector3(0, 0, 0)

var active_chunk = null  # chunk the player is currently in (Vector3)

var rails_by_chunk := {}

var _dir: Directory = null


func position_to_chunk(position: Vector3) -> Vector3:
	position = position - world_origin
	return Vector3(round(position.x / chunk_size), 0, round(position.z / chunk_size))


func chunk_to_position(chunk: Vector3) -> Vector3:
	return chunk * chunk_size + world_origin


# needed for serialisation
static func chunk_to_string(chunk: Vector3) -> String:
	return "chunk_%d_%d" % [chunk.x, chunk.z]


static func string_to_chunk(chunk: String) -> Vector3:
	var idx1 = chunk.find('_') + 1
	var idx2 = chunk.find('_', idx1)

	var x = chunk.substr(idx1, idx2 - idx1)
	var z = chunk.substr(idx2+1)

	return Vector3(x, 0, z)


func get_chunks(around: Vector3, distance: int):
	var chunks := [
		chunk_to_string(Vector3(around.x, 0, around.z)),
	]
	for i in range(1, distance + 1):
		chunks.append_array([
			chunk_to_string(Vector3(around.x - i, 0, around.z)),
			chunk_to_string(Vector3(around.x - i, 0, around.z - i)),
			chunk_to_string(Vector3(around.x - i, 0, around.z + i)),
			chunk_to_string(Vector3(around.x + i, 0, around.z)),
			chunk_to_string(Vector3(around.x + i, 0, around.z - i)),
			chunk_to_string(Vector3(around.x + i, 0, around.z + i)),
			chunk_to_string(Vector3(around.x, 0, around.z - i)),
			chunk_to_string(Vector3(around.x, 0, around.z + i)),
		])
	return chunks


func is_position_in_loaded_chunk(position: Vector3):
	var chunk_pos = position_to_chunk(position)
	var chunk_name = chunk_to_string(chunk_pos)
	return world.get_node("Chunks").has_node(chunk_name)


func _ready():
	assert(world != null)
	if Root.Editor:
		editor = find_parent("Editor")
		assert(editor != null)
		_test_position_calc()

	_dir = Directory.new()
	if _dir.open("res://") != OK:
		Logger.err("Dir cannot open res://", self)

	_order_rails_by_chunk()

	loader = ChunkLoaderInteractive.new()
	loader.chunk_manager = self
	add_child(loader)

	# backwards compat.
	if not world.has_node("Chunks"):
		var chunks_node := Spatial.new()
		chunks_node.name = "Chunks"
		world.add_child(chunks_node)
		chunks_node.owner = world

	yield(get_tree(), "idle_frame")
	# get position of active camera
	var position_provider = get_viewport().get_camera()
	if position_provider == null:
		Logger.err("Failed to perform initial move", self)
		return

	# handle world origin
	var position = position_provider.global_transform.origin
	var chunk_position = position_to_chunk(position)
	_shift_world_origin_to(-chunk_position * chunk_size)


func _order_rails_by_chunk():
	for rail in world.get_node("Rails").get_children():
		var chunk_pos = position_to_chunk(rail.global_transform.origin)
		var chunk_name = chunk_to_string(chunk_pos)
		if rails_by_chunk.has(chunk_name):
			rails_by_chunk[chunk_name].append(rail)
		else:
			rails_by_chunk[chunk_name] = [rail]


func _process(_delta: float):
	assert(world != null)

	# get position of active camera
	var position_provider = get_viewport().get_camera()
	if position_provider == null:
		return

	# handle world origin
	var position = position_provider.global_transform.origin
	var chunk_position = position_to_chunk(position)
	if position.length() > world_origin_shift_treshold:
		_shift_world_origin_to(-chunk_position * chunk_size)

	# handle chunks
	if chunk_position != active_chunk:
		loader.load_chunks(get_chunks(chunk_position, ProjectSettings["game/gameplay/chunk_load_distance"]))
		active_chunk = chunk_position
		_unload_old_chunks()

	if ProjectSettings["game/debug/display_chunk"]:
		DebugDraw.set_text("Chunk", active_chunk)
		DebugDraw.set_text("World Origin", world_origin)
		DebugDraw.set_text("Distance to Origin", position.length())


func _shift_world_origin_to(position: Vector3):
	var delta: Vector3 = position - world_origin
	world_origin = position
	Root.world_origin_shifted(delta)


func _unload_old_chunks(saving: bool = false):
	if saving:
		assert(Root.Editor)

	var chunks_to_unload = loader._loaded_chunks.duplicate()

	# chunks_to_unload = all chunks further away than treshold
	if not saving:
		for chunk_name in loader._loaded_chunks:
			var chunk_pos = string_to_chunk(chunk_name)
			if active_chunk.distance_to(chunk_pos) <= ProjectSettings["game/gameplay/chunk_unload_distance"]:
				chunks_to_unload.erase(chunk_name)

	if Root.Editor:
		for chunk in chunks_to_unload:
			_save_chunk(chunk, saving)

	loader.unload_chunks(chunks_to_unload)


# TODO: in future we could refactor send_message to be a signal in Root ?
func _send_message(msg: String):
	if Root.Editor:
		editor.send_message(msg)
	else:
		world.player.send_message(msg)


### Editor functions
func save_and_unload_all_chunks():
	assert(Root.Editor)

	# first save chunks that have been temporarily swapped to disk
	var files_to_save := []
	var chunk_path = editor.current_track_path.plus_file("chunks")
	_dir.change_dir(chunk_path)
	_dir.list_dir_begin(true, true)
	while(true):
		var file: String = _dir.get_next()
		if file == "":
			break
		if file.ends_with("_temp.tscn"):
			files_to_save.append(file)
	_dir.list_dir_end()

	for file in files_to_save:
		var real_file = file.substr(0, file.length()-len("_temp.tscn")) + ".tscn"
		_dir.copy(file, real_file)  # TODO: sometimes says failed to open, but always works...
		_dir.remove(file)

	_dir.change_dir("res://")

	# then save the currently in-memory chunks
	# and unload them
	_unload_old_chunks(true)


func _force_load_chunk_immediately(chunk_pos: Vector3):
	assert(Root.Editor)
	var chunk_name = chunk_to_string(chunk_pos)
	return loader._force_load_chunk_immediately(chunk_name)


func _force_load_chunk_name_immediately(chunk_name: String):
	assert(Root.Editor)
	return loader._force_load_chunk_immediately(chunk_name)


# TODO: Godot Export "TrackObject is not a valid type"
func add_track_object(track_object: TrackObject):
	var rail_name = track_object.attached_rail
	var rail = world.get_node("Rails").get_node_or_null(rail_name)
	if not is_instance_valid(rail):
		Logger.err("Your track object is attached to an invalid rail.", self)
		_send_message("Cannot create track object. Rail not found.")
		return

	var chunk_pos = position_to_chunk(rail.global_transform.origin)
	var chunk_name = chunk_to_string(chunk_pos)
	var chunk = world.get_node("Chunks").get_node_or_null(chunk_name)
	if not is_instance_valid(chunk):
		Logger.err("Trying to create track object in unloaded chunk.", self)
		_send_message("Cannot create track object. Chunk not loaded.")
		return

	chunk.get_node("TrackObjects").add_child(track_object)
	track_object.owner = chunk


func add_rail(rail):
	assert(Root.Editor)

	var chunk_pos = position_to_chunk(rail.global_transform.origin)
	var chunk_name = chunk_to_string(chunk_pos)

	if rails_by_chunk.has(chunk_name):
		rails_by_chunk[chunk_name].append(rail)
	else:
		rails_by_chunk[chunk_name] = [rail]


func remove_rail(rail):
	assert(Root.Editor)

	var chunk_pos = position_to_chunk(rail.global_transform.origin)
	var chunk_name = chunk_to_string(chunk_pos)

	rails_by_chunk[chunk_name].erase(rail)


func pause_chunking():
	assert(Root.Editor)

	set_process(false)
	loader.set_process(false)


func resume_chunking():
	assert(Root.Editor)

	set_process(true)
	loader.set_process(true)
	if active_chunk:
		loader.load_chunks(get_chunks(active_chunk, ProjectSettings["game/gameplay/chunk_load_distance"]))


func _save_chunk(chunk_name: String, saving: bool = false):
	assert(Root.Editor)

	var chunk_pos = string_to_chunk(chunk_name)

	# get chunks dir
	var base_path = editor.current_track_path.plus_file("chunks")
	if not _dir.dir_exists(base_path):
		_dir.make_dir_recursive(base_path)

	# find the chunk
	var chunk: Chunk = world.get_node("Chunks").get_node_or_null(chunk_name)
	if not is_instance_valid(chunk):
		Logger.err("Trying to save chunk that has been free()'d: %s" % chunk_name, self)
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

	# save a temp file if the chunk gets unloaded before the editor saves!
	# -> do not overwrite old chunks unless the USER presses "save"
	var file = base_path.plus_file(chunk.name)
	if saving:
		file += ".tscn"
	else:
		file += "_temp.tscn"

	# don't save empty chunks
	if chunk.is_empty:
		chunk.queue_free()
		_dir.remove(file)  # delete stale chunk files
		return

	# write chunk to disk
	chunk._prepare_saving()

	var packed_chunk = PackedScene.new()
	if packed_chunk.pack(chunk) != OK:
		Logger.err("Could not pack chunk to tscn!", self)
		return

	if ResourceSaver.save(file, packed_chunk) != OK:
		Logger.err("Could not save chunk tscn!", self)
		return

	world.world_origin_on_last_save = world_origin
	Logger.log("Saved Chunk " + chunk_name)


func cleanup():
	assert(Root.Editor)
	# clean up temporary chunk files

	set_process(false)
	loader.set_process(false)

	var files_to_remove := []

	var chunk_path = editor.current_track_path.plus_file("chunks")
	_dir.open(chunk_path)
	_dir.change_dir(chunk_path)
	_dir.list_dir_begin(true, true)
	while(true):
		var file: String = _dir.get_next()
		if file == "":
			break
		if file.ends_with("_temp.tscn"):
			files_to_remove.append(file)
	_dir.list_dir_end()

	for file in files_to_remove:
		_dir.remove(file)

	_dir.change_dir("res://")


func _test_position_calc() -> void:
	var cases := PoolVector3Array([
		Vector3(0, 0, 0),
		Vector3(500, 0, 0),
		Vector3(-499, 0, 152),
		Vector3(-501, 0, 0),
		Vector3(1000, 0, -1000),
		Vector3(499, 0, 1000),
		Vector3(600, 0, 300),
		Vector3(-700, 0, -700),
	])

	Logger.warn("Running position test", self)

	for case in cases:
		printt(case, position_to_chunk(case))

	print(Vector3() == position_to_chunk(Vector3(-499, 0, 152)))
