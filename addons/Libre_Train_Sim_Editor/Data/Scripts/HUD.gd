extends CanvasLayer

func _ready():
	pass
	
func _process(delta):
	check_escape(delta)
	
	check_ingameHUD(delta)
	
	if sending:
		messaget += delta
		if messaget > 4:
			$Message.play("FadeOut")
			sending = false
	$FPS.text = String(Engine.get_frames_per_second())
	
	$Speed.text = "Speed: " + String(int(Math.speedToKmH((get_parent().speed)))) + " km/h"

func _on_Direction_pressed():
	pass
#	if Root.directionPositive == true && get_parent().speed == 0:
#		Root.directionPositive = false
#		print("Backwards")
#	elif Root.directionPositive == false && get_parent().speed == 0:
#		Root.directionPositive = true
#		print("Forwards")
#	else:
#		pass
	
#	if Root.directionPositive == true:
#		$Direction.text = "Forwards"
#	else:
#		$Direction.text = "Reverse"
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
		$Speed.visible = !$Speed.visible
