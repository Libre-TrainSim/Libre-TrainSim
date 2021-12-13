extends Node

var world

var j_save_module = jSaveModule.new()

func _ready():
	world = load(Root.current_editor_track_path.plus_file(Root.current_editor_track + ".tscn")).instance()
	world.passive = true
	add_child(world)
	j_save_module.set_save_path(Root.current_scenario)
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


	if event.is_action_pressed("Escape"):
		$CanvasLayer/Pause.visible = !$CanvasLayer/Pause.visible
		get_tree().set_input_as_handled()


func _on_Pause_Back_pressed():
	$CanvasLayer/Pause.hide()


func _on_Save_pressed():
	$CanvasLayer/Pause.hide()
	$CanvasLayer/ScenarioConfiguration.save()


func _on_Pause_QuitWithoutSaving_pressed():
	LoadingScreen.load_main_menu()


func _on_Pause_SaveAndQuit_pressed():
	$CanvasLayer/ScenarioConfiguration.save()
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
