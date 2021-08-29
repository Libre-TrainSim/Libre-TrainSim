extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func _input(event):
	visible = is_instance_valid(current_rail_logic) and get_parent().current_tab == 2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var current_rail_logic = null
var current_rail_logic_type = ""
func set_rail_logic(rail_logic):
	current_rail_logic = rail_logic
	current_rail_logic_type = rail_logic.type
	update_general_settings_ui()
	$SignalSettings.visible = current_rail_logic_type == "Signal"
	$StationSettings.visible = current_rail_logic_type == "Station"
	$SpeedLimitSettings.visible = current_rail_logic_type == "Speed"
	$WarnSpeedLimitSettings.visible = current_rail_logic_type == "WarnSpeed"
	$ContactPointSettings.visible = current_rail_logic_type == "ContactPoint"
	match current_rail_logic.type:
		"Signal":
			update_signal_settings_ui()
		"Station":
			update_station_settings_ui()
		"Speed":
			update_speed_limit_settings_ui()
		"WarnSpeed":
			update_warn_speed_limit_settings_ui()
		"ContactPoint":
			update_contact_point_settings_ui()

func update_general_settings_ui():
	$GeneralSettings/Distance.value = current_rail_logic.onRailPosition
	$GeneralSettings/Forwad.pressed = current_rail_logic.forward

func _on_Distance_value_changed(value):
	$GeneralSettings/Distance.value = clamp($GeneralSettings/Distance.value, 0, find_parent("Editor").get_node("World/Rails/" + current_rail_logic.attachedRail).length)
	current_rail_logic.onRailPosition = $GeneralSettings/Distance.value
	current_rail_logic.setToRail(true)

func _on_Forwad_pressed():
	current_rail_logic.forward = $GeneralSettings/Forwad.pressed
	current_rail_logic.setToRail(true)
	


var resource_selector_called = false
func _on_PickVisibleInstance_pressed():
	resource_selector_called = true
	var content_selector = find_parent("Editor").get_node("EditorHUD/Content_Selector")
	content_selector.set_type(content_selector.SIGNAL_TYPES)
	content_selector.show()
	pass # Replace with function body.


func _on_Block_Signal_pressed():
	current_rail_logic.blockSignal = $SignalSettings/BlockSignal.pressed
	update_signal_settings_ui()
	
func update_signal_settings_ui():
	$SignalSettings/SpeedLimit.value = current_rail_logic.speed
	$SignalSettings/BlockSignal.pressed = current_rail_logic.blockSignal
	$SignalSettings/VisibleInstance/LineEdit.text = current_rail_logic.visualInstancePath
	$SignalSettings/Status.value = current_rail_logic.status
	$SignalSettings/Status.visible = not current_rail_logic.blockSignal
	$SignalSettings/LabelStatus.visible = not current_rail_logic.blockSignal
	$SignalSettings/Label4.visible = not current_rail_logic.blockSignal
	$SignalSettings/EnableTimedFree.visible = not current_rail_logic.blockSignal
	$SignalSettings/EnableTimedFree.pressed = not current_rail_logic.setPassAtH < 0 and not current_rail_logic.setPassAtH > 23
	update_signal_time_free_ui()
	


func _on_Content_Selector_resource_selected(complete_path):
	if not resource_selector_called: return
	resource_selector_called = false
	if complete_path == "": return
	$SignalSettings/VisibleInstance/LineEdit.text = complete_path
	current_rail_logic.visualInstancePath = complete_path
	current_rail_logic.updateVisualInstance()


func _on_Status_value_changed(value):
	current_rail_logic.status = $SignalSettings/Status.value
	pass # Replace with function body.


func _on_EnableTimedFree_pressed():
	if not $SignalSettings/EnableTimedFree.pressed:
		current_rail_logic.setPassAtH = 25 # Disable timed free
	update_signal_time_free_ui()
	
func update_signal_time_free_ui():
	$SignalSettings/Label3.visible = $SignalSettings/EnableTimedFree.pressed and not $SignalSettings/BlockSignal.pressed
	$SignalSettings/TimedFree.visible = $SignalSettings/EnableTimedFree.pressed and not $SignalSettings/BlockSignal.pressed
	$SignalSettings/TimedFree.set_data([current_rail_logic.setPassAtH, current_rail_logic.setPassAtM, current_rail_logic.setPassAtS])


func _on_TimedFree_time_set():
	var time_data = $SignalSettings/TimedFree.get_data()
	current_rail_logic.setPassAtH = time_data[0]
	current_rail_logic.setPassAtM = time_data[1]
	current_rail_logic.setPassAtS = time_data[2]


func _on_SpeedLimitSignalSettings_value_changed(value):
	current_rail_logic.speed = $SignalSettings/SpeedLimit.value






