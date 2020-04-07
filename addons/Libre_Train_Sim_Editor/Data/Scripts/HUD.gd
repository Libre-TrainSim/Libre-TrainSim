extends CanvasLayer

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
################################################################################

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
	
	$HBoxContainer/Speed.text = "Speed: " + String(int(Math.speedToKmH((get_parent().speed)))) + " km/h"
	$HBoxContainer/CurrentLimit.text = "Speed Limit: " + String(get_parent().currentSpeedLimit) + " km/h"
	
	var alpha = (Math.speedToKmH(get_parent().speed)/get_parent().currentSpeedLimit)*2 -1
	if alpha < 0:
		alpha = 0
	$HBoxContainer/CurrentLimit.modulate.a = alpha


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
