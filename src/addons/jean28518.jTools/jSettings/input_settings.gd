class_name InputSettings
extends PanelContainer

signal save

const input_button_scene = preload("res://addons/jean28518.jTools/jSettings/input_button.tscn")
const preset_lts = preload("res://addons/jean28518.jTools/jSettings/input_presets/layout_lts.tres")
const preset_openbve = preload("res://addons/jean28518.jTools/jSettings/input_presets/layout_openbve.tres")
var _input_buttons := []

onready var _input_grid := $"%InputGrid"
onready var _layout_confirmation_lts := $"%LayoutConfirmationLTS"
onready var _layout_confirmation_open_bve := $"%LayoutConfirmationOpenBVE"
onready var _layout_export_dialog := $"%LayoutExportDialog"
onready var _layout_import_dialog := $"%LayoutImportDialog"

func _ready():
	# Localize the Reset Dialog
	_layout_confirmation_lts.get_cancel().text = "NO"
	_layout_confirmation_lts.get_ok().text = "YES"
	_layout_confirmation_open_bve.get_cancel().text = "NO"
	_layout_confirmation_open_bve.get_ok().text = "YES"
	
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
		ProjectSettings["input/" + button.action]["events"] = []
		for event in button.events:
			InputMap.action_add_event(button.action, event)
			ProjectSettings["input/" + button.action]["events"].append(event)
		emit_signal("save")


func _update_all_buttons():
	# Update the text of all InputButtons
	for button in _input_buttons:
		button.events = InputMap.get_action_list(button.action)
		button.update_text()


func _apply_layout(input_map_resource: InputMapResource):
	input_map_resource.apply()
	_update_all_buttons()
	emit_signal("save")


func _load_layout(path: String):
	# Load a layout into InputMap from the provided Resource file
	Logger.log("Loading InputMap from \"" + path + "\".")
	var input_map_resource := ResourceLoader.load(path) as InputMapResource
	if input_map_resource != null:
		_apply_layout(input_map_resource)
	else:
		Logger.log("Failed to load InputMap from \"" + path + "\".")


func _on_LayoutLTS_pressed():
	finish()
	_layout_confirmation_lts.popup_centered_clamped(Vector2(500,250))


func _on_LayoutOpenBVE_pressed():
	finish()
	_layout_confirmation_open_bve.popup_centered_clamped(Vector2(500,250))


func _on_LayoutExport_pressed():
	finish()
	_layout_export_dialog.popup_centered()


func _on_LayoutImport_pressed():
	finish()
	_layout_import_dialog.popup_centered()


func _on_LayoutExportDialog_file_selected(path: String):
	# Save current InputMap to selected path
	Logger.log("Exporting current InputMap to \"" + path + "\".")
	var input_map_resource := InputMapResource.new()
	ResourceSaver.save(path, input_map_resource)


func _on_LayoutImportDialog_file_selected(path: String):
	# Load and apply InputMap from selected path
	_load_layout(path)


func _on_LayoutConfirmationLTS_confirmed():
	Logger.log("Applying LTS input layout preset.")
	_apply_layout(preset_lts)


func _on_LayoutConfirmationOpenBVE_confirmed():
	Logger.log("Applying OpenBVE input layout preset.")
	_apply_layout(preset_openbve)
