extends Control

var save_path
var config

# Called when the node enters the scene tree for the first time.
func _ready():
	save_path = get_parent().save_path
	config = get_parent().config
	$GridContainer/Fullscreen.pressed = config.get_value("Settings", "fullscreen", true)
	$GridContainer/Shadows.pressed = config.get_value("Settings", "shadows", true)
	$GridContainer/ViewDistance.value = config.get_value("Settings", "viewDistance", 1000)
	$GridContainer/AntiAliasing.pressed = config.get_value("Settings", "antiAliasing", true)
	$GridContainer/Fog.pressed = config.get_value("Settings", "fog", true)
	$GridContainer/MainMenuMusic.pressed = config.get_value("Settings", "mainMenuMusic", true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_Fullscreen_pressed():
	config.set_value("Settings", "fullscreen", $GridContainer/Fullscreen.pressed)
	config.save(save_path)
	OS.window_fullscreen = $GridContainer/Fullscreen.pressed
	
func _on_Shadows_pressed():
	config.set_value("Settings", "shadows", $GridContainer/Shadows.pressed)
	config.save(save_path)

func _on_ViewDistance_value_changed(value):
	config.set_value("Settings", "viewDistance", $GridContainer/ViewDistance.value)
	config.save(save_path)

func _on_AntiAliasing_pressed():
	config.set_value("Settings", "antiAliasing", $GridContainer/AntiAliasing.pressed)
	config.save(save_path)

func _on_Fog_pressed():
	config.set_value("Settings", "fog", $GridContainer/Fog.pressed)
	config.save(save_path)

func _on_MainMenuMusic_pressed():
	config.set_value("Settings", "mainMenuMusic", $GridContainer/MainMenuMusic.pressed)
	config.save(save_path)
	get_parent().update_MainMenuMusic()

func _on_Back_pressed():
	hide()
	get_node("../MenuBackground").hide()
	get_node("../Front").show()
	



