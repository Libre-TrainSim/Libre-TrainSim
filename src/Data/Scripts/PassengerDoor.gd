extends PassengerPathNode

export (DoorSide.TypeHint) var side := DoorSide.UNASSIGNED

func _init() -> void:
	type = Type.DOOR
