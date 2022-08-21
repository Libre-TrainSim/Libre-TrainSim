class_name InputSettings
extends PanelContainer

signal save

export (PackedScene) var input_button_scene
var _input_buttons := []

onready var _input_grid := $"%InputGrid"
onready var _input_reset_confirmation_dialog := $"%InputResetConfirmationDialog"

func _ready():
	# Localize the Reset Dialog
	_input_reset_confirmation_dialog.get_cancel().text = "NO"
	_input_reset_confirmation_dialog.get_ok().text = "YES"
	
	# Load all available inputs into a list
	var actions := InputMap.get_actions()
	for action in actions:
		# Add the action to the grid
		_add_entry(action)


func _add_entry(action: String):
	# Add label
	var label := Label.new()
	label.text = action
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	_input_grid.add_child(label)
	
	# Add InputButton
	var input_button := input_button_scene.instance() as InputButton
	input_button.size_flags_horizontal = SIZE_EXPAND_FILL
	input_button.action = action
	input_button.connect("toggled", self, "_on_any_button_toggled", [input_button])
	_input_buttons.append(input_button)
	_input_grid.add_child(input_button)


func finish():
	# Finish any currently active remapping by unpressing all buttons.
	_unpress_all_buttons_except(null)


func _unpress_all_buttons_except(that_button: InputButton):
	for button in _input_buttons:
		if button != that_button:
			button.pressed = false


func _on_any_button_toggled(button_pressed: bool, button: InputButton):
	if button_pressed:
		# Make sure at most one button is pressed at a time
		_unpress_all_buttons_except(button)
	else:
		# When a button is disabled, save its input settings
		InputMap.action_erase_events(button.action)
		for event in button.events:
			InputMap.action_add_event(button.action, event)
		emit_signal("save")


func _on_InputReset_pressed():
	# Ensure active remapping is stopped
	finish()
	
	# Ask for confirmation
	_input_reset_confirmation_dialog.popup_centered_clamped(Vector2(500,250))


func _on_InputResetConfirmationDialog_confirmed():
	# Reset to default
	Logger.vlog("InputMap reset to default.")
	InputMap.load_from_globals()
	
	# Update all buttons
	for button in _input_buttons:
		button.events = InputMap.get_action_list(button.action)
		button.update_text()
	
	# Save
	emit_signal("save")
