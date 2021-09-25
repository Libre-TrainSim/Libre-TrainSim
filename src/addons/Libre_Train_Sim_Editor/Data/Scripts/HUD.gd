extends CanvasLayer

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
################################################################################

onready var player = get_parent()

enum MapStatus {
	CLOSED = 0,
	OVERLAY = 1,
	FULL = 2
}
var map_status = MapStatus.CLOSED

func _ready():
	$MobileHUD.visible = Root.mobile_version
	if Root.mobile_version:
		$IngameInformation/Next.rect_position.y += 100
		$TextBox/RichTextLabel.hide()
		$TextBox/RichTextLabelMobile.show()
		$TextBox/Ok.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))

func init_map():
	$Map/ViewportContainer.hide()
	$Map/ViewportContainer/RailMap.render_target_update_mode = Viewport.UPDATE_ALWAYS
	$Map/ViewportContainer/RailMap.handle_input_locally = true
	$Map/ViewportContainer/RailMap.init_map()

func _process(_delta) -> void:
	$FPS.text = String(Engine.get_frames_per_second())
	if $Pause.visible or $TextBox.visible or $MobileHUD/Pause.visible or Root.ingame_pause:
		get_tree().paused = true
		$MarginContainer/Message.hide()
	else:
		get_tree().paused = false
		$MarginContainer/Message.show()
		
	update_nextTable()
	$IngameInformation/TrainInfo/Screen1.update_display(Math.speedToKmH(player.speed), \
			player.technicalSoll, player.doorLeft, player.doorRight, player.doorsClosing,\
			player.enforcedBreaking, player.sifa, player.automaticDriving,\
			player.currentSpeedLimit, player.engine, player.reverser)

var _saved_ingame_pause 
func _unhandled_input(_event) -> void:
	if $TextBox.visible:
		if Input.is_action_just_pressed("ui_accept"):
			_on_OkTextBox_pressed()
	
	if Input.is_action_just_pressed("Escape"):
		get_tree().paused = !get_tree().paused
		$Pause.visible = !$Pause.visible
		if $Pause.visible:
			_saved_ingame_pause = Root.ingame_pause
			Root.ingame_pause = false
			_saved_mouse_mode = Input.get_mouse_mode()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(_saved_mouse_mode)
			Root.ingame_pause = _saved_ingame_pause
	
	if Input.is_action_just_pressed("nextTable"):
		$IngameInformation/Next.visible = !$IngameInformation/Next.visible
	
	check_trainInfo()
	check_trainInfoAbove()
	check_map()


var messages := 0
func send_message(text: String, actions := []) -> void:
	var Message := $MarginContainer/Message as InputLabel
	Message.backing_text = text
	Message.actions = actions
	Message.make_string()
	$Bling.play()
	if messages == 0:
		$Message.play("FadeIn")
	messages += 1
	yield(get_tree().create_timer(4, false), "timeout")
	messages -= 1
	if messages == 0:
		$Message.play("FadeOut")


func _on_Back_pressed():
	get_tree().paused = false
	$Pause.visible = false
	Input.set_mouse_mode(_saved_mouse_mode)
	Root.ingame_pause = _saved_ingame_pause


func _on_Quit_pressed():
	get_tree().quit()

var _saved_mouse_mode
func show_textbox_message(string):
	_saved_mouse_mode = Input.get_mouse_mode()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$TextBox/RichTextLabel.text = string
	$TextBox/RichTextLabelMobile.text = string
	get_tree().paused = true
	$TextBox.visible = true


func _on_OkTextBox_pressed():
	if player.failed_scenario:
		_on_QuitMenu_pressed()
		return
	get_tree().paused = false
	$TextBox.visible = false
	if $Black.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		$Black/AnimationPlayer.play("FadeOut")
	else:
		Input.set_mouse_mode(_saved_mouse_mode)


var modulation = 0
func check_trainInfo():
	if Input.is_action_just_pressed("trainInfo"):
		modulation += 0.5
		if modulation > 1: 
			modulation = 0
		$IngameInformation/TrainInfo.modulate = Color( 1, 1, 1, modulation)


func check_map():
	if Input.is_action_just_pressed("map_open"):
		map_status = (map_status + 1) % 3
		match map_status:
			MapStatus.CLOSED:
				$Map/ViewportContainer/RailMap.close_map()
				$Map.hide()
			MapStatus.OVERLAY:
				$Map/ViewportContainer/RailMap.open_overlay_map()
				$Map.show()
				$Map/FullMap.hide()
				$Map/OverlayMap.show()
			MapStatus.FULL:
				$Map/ViewportContainer/RailMap.open_full_map()
				$Map.show()
				$Map/FullMap.show()
				$Map/OverlayMap.hide()


func _on_QuitMenu_pressed():
	get_tree().paused = false
	jAudioManager.clear_all_sounds()
	jEssentials.remove_all_pending_delayed_calls()
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")
	pass # Replace with function body.


func check_trainInfoAbove():
	if Input.is_action_just_pressed("trainInfoAbove"):
		$IngameInformation/TrainInfoAbove.visible = not $IngameInformation/TrainInfoAbove.visible
	if $IngameInformation/TrainInfoAbove.visible:
		$IngameInformation/TrainInfoAbove.update_info(get_parent())


var redSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/RedSignal.png")
var greenSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/GreenSignal.png")
var orangeSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/OrangeSignal.png")
func update_nextTable():
	## Update Next Signal:
	$IngameInformation/Next/GridContainer/DistanceToSignal.text = Math.distance2String(player.distanceToNextSignal)
	if player.nextSignal != null:
		match player.nextSignal.status:
			SignalStatus.RED:
				$IngameInformation/Next/GridContainer/Signal.texture = redSignal
			SignalStatus.GREEN:
				$IngameInformation/Next/GridContainer/Signal.texture = greenSignal
			SignalStatus.ORANGE:
				$IngameInformation/Next/GridContainer/Signal.texture = orangeSignal
				
	
	## Update next Speedlimit
	if player.nextSpeedLimitNode != null:
		$IngameInformation/Next/GridContainer/DistanceToSpeedLimit.text = Math.distance2String(player.distanceToNextSpeedLimit)
		$IngameInformation/Next/GridContainer/SpeedLimit.text = String(player.nextSpeedLimitNode.speed) + " km/h"
	else:
		$IngameInformation/Next/GridContainer/DistanceToSpeedLimit.text = "-"
	
	## Update Next Station 
	var stations = player.stations
	if stations.passed.size() == 0 or (player.is_last_station and player.isInStation):
		$IngameInformation/Next/GridContainer/Arrival.text = "-"
		$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
	else:
		if player.isInStation:
			for i in range (0, stations.passed.size()):
				if stations.passed[i]: continue
				$IngameInformation/Next/GridContainer/Arrival.text = Math.time2String(player.stations["departureTime"][i])
				$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
				
				break
		else:
			for i in range (0, stations.passed.size()):
				
				if stations.passed[i] or stations.nodeName[i] != player.nextStation: continue
				$IngameInformation/Next/GridContainer/Arrival.text = Math.time2String(player.stations["arrivalTime"][i])
				$IngameInformation/Next/GridContainer/DistanceToStation.text = Math.distance2String(player.distanceToNextStation)
				
				break

func is_full_map_visible():
	return map_status == MapStatus.FULL
