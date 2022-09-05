class_name ContactPointSettings
extends RailLogicSettings

export (bool) var enabled := false
export (String) var affected_signal := ""
export (float) var affect_time := 0.1
export (int) var new_speed_limit := -1
export (int) var new_status := 1
export (bool) var enable_for_all_trains := true
export (String) var specific_train := ""


func duplicate(deep: bool = true):
	var copy = get_script().new()

	copy.enabled = enabled
	copy.affected_signal = affected_signal
	copy.affect_time = affect_time
	copy.new_speed_limit = new_speed_limit
	copy.new_status = new_status
	copy.enable_for_all_trains = enable_for_all_trains
	copy.specific_train = specific_train

	return copy
