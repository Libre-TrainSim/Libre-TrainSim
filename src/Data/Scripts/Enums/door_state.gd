class_name DoorState

# Description
#
# CLOSED: 
#	Door is fully closed.
#	New Person transition is forbidden.
# OPENED: 
#	Door is fully opened.
#	New Person transition is allowed.
# OPENING: 
#	Door is trasiting to OPENED state.
#	No pathfinding allowed.
# CLOSING: 
#	Door is trasiting to CLOSED state. 
#	New Person transition is forbidden. 
#	Person already is transition is allowed to continue.
# HALTED: 
#	Door is not transitining. 
#	New Person transition is forbidden. 
#	Animations/SFX should stop. 
#	Special state for power cut-off (pantograf).

# Door state transitions:
#
#	init 	-> CLOSED
#	CLOSED  -> OPENING
#	OPENING -> OPENED | HALTED | CLOSING
#	CLOSING -> CLOSED | HALTED | OPENING
#	OPENED  -> CLOSING
#	HALTED  -> OPENING | CLOSING

enum State {
	HALTED,
	CLOSED,
	OPENED,
	CLOSING,
	OPENING
}

var state: int = State.CLOSED

signal state_changed(state) # int, enum value

func open() -> void:
	if state == State.OPENED:
		assert(false, "Doors are already in opened state.")
		return
	_set_state(State.OPENING)


func is_opened() -> bool:
	return state == State.OPENED


func close() -> void:
	if state == State.CLOSED:
		assert(false, "Doors are already in closed state.")
		return
	_set_state(State.CLOSING)


func is_closed() -> bool:
	return state == State.CLOSED


func is_halted() -> bool:
	return state == State.HALTED


func is_opening() -> bool:
	return state == State.OPENING


func is_closing() -> bool:
	return state == State.CLOSING

func _init() -> void:
	state = State.CLOSED

func _set_state(newState: int) -> void:
	state = newState
	emit_signal("state_changed", state)
	

func _on_animation_transition_finished(animation: String) -> void:
	if animation == "open":
		match(state):
			State.CLOSING:
				_set_state(State.CLOSED)
			State.OPENING:
				_set_state(State.OPENED)
