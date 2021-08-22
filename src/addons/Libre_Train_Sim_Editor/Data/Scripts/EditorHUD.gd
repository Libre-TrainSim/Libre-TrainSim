extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
#	if Engine.is_editor_hint():
	register_signals_for_escaping_mouse_clicks_from_ui(self)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func handle_object_transform_field():
	$ObjectName/Name/Duplicate.visible = get_parent().selected_object_type == "Building"
	if not $ObjectTransform.visible:
		return
	var selected_object = get_parent().selected_object
	$ObjectTransform/HBoxContainer/x.value = selected_object.translation.x
	$ObjectTransform/HBoxContainer/y.value = selected_object.translation.y
	$ObjectTransform/HBoxContainer/z.value = selected_object.translation.z
	$ObjectTransform/HBoxContainer/y_rot.value = selected_object.rotation_degrees.y
	
	

func _input(event):
	if Input.is_action_just_pressed("Escape"):
		if $Pause.visible:
			_on_Pause_Back_pressed()
		else:
			$Pause.show()
			get_tree().paused = true
	
	handle_object_transform_field()

	

func update_ShowSettingsButton():
	if not $Settings.visible:
		$ShowSettingsButton.text = "Show Settings"
	else:
		$ShowSettingsButton.text = "Hide Settings"

func _on_ShowSettings_pressed():
	if $Settings.visible:
		hide_settings()
	else:
		show_settings()
	update_ShowSettingsButton()
		
	
func hide_settings():
	$Settings.hide()

func show_settings():
	$Settings.show()

func set_current_object_name(object_name : String):
	$ObjectName/Name/LineEdit.text = object_name
	$ObjectName.show()

func clear_current_object_name():
	$ObjectName.hide()

func hide_current_object_transform():
	$ObjectTransform.hide()
	
func show_current_object_transform():
	$ObjectTransform.show()
	handle_object_transform_field()


func _on_ClearCurrentObject_pressed():
	get_parent().clear_selected_object()


func _on_CurrentObjectRename_pressed():
	get_parent().rename_selected_object($ObjectName/Name/LineEdit.text)


func _on_DeleteCurrentObject_pressed():
	get_parent().delete_selected_object()


func _on_Pause_Back_pressed():
	get_tree().paused = false
	$Pause.hide()


func _on_SaveAndExit_pressed():
	get_parent().save_world()
	get_tree().paused = false
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")


func _on_SaveWithoutExit_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")



	

func _on_x_value_changed(value):
	var selected_object = get_parent().selected_object
	selected_object.translation.x = $ObjectTransform/HBoxContainer/x.value


func _on_y_value_changed(value):
	var selected_object = get_parent().selected_object
	selected_object.translation.y = $ObjectTransform/HBoxContainer/y.value


func _on_z_value_changed(value):
	var selected_object = get_parent().selected_object
	selected_object.translation.z = $ObjectTransform/HBoxContainer/z.value


func _on_y_rot_value_changed(value):
	var selected_object = get_parent().selected_object
	selected_object.rotation_degrees.y = $ObjectTransform/HBoxContainer/y_rot.value


func _onObjectName_text_entered(new_text):
	_on_CurrentObjectRename_pressed()
	
func show_building_settings():
	show_settings()
	$Settings/TabContainer.current_tab = 3

func ensure_rail_settings():
	show_settings()
	if $Settings/TabContainer.current_tab > 2:
		$Settings/TabContainer.current_tab = 0


func  _on_DuplicateObject_pressed():
	get_parent().duplicate_selected_object()


var mouse_over_ui = false
var mouse_ui_index = 0
func _on_Mouse_entered_UI():
	mouse_ui_index += 1
	mouse_over_ui = mouse_ui_index != 0
	
func _on_Mouse_exited_UI():
	mouse_ui_index -= 1
	mouse_over_ui =  mouse_ui_index != 0

func register_signals_for_escaping_mouse_clicks_from_ui(node : Node) -> void:
	print("CONNECTING SIGNALS:::::")
	for child in node.get_children():
		if child.has_signal("mouse_entered"): 
			child.connect("mouse_entered", child.find_parent("EditorHUD"), "_on_Mouse_entered_UI")
			child.connect("mouse_exited", child.find_parent("EditorHUD"), "_on_Mouse_exited_UI")
		register_signals_for_escaping_mouse_clicks_from_ui(child)
