class_name InputButton
extends Button


var action: String
var events := []


func _ready():
	# Add existing inputs
	events.append_array(InputMap.get_action_list(action))
	update_text()


func _input(event):
	# Only handle input if currently capturing
	if not pressed:
		return
	
	# Ignore mouse input
	if event is InputEventMouse:
		return
	
	# Ignore release events
	if not event.is_pressed():
		return
	
	# Don't allow assigning the ESC key
	if event is InputEventKey and event.scancode == KEY_ESCAPE:
		return
	
	# If the event is already in the list, remove it again and return
	for e in events:
		if event.shortcut_match(e):
			events.remove(events.find(e))
			update_text()
			return
	
	# Add event to list
	events.append(event)
	update_text()


func update_text():
	text = ""
	for event in events:
		if text != "":
			text += ", "
		text += '"'
		if event is InputEventJoypadButton:
			text += "Button " + str(event.button_index)
		elif event is InputEventJoypadMotion:
			text += "Axis " + str(event.axis)
			text += '+' if event.axis_value >= 0 else '-'
		elif event is InputEventMouseButton:
			text += "Mouse " + str(event.button_index)
		else:
			text += event.as_text()
		text += '"'
