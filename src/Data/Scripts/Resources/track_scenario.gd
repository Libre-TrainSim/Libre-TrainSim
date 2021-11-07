class_name TrackScenario
extends Resource

# String -> int
# I don't like it, but this is what OS.get_time() would return
# so let's stick to Godots chosen way of doing it.
export var time := {
	"hour": 0,    # TimeH
	"minute": 0,  # TimeM
	"second": 0   # TimeS
}
export var title := ""
export var description := ""
export var duration: int = 0  # Minutes

export var is_hidden := false  # true = visible only in Editor, not in Play menu

export var train_length: float = 0.0  # why???

# Dict[String, Dict[String, Any]]
# see World.gd spawn_train()
export var trains := {}

# Dict[String, Dict[String, Any]]
# see Signal.gd get_scenario_data()
export var signals := {}
