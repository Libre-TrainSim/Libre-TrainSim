class_name SignalSettings
extends RailLogicSettings

export (int) var operation_mode: int = SignalOperationMode.BLOCK
export (int) var signal_free_time: int = -1
export (int) var speed: int = -1
export (int) var status: int = SignalStatus.RED


func duplicate(deep: bool = true):
	var copy = get_script().new()

	copy.operation_mode = operation_mode
	copy.signal_free_time = signal_free_time
	copy.speed = speed
	copy.status = status

	return copy
