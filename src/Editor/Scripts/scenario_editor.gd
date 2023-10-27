extends Node

var world

var current_track_path = ""
var current_track_name = ""
var content: ModContentDefinition

var scenario_info: TrackScenario = null

onready var pause_menu: Control = $CanvasLayer/Pause

func _ready():
	# For now we retrieve the variables from Root. Later these should be filled by the LoadingScreenManager.
	scenario_info = load(Root.current_scenario) as TrackScenario
	current_track_name = Root.current_editor_track
	current_track_path = Root.current_editor_track_path
	var editor_directory = jSaveManager.get_setting("editor_directory_path", "user://editor/")
	content = load(editor_directory.plus_file(current_track_name).plus_file("content.tres")) as ModContentDefinition
	world = load(current_track_path.plus_file(current_track_name+".tscn")).instance()
	world.passive = true
	add_child(world)
	$ScenarioMap.init(world)
	$CanvasLayer/ScenarioConfiguration.init()
	Logger.log("Successfully loaded track data.")

	pause_menu.connect("visibility_changed", self, "_on_Pause_visibility_changed")


func _enter_tree() -> void:
	Root.Editor = true
	Root.scenario_editor = true


func _exit_tree() -> void:
	Root.Editor = false
	Root.scenario_editor = false


func _process(delta):
	run_map_updater(delta)


func show_message(text: String) -> void:
	$CanvasLayer/Message/VBoxContainer/Label.text = text
	$CanvasLayer/Message.show()


func _on_Message_Ok_pressed():
	$CanvasLayer/Message.hide()


func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and $CanvasLayer/Message.visible:
		$CanvasLayer/Message.hide()
		get_tree().set_input_as_handled()

	if pause_menu.visible and (event.is_action_released("pause") or event.is_action_released("ui_cancel")):
		pause_menu.visible = false
		get_tree().set_input_as_handled()
	elif event.is_action_released("pause"):
		pause_menu.visible = true
		get_tree().set_input_as_handled()


func _on_Pause_Back_pressed():
	pause_menu.hide()


func _on_Save_pressed():
	pause_menu.hide()
	$CanvasLayer/ScenarioConfiguration.save()


func _on_Pause_QuitWithoutSaving_pressed():
	LoadingScreen.load_main_menu()


func _on_Pause_SaveAndQuit_pressed():
	$CanvasLayer/ScenarioConfiguration.save()
	LoadingScreen.load_main_menu()


func _on_Pause_visibility_changed() -> void:
	if pause_menu.visible:
		$CanvasLayer/Pause/VBoxContainer/Back.grab_focus()


func _on_LayoutSetting_pressed():
	var label_data: Dictionary = {}
	label_data.rails = $CanvasLayer/LabelSettings/V/Rails.pressed
	label_data.signals = $CanvasLayer/LabelSettings/V/Signals.pressed
	label_data.stations = $CanvasLayer/LabelSettings/V/Stations.pressed
	label_data.contact_points = $CanvasLayer/LabelSettings/V/ContactPoints.pressed
	label_data.other = $CanvasLayer/LabelSettings/V/Other.pressed
	$ScenarioMap.set_label_mask(label_data)


func _on_Labels_pressed():
	$CanvasLayer/LabelSettings.visible = not $CanvasLayer/LabelSettings.visible


var _run_map_updater_timer: float = 0
func run_map_updater(delta: float):
	_run_map_updater_timer += delta
	if _run_map_updater_timer > 1:
		_run_map_updater_timer = 0
		$ScenarioMap.update_map()


func _on_TestTrack_pressed():
	pause_menu.hide()
	save_scenario()
	test_track()


func _on_ExportTrack_pressed():
	pause_menu.hide()
	export_mod()


func save_scenario():
	$CanvasLayer/ScenarioConfiguration.save()


func test_track() -> void:
	$CanvasLayer/PlayMenu.show_route_selector( \
		current_track_path.plus_file(current_track_name + ".tscn"), \
		scenario_info.resource_path \
	)


func export_mod() -> void:
	if ContentLoader.get_scenarios_for_track(current_track_path).size() == 0:
		show_message("No scenario found! Please create a scenario.")
		return

	save_scenario()
	var track_name = current_track_path.get_file().get_basename()
	var export_path = "user://addons/"
	show_message(ExportTrack.export_editor_track(track_name, export_path))
	return


func _on_AutoUpdating_toggled(update: bool) -> void:
	set_process(update)
	$CanvasLayer/UpdateMode/VBoxContainer/UpdateNow.visible = !update


func _on_UpdateNow_pressed() -> void:
	$ScenarioMap.update_map()
	_run_map_updater_timer = 0
