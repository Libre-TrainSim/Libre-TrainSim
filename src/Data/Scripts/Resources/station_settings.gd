class_name StationSettings
extends RailLogicSettings

@export var assigned_signal_name: String = ""
@export var enable_person_system: bool = true
@export var overwrite: bool = false


#func duplicate(deep: bool = true):
	#var copy = get_script().new()
#
	#copy.assigned_signal_name = assigned_signal_name
	#copy.enable_person_system = enable_person_system
	#copy.overwrite = overwrite
#
	#return copy
