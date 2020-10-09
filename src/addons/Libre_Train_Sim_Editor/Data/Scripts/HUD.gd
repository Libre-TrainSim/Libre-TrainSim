extends CanvasLayer

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
################################################################################

onready var player = get_parent()

func _ready():
	pass
	
func _process(delta):
	check_escape(delta)
	
	check_ingameHUD(delta)
	
	check_trainInfo(delta)
	
	if sending:
		messaget += delta
		if messaget > 4:
			$Message.play("FadeOut")
			sending = false
	$FPS.text = String(Engine.get_frames_per_second())
	
	$IngameInformation/Speed/Speed.text = "Speed: " + String(int(Math.speedToKmH((get_parent().speed)))) + " km/h"
	$IngameInformation/Speed/CurrentLimit.text = "Speed Limit: " + String(get_parent().currentSpeedLimit) + " km/h"
	
	var alpha = (Math.speedToKmH(get_parent().speed)/get_parent().currentSpeedLimit)*2 -1
	if alpha < 0:
		alpha = 0
	$IngameInformation/Speed/CurrentLimit.modulate.a = alpha
	
	if $Pause.visible or $TextBox.visible:
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_tree().paused = false
		
	update_nextTable(delta)
		


var sending = false
var messaget = 0
func send_Message(text):
	$MarginContainer/Label.text = text
	$Message.play("FadeIn")
	$Bling.play()
	messaget = 0
	sending = true
	
func check_escape(delta):
	if Input.is_action_just_pressed("Escape"):
		get_tree().paused = true
		$Pause.visible = true


func _on_Back_pressed():
	get_tree().paused = false
	$Pause.visible = false


func _on_Quit_pressed():
	get_tree().quit()
	

func show_textbox_message(string):
	$TextBox/RichTextLabel.text = string
	get_tree().paused = true
	$TextBox.visible = true
	


func _on_OkTextBox_pressed():
	get_tree().paused = false
	$TextBox.visible = false
	
	
func check_ingameHUD(delta):
	if Input.is_action_just_pressed("ingameHUD"):
		$HBoxContainer.visible = !$HBoxContainer.visible



func _on_QuitMenu_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")
	pass # Replace with function body.

func check_trainInfo(delta):
	if Input.is_action_just_pressed("trainInfo"):
		$TrainInfo.visible = not $TrainInfo.visible
	if $TrainInfo.visible:
		$TrainInfo.update_info(get_parent())

var redSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/RedSignal.png")
var greenSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/GreenSignal.png")
var orangeSignal = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/OrangeSignal.png")
func update_nextTable(delta):
	## Update Next Signal:
	$IngameInformation/Next/GridContainer/DistanceToSignal.text = format_distance(player.distanceToNextSignal)
	if player.nextSignal != null:
		match player.nextSignal.status:
			0:
				$IngameInformation/Next/GridContainer/Signal.texture = redSignal
			1:
				if player.nextSignal.orange:
					$IngameInformation/Next/GridContainer/Signal.texture = orangeSignal
				else:
					$IngameInformation/Next/GridContainer/Signal.texture = greenSignal
			
				
	
	## Update next Speedlimit
	
	if player.nextSpeedLimitNode != null:
		$IngameInformation/Next/GridContainer/DistanceToSpeedLimit.text = format_distance(player.distanceToNextSpeedLimit)
		$IngameInformation/Next/GridContainer/SpeedLimit.text = String(player.nextSpeedLimitNode.speed) + " km/h"
	else:
		$IngameInformation/Next/GridContainer/DistanceToSpeedLimit.text = "-"
	
	## Update Next Station 
	var stations = player.stations
	if stations.passed.size() == 0 or (player.endStation and player.isInStation):
		$IngameInformation/Next/GridContainer/Arrival.text = "-"
		$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
	else:
		if player.isInStation:
			for i in range (0, stations.size()-1):
				if stations.passed[i]: continue
				$IngameInformation/Next/GridContainer/Arrival.text = Math.time2String(player.stations["departureTime"][i])
				$IngameInformation/Next/GridContainer/DistanceToStation.text = "-"
				break
		else:
			for i in range (0, stations.size()-1):
				if stations.passed[i]: continue
				$IngameInformation/Next/GridContainer/Arrival.text = Math.time2String(player.stations["arrivalTime"][i])
				$IngameInformation/Next/GridContainer/DistanceToStation.text = format_distance(player.distanceToNextStation)
				break
	
func format_distance(distance):
	distance -= 10
	if distance > 1000:
		return String(int(distance/100)/10.0) + " km"
	if distance > 100:
		return String((int(distance/10)/10.0)*100) + " m"
	else:
		return String((int(distance)/10)*10) + " m"
