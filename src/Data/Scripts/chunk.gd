class_name Chunk
extends Spatial

export var is_empty := true
export var generate_grass := true  # set this to false when we have terrain

export var chunk_position: Vector3

# array of node names
export (Array, String) var rails := []


# see chunk_prefab.tscn
# TrackObjects are saved in global coordinates, NOT relative to the chunk!
# this is because they are attached to the Rails!
# Buildings are also stored in global coordinates
# DefaultGrass is stored relative to the chunk, we must move it to the correct global position
# thus, Chunks should always be at (0,0,0)


func _ready() -> void:
	translation = Vector3(0, 0, 0)
	if not generate_grass:
		$DefaultGrass.queue_free()
	else:
		$DefaultGrass.translation = chunk_position * 1000  # 1000 = ChunkManager.chunk_size
		$DefaultGrass.translation.y = -0.5
	Root.connect("world_origin_shifted", self, "_on_world_origin_shifted")


func update():
	for obj in $TrackObjects.get_children():
		obj.update()


func _prepare_saving():
	# clear multimesh data, it is generated at runtime
	# saves disk space
	for obj in $TrackObjects.get_children():
		obj.multimesh = null


func _on_world_origin_shifted(delta):
	if generate_grass:
		$DefaultGrass.translation += delta

	# FIXME: this does not actually work...
	#        it would be so nice, if we could just shift the entire chunk node
	#        instead of all the track objects,
	#        but I think that will require a TrackObject refactor
	#        ask me about it for 0.10
	#translation += delta
