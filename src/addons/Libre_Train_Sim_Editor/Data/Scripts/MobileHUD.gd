extends Control

var COMMAND_STEP = 0.2

onready var world = find_parent("World")
var player


func _ready():
	player = world.get_node("Players/Player")
	

func _process(delta):
	$VBoxContainer/Pantograph.visible = not player.pantograph
	$VBoxContainer/Engine.visible = not player.engine
	var progress_bar_soll_position = ((player.soll_command-1)*(-0.5)) * OS.get_screen_size().y
	$ProgressBar.rect_position.y = Root.clampViaTime(progress_bar_soll_position, $ProgressBar.rect_position.y, delta*5.0)
	
	if player.pantographUp and not player.pantograph:
		$VBoxContainer/Pantograph.modulate = Color(1,1,1,0.5)
		
	
	
	
	if player.soll_command < 0:
		$ProgressBar.modulate = Color(1, 0.6, 0.1, 1)
	elif player.soll_command == 0:
		$ProgressBar.modulate = Color(1, 1, 1, 1)
	else:
		$ProgressBar.modulate = Color(0.2, 0.7, 0.2, 1)
	
	
	var player_speed_zero = player.speed == 0
	var other_buttons_visible = not player.automaticDriving
	
	$Up.visible = other_buttons_visible
	$Down.visible = other_buttons_visible
	$VBoxContainer.visible = other_buttons_visible
	$DoorLeft.visible = other_buttons_visible and player_speed_zero
	$DoorClose.visible = other_buttons_visible and player_speed_zero
	$DoorRight.visible = other_buttons_visible and player_speed_zero


func update_player_control():
	player.soll_command = soll_command

var soll_command = 0.0
func _on_Up_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	soll_command += COMMAND_STEP
	if soll_command > 1.0:
		soll_command = 1.0
	update_player_control()

func _on_Down_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	soll_command -= COMMAND_STEP
	if soll_command < -1.0:
		soll_command = -1.0
	update_player_control()
	

func _on_Pantograph_pressed():
	if not player.pantographUp:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		player.rise_pantograph()


func _on_Engine_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.startEngine()


func _on_DoorLeft_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.open_left_doors()


func _on_DoorClose_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.close_doors()


func _on_DoorRight_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.open_right_doors()


func _on_Camera_pressed():
	if player.cameraState == 1:
		player.switch_to_outer_view()
	else:
		player.switch_to_cabin_view()
		


func _on_Autopilot_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.toggle_automatic_driving()


func _on_Pause_Back_pressed():
	$Pause.hide()
	get_tree().paused = false




func _on_Pause_QuitMenu_pressed():
	get_tree().paused = false
	jAudioManager.clear_all_sounds()
	get_tree().change_scene("res://addons/Libre_Train_Sim_Editor/Data/Modules/MainMenu.tscn")


func _on_PauseButton_pressed():
	$Pause.show()
	get_tree().paused = true
