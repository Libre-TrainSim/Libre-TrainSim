extends PassengerPathNode

@export var side : DoorSide.TypeHint = DoorSide.TypeHint.UNASSIGNED

func _init() -> void:
	type = Type.DOOR