func update_station_settings_ui():
	$StationSettings/Name.text = current_rail_logic.name
	$StationSettings/Length.value = current_rail_logic.stationLength
	$StationSettings/PlatformSide.selected = current_rail_logic.platformSide
	$StationSettings/EnablePersonSystem.pressed = current_rail_logic.personSystem
	$StationSettings/PlatformHeight.visible = current_rail_logic.personSystem
	$StationSettings/Label4.visible = current_rail_logic.personSystem
	$StationSettings/PlatformHeight.value = current_rail_logic.platformHeight
	$StationSettings/Label5.visible = current_rail_logic.personSystem
	$StationSettings/PlatformStart.visible = current_rail_logic.personSystem
	$StationSettings/PlatformStart.value = current_rail_logic.platformStart
	$StationSettings/Label6.visible = current_rail_logic.personSystem
	$StationSettings/PlatformEnd.visible = current_rail_logic.personSystem
	$StationSettings/PlatformEnd.value = current_rail_logic.platformEnd

	pass # TODO!


func _on_StationName_text_entered(new_text):
	Root.name_node_appropriate(current_rail_logic, new_text, current_rail_logic.get_parent())
	$StationSettings/Name.text = current_rail_logic.name


func _on_Length_value_changed(value):
	current_rail_logic.stationLength = $StationSettings/Length.value

func _on_PlatformSide_item_selected(index):
	current_rail_logic.platformSide = index

func _on_EnablePersonSystem_pressed():
	current_rail_logic.personSystem = $StationSettings/EnablePersonSystem.pressed

func _on_PlatformHeight_value_changed(value):
	current_rail_logic.platformHeight = value

func _on_PlatformStart_value_changed(value):
	current_rail_logic.platformStart = value

func _on_PlatformEnd_value_changed(value):
	current_rail_logic.platformEnd = value
	
	
	



func update_speed_limit_settings_ui():
	$SpeedLimitSettings/SpeedLimit.value = current_rail_logic.speed

func _on_SpeedLimit_SpeedLimit_value_changed(value):
	current_rail_logic.speed = $SpeedLimitSettings/SpeedLimit.value
	current_rail_logic.setToRail(true)




func update_warn_speed_limit_settings_ui():
	$WarnSpeedLimitSettings/SpeedLimit.value = current_rail_logic.warnSpeed

func _on_WarnSpeedLimit_value_changed(value):
	current_rail_logic.warnSpeed = $WarnSpeedLimitSettings/SpeedLimit.value
	current_rail_logic.setToRail(true)



func update_contact_point_settings_ui():
	$ContactPointSettings/AffectedSignal.text = current_rail_logic.affectedSignal
	$ContactPointSettings/Disable.pressed = current_rail_logic.disabled
	$ContactPointSettings/AffectTime.value = current_rail_logic.affectTime
	$ContactPointSettings/NewSpeedLimit.value = current_rail_logic.newSpeed
	$ContactPointSettings/NewStatus.value = current_rail_logic.newStatus
	$ContactPointSettings/EnableForAllTrains.pressed = current_rail_logic.enable_for_all_trains
	$ContactPointSettings/OnlySpecificTrain.text = current_rail_logic.bySpecificTrain
	
	$ContactPointSettings/Label4.visible = not current_rail_logic.disabled
	$ContactPointSettings/AffectTime.visible = not current_rail_logic.disabled
	$ContactPointSettings/Label2.visible = not current_rail_logic.disabled
	$ContactPointSettings/NewSpeedLimit.visible = not current_rail_logic.disabled
	$ContactPointSettings/Label3.visible = not current_rail_logic.disabled
	$ContactPointSettings/NewStatus.visible = not current_rail_logic.disabled
	$ContactPointSettings/Label6.visible = not current_rail_logic.disabled
	$ContactPointSettings/EnableForAllTrains.visible = not current_rail_logic.disabled
	$ContactPointSettings/Label7.visible = not current_rail_logic.disabled and not current_rail_logic.enable_for_all_trains
	$ContactPointSettings/OnlySpecificTrain.visible = not current_rail_logic.disabled and not current_rail_logic.enable_for_all_trains
	pass



func _on_AffectedSignal_text_entered(new_text):
	current_rail_logic.affectedSignal = $ContactPointSettings/AffectedSignal.text

func _on_ContactPointDisable_pressed():
	current_rail_logic.disabled = $ContactPointSettings/Disable.pressed
	update_contact_point_settings_ui()

func _on_ContactPointAffectTime_value_changed(value):
	current_rail_logic.affectTime = $ContactPointSettings/AffectTime.value

func _on_ContactPointNewSpeedLimit_value_changed(value):
	current_rail_logic.newSpeed = $ContactPointSettings/NewSpeedLimit.value

func _on_ContactPointNewStatus_value_changed(value):
	current_rail_logic.newStatus = $ContactPointSettings/NewStatus.value

func _on_ContactPointEnableForAllTrains_pressed():
	current_rail_logic.enable_for_all_trains = $ContactPointSettings/EnableForAllTrains.pressed
	update_contact_point_settings_ui()

func _on_ContactPointOnlySpecificTrain_text_entered(new_text):
	current_rail_logic.bySpecificTrain = $ContactPointSettings/OnlySpecificTrain.text
