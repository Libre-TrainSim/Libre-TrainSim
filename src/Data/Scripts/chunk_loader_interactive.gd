class_name ChunkLoaderInteractive
extends Node

# This class will become obsolete with Godot 4.0
# https://github.com/godotengine/godot/pull/36640

const MAX_LOAD_TIME_STEP = 1.0  # control for how long we block main thread
const chunk_prefab := preload("res://Data/Modules/chunk_prefab.tscn")

var _loaded_chunks := []  # Array[String]
var _chunks_to_load := []  # Array[String] ; Queue

var chunk_manager = null

var _loader: ResourceInteractiveLoader
var _currently_loading_chunk: String

var _dir: Directory


func load_chunks(new_chunks: Array):
	for chunk in new_chunks:
		# load the chunk only if it is not yet loaded
		if (not chunk in _loaded_chunks) \
			and (not chunk in _chunks_to_load) \
			and chunk != _currently_loading_chunk:
			_chunks_to_load.push_back(chunk)

	if not _chunks_to_load.empty():
		set_process(true)


func unload_chunks(old_chunks: Array):
	for rail in chunk_manager.world.get_node("Rails").get_children():
		var chunk_pos = chunk_manager.position_to_chunk(rail.global_transform.origin)
		var chunk_name = chunk_manager.chunk_to_string(chunk_pos)
		if chunk_pos in old_chunks:
			rail.unload_visible_instance()

	for chunk_name in old_chunks:
		var chunk = chunk_manager.world.get_node("Chunks").get_node_or_null(chunk_name)
		if is_instance_valid(chunk):
			if Root.Editor:
				chunk.free() # necessary for saving
			else:
				chunk.queue_free()
		_loaded_chunks.erase(chunk_name)
		_chunks_to_load.erase(chunk_name)


func _ready() -> void:
	_dir = Directory.new()
	if _dir.open("res://") != OK:
		Logger.err("Cannot open resource directory.", self)
		return


func _process(delta: float) -> void:
	if _chunks_to_load.empty():
		set_process(false)
		return

	if _loader == null:
		_currently_loading_chunk = _chunks_to_load.pop_front()
		var file = _get_chunk_file_path(_currently_loading_chunk)
		if _dir.file_exists(file):
			_loader = ResourceLoader.load_interactive(file)
		else:
			_spawn_empty_chunk()
			_currently_loading_chunk = ""
			return

	assert(_loader != null)

	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + MAX_LOAD_TIME_STEP:
		var err = _loader.poll()
		if err == ERR_FILE_EOF:
			_spawn_chunk_from_res(_loader.get_resource())
			_loader = null
			_currently_loading_chunk = ""
			break
		elif err != OK:
			Logger.err("Cannot load chunk %s (Reason %s)" % [_currently_loading_chunk, err], self)
			_loader = null
			chunk_manager._send_message("Chunk could not be loaded, please check your logs!")
			break


func _spawn_chunk_from_res(resource):
	if not resource is PackedScene:
		Logger.warn("What? Your chunk is not a packed scene! %s" % _currently_loading_chunk, self)
		return

	var chunk = resource.instance()
	chunk.generate_grass = chunk_manager.world.current_world_config.generate_grass

	_add_chunk_to_scene_tree(chunk)

	return chunk


func _spawn_empty_chunk():
	var chunk = chunk_prefab.instance()
	chunk.name = _currently_loading_chunk
	chunk.chunk_position = chunk_manager.string_to_chunk(_currently_loading_chunk)
	chunk.generate_grass = chunk_manager.world.current_world_config.generate_grass

	_add_chunk_to_scene_tree(chunk)

	return chunk


func _add_chunk_to_scene_tree(chunk):
	# This should never happen! If it does, we're hiding a bug.
	if chunk_manager.world.get_node("Chunks").has_node(chunk.name):
		Logger.warn("Chunk already loaded: %s" % chunk.name, self)
		_loaded_chunks.push_back(chunk.name)
		chunk.free()
		return

	chunk_manager.world.get_node("Chunks").add_child(chunk)
	chunk.owner = chunk_manager.world
	chunk._on_world_origin_shifted(chunk_manager.world_origin)
	chunk.update()

	if chunk_manager.rails_by_chunk.has(chunk.name):
		for rail in chunk_manager.rails_by_chunk[chunk.name]:
			rail._update()

	_loaded_chunks.push_back(_currently_loading_chunk)


func _get_chunk_file_path(chunk: String):
	var chunk_path := ""
	if Root.Editor:
		chunk_path = chunk_manager.editor.current_track_path.plus_file("chunks")
	else:
		chunk_path = Root.current_track.get_base_dir().plus_file("chunks")
	var chunk_file = chunk_path.plus_file(chunk) + ".tscn"

	if Root.Editor:
		var temp_file = chunk_path.plus_file(chunk) + "_temp.tscn"
		if _dir.file_exists(temp_file):
			chunk_file = temp_file

	return chunk_file


func _force_load_chunk_immediately(chunk_name):
	assert(Root.Editor)

	var file = _get_chunk_file_path(chunk_name)
	var chunk = null
	_currently_loading_chunk = chunk_name
	if _dir.file_exists(file):
		var resource = load(file)
		chunk = _spawn_chunk_from_res(resource)
	else:
		chunk = _spawn_empty_chunk()
	return chunk

