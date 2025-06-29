class_name TrackScenario
extends Resource


@export var time: int = 0  # seconds
@export var title: String = ""
@export var description: String = ""
@export var duration: int = 0  # minutes

@export var is_hidden: bool = false  # true = visible only in Editor, not in Play menu

# Dict[String, ScenarioRoute]
@export var routes: Dictionary = {}

# Dict[String, RailLogicSettings]
@export var rail_logic_settings: Dictionary = {}


func _init() -> void:
	routes = {}
	rail_logic_settings = {}


func is_route_playable(route_name: String) -> bool:
	assert(routes.has(route_name))
	return routes[route_name].is_playable


static func load_scenario(path = null) -> TrackScenario:
	if path == null:
		path = Root.current_scenario

	var current_scenario = load(path) as TrackScenario
	if current_scenario == null:
		Logger.err("Error loading scenario %s!" % Root.current_scenario, "TrackScenario")
		return null

	return current_scenario


func save_scenario(path = null):
	if path == null:
		path = Root.current_scenario

	var err = ResourceSaver.save(path, self)
	if err != OK:
		Logger.err("Failed saving scenario at %s. Reason: %s" % [path, err], self)
