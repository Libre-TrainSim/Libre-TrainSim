extends Node
class_name DistanceMonitor

signal reached()

export var _distance: int = 0
var _player = null
var _start_dist = 0

var is_stopped = true


func set_distance(val):
	self._distance = val


func set_player(player):
	self._player = player


func distance_left():
	return (_start_dist + _distance) - _player.distance_on_route


func _ready():
	self.set_process(false)


# either starts or restarts the monitoring
func start():
	if _player == null:
		printerr("DistanceMonitor: Need to set_player() before calling start()!")
		return
	self._start_dist = _player.distance_on_route
	self.is_stopped = false
	self.set_process(true)


func stop():
	self.set_process(false)
	self.is_stopped = true


func _process(delta):
	if _player.distance_on_route > _start_dist + _distance:
		emit_signal("reached")
		stop()

