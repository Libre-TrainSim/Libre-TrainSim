extends Node
class_name DistanceMonitor

signal reached()

export var _distance: int = 0
var _player: Spatial = null
var _start_dist: float = 0

var is_stopped: bool = true


func set_distance(val: int) -> void:
	self._distance = val


func set_player(player: Spatial) -> void:
	self._player = player


func distance_left() -> float:
	var dist = (_start_dist + _distance) - _player.distance_on_route
	return max(dist, 0)  # never return negative values


func _ready() -> void:
	self.set_process(false)


# either starts or restarts the monitoring
func start() -> void:
	if _player == null:
		printerr("DistanceMonitor: Need to set_player() before calling start()!")
		return
	self._start_dist = _player.distance_on_route
	self.is_stopped = false
	self.set_process(true)


func stop() -> void:
	self.set_process(false)
	self.is_stopped = true


func _process(_delta: float) -> void:
	if _player.distance_on_route > _start_dist + _distance:
		emit_signal("reached")
		stop()

