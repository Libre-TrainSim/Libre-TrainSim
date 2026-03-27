class_name ContactPointSettings
extends RailLogicSettings

@export var enabled: bool = false
@export var affected_signal: String = ""
@export var affect_time: float = 0.1
@export var new_speed_limit: int = -1
@export var new_status: int = 1
@export var enable_for_all_trains: bool = true
@export var specific_train: String = ""


#func duplicate(deep: bool = true):
	#var copy = get_script().new()
#
	#copy.enabled = enabled
	#copy.affected_signal = affected_signal
	#copy.affect_time = affect_time
	#copy.new_speed_limit = new_speed_limit
	#copy.new_status = new_status
	#copy.enable_for_all_trains = enable_for_all_trains
	#copy.specific_train = specific_train
#
	#return copy
