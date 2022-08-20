extends Node

var world

var current_track_path = ""
var current_track_name = ""
var content: ModContentDefinition

var scenario_info: TrackScenario = null

func _ready():
	# For now we retrieve the variables from Root. Later these should be filled by the LoadingScreenManager.
	scenario_info = TrackScenario.new()
	current_track_name = Root.current_editor_track
	current_track_path = Root.current_editor_track_path.plus_file(Root.current_editor_track + ".tscn")
	var editor_directory = jSaveManager.get_setting("editor_directory_path", "user://editor/")
	content = load(editor_directory.plus_file(current_track_name).plus_file("content.tres")) as ModContentDefinition
	world = load(current_track_path).instance()
	world.passive = true
	add_child(world)
	$ScenarioMap.init(world)
	$CanvasLayer/ScenarioConfiguration.init()
	Logger.log("Successfully loaded track data.")


func _process(delta):
	run_map_updater(delta)


func show_message(text: String) -> void:
	$CanvasLayer/Message/VBoxContainer/Label.text = text
	$CanvasLayer/Message.show()


func _on_Message_Ok_pressed():
	$CanvasLayer/Message.hide()


func _unhandled_key_input(event):
	if event.is_action_pressed("ui_accept") and $CanvasLayer/Message.visible:
		$CanvasLayer/Message.hide()
		get_tree().set_input_as_handled()

	if event.is_action_pressed("ui_cancel"):
		$CanvasLayer/Pause.visible = !$CanvasLayer/Pause.visible
		get_tree().set_input_as_handled()


func _on_Pause_Back_pressed():
	$CanvasLayer/Pause.hide()


func _on_Save_pressed():
	$CanvasLayer/Pause.hide()
	$CanvasLayer/ScenarioConfiguration.save()


func _on_Pause_QuitWithoutSaving_pressed():
	Root.Editor = false
	Root.scenario_editor = false
	LoadingScreen.load_main_menu()


func _on_Pause_SaveAndQuit_pressed():
	$CanvasLayer/ScenarioConfiguration.save()
	Root.Editor = false
	Root.scenario_editor = false
	LoadingScreen.load_main_menu()


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
	$CanvasLayer/Pause.hide()
	test_track_pck()


func _on_ExportTrack_pressed():
	$CanvasLayer/Pause.hide()
	export_mod()


func save_scenario():
	$CanvasLayer/ScenarioConfiguration.save()


func test_track_pck() -> void:
	if OS.has_feature("editor"):
		show_message("Can't test tracks if runs Libre TrainSim using the Godot Editor. " \
				+ "Please use a build of Libre TrainSim to test tracks. ")
		return

	if ContentLoader.get_scenarios_for_track(Root.current_editor_track_path).size() == 0:
		show_message("Cannot test the track! Please create a scenario.")
		return

	save_scenario()
	export_mod()

	if !ProjectSettings.load_resource_pack("user://addons/%s/%s.pck" % [current_track_name, current_track_name]):
		Logger.warn("Can't load content pack!", self)
		show_message("Can't load content pack!")
		return
	ContentLoader.append_content_to_global_repo(content)
	Root.start_menu_in_play_menu = true
	LoadingScreen.load_main_menu()


func export_mod() -> void:
	if ContentLoader.get_scenarios_for_track(current_track_path).size() == 0:
		show_message("No scenario found! Please create a scenario.")
		return
	save_scenario()
	var track_name = current_track_path.get_file().get_basename()
	var export_path = "user://addons/"
	show_message(ExportTrack.export_editor_track(track_name, export_path))
	return
