class_name SignalSettings
extends RailLogicSettings

@export var operation_mode: int = SignalOperationMode.BLOCK
@export var signal_free_time: int = -1
@export var speed: int = -1
@export var status: int = SignalStatus.RED


func duplicate(deep: bool = true):
	var copy = get_script().new()

	copy.operation_mode = operation_mode
	copy.signal_free_time = signal_free_time
	copy.speed = speed
	copy.status = status

	return copy
