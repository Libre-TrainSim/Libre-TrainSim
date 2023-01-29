class_name InputMapResource
extends Resource


export (Dictionary) var input_map


func _init():
	update()


func update() -> void:
	# Clear input_map
	input_map = {}

	# Parse all InputMap content into input_map
	for action in InputMap.get_actions():
		input_map[action] = []
		for event in InputMap.get_action_list(action):
			input_map[action].append(event)


func apply() -> void:
	# Apply content of input_map
	for action in input_map:
		InputMap.action_erase_events(action)
		ProjectSettings["input/" + action]["events"] = []
		for event in input_map[action]:
			InputMap.action_add_event(action, event)
			ProjectSettings["input/" + action]["events"].append(event)
