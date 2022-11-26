class_name EditorInfo
extends Resource


const RECENT_QUEUE_SIZE := 20


export var favourites := {} # scene: null
export var common := {} # scene: count
export var recent := [] # queue


func push_object(scene: PackedScene) -> void:
	if !common.has(scene):
		common[scene] = 0
	common[scene] += 1
	recent.erase(scene)
	recent.push_back(scene)
	while recent.size() > RECENT_QUEUE_SIZE:
		recent.remove(0)
