class_name TrackScenario
extends Resource


export var time: int = 0  # seconds
export var title := ""
export var description := ""
export var duration: int = 0  # minutes

export var is_hidden := false  # true = visible only in Editor, not in Play menu

# Dict[String, ScenarioRoute]
# see World.gd spawn_train()
export var routes := {}

# Dict[String, RailLogicSettings]
# see Signal.gd get_scenario_data()
export var rail_logic_settings := {}


func is_route_playable(route_name: String) -> bool:
	assert(routes.has(route_name))
	return routes[route_name].is_playable


static func load_scenario(path = null) -> TrackScenario:
	if path == null:
		path = Root.current_track.get_base_dir().plus_file("scenarios").plus_file(Root.current_scenario) + ".tres"

	var current_scenario = load(path) as TrackScenario
	if current_scenario == null:
		Logger.err("Error loading scenario %s!" % Root.current_scenario, "TrackScenario")
		return null

	return current_scenario
