extends CanvasLayer

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!!
## This Script will be overwritten by the game.
################################################################################

signal textbox_closed

onready var player: LTSPlayer = get_parent()


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$MobileHUD.visible = Root.mobile_version
	if Root.mobile_version:
		$IngameInformation/Next.rect_position.y += 100
	$Pause.player = player
	$Black.show()
	$TextBox.connect("closed", self, "emit_signal", ["textbox_closed"])


func _process(_delta: float) -> void:
	$FPS.text = String(Engine.get_frames_per_second())
	update_nextTable()
	$IngameInformation/TrainInfo/Screen1.update_display(Math.speedToKmH(player.speed), \
			player.technicalSoll, player.doorLeft, player.doorRight, player.doorsClosing,\
			player.enforced_braking, player.automaticDriving,\
			player.currentSpeedLimit, player.engine, player.reverser)


func _unhandled_input(_event) -> void:
	if Input.is_action_just_pressed("nextTable"):
		$IngameInformation/Next.visible = !$IngameInformation/Next.visible

	check_trainInfo()
	check_trainInfoAbove()


var messages: int = 0
func send_message(text: String, actions := []) -> void:
	var Message: InputLabel = $PanelContainer/MessageLabel as InputLabel
	Message.backing_text = text
	Message.actions = actions
	Message.make_string()
	$Bling.play()
	if messages == 0:
		$Message.play("fade")
	messages += 1
	yield(get_tree().create_timer(4, false), "timeout")
	messages -= 1
	if messages == 0:
		$Message.play_backwards("fade")


func show_textbox_message(string: String) -> void:
	$TextBox.message(string)


var modulation: float = 0
func check_trainInfo() -> void:
	if Input.is_action_just_pressed("trainInfo"):
		modulation += 0.5
		if modulation > 1:
			modulation = 0
		$IngameInformation/TrainInfo.modulate = Color( 1, 1, 1, modulation)


func check_trainInfoAbove() -> void:
	if Input.is_action_just_pressed("trainInfoAbove"):
		$IngameInformation/TrainInfoAbove.visible = not $IngameInformation/TrainInfoAbove.visible
	if $IngameInformation/TrainInfoAbove.visible:
		$IngameInformation/TrainInfoAbove.update_info(get_parent())


var redSignal: Texture = preload("res://Data/Misc/RedSignal.png")
var greenSignal: Texture = preload("res://Data/Misc/GreenSignal.png")
var orangeSignal: Texture = preload("res://Data/Misc/OrangeSignal.png")
func update_nextTable() -> void:
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
	var stations: Dictionary = player.stations
	if stations.passed.size() == 0 or (player.is_last_station and player.isInStation):
		$IngameInformation/Next/GridContainer/Arrival.text = "-"
		$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
	else:
		if player.isInStation:
			for i in range(0, stations.passed.size()):
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


func _on_TextBox_closed() -> void:
	if $Black.visible:
		$Black/AnimationPlayer.play("FadeOut")


func _on_paused() -> void:
	$PanelContainer.hide()


func _on_unpaused() -> void:
	$PanelContainer.show()
