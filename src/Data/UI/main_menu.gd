extends Control

var save_path := "user://config.cfg"


func _ready():
	# Update GUI language directly at launch
	jSettings.update_and_prepare_language_handling()

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	$Version.text = "Version: %s" % ProjectSettings["application/version/label"]
	if ProjectSettings["application/version/broken"]:
		$Version.add_color_override("font_color", Color.webmaroon)
	elif ProjectSettings["application/version/dirty"]:
		$Version.add_color_override("font_color", Color.yellow)
	var openTimes = jSaveManager.get_value("open_times", 0)
	openTimes += 1
	jSaveManager.save_value("open_times", openTimes)
	var feedbackPressed = jSaveManager.get_value("feedback_pressed", false)
	if openTimes > 3 and not feedbackPressed and not Root.mobile_version:
		$Feedback/VBoxContainer/RichTextLabel.text = tr("MENU_FEEDBACK_QUESTION")
		$Feedback.popup()

	if Root.start_menu_in_play_menu:
		Root.start_menu_in_play_menu = false
		$Feedback.hide()
		_on_PlayFront_pressed()

	updateBottmLabels()
	Logger.log("Using version: %s" % ProjectSettings["application/version/label"])
	Logger.vlog("Main menu loaded")


func _on_Quit_pressed():
	get_tree().quit()


func updateBottmLabels():
	$LabelMusic.visible = jSaveManager.get_setting("musicVolume", 0.0) != 0.0
	$Version.visible = !OS.has_feature("mobile")


func _on_PlayFront_pressed():
	$Play.show()


func _on_Content_pressed():
	$Content.show()


func _on_SettingsFront_pressed():
	jSettings.popup()


func _on_AboutFront_pressed():
	$About.show()


func _on_ButtonFeedback_pressed():
	jSaveManager.save_value("feedback_pressed", true)
	var _unused = OS.shell_open("https://www.libretrainsim.org/feedback")


func _on_OpenWebBrowser_pressed():
	_on_ButtonFeedback_pressed()
	$Feedback.hide()


func _on_Later_pressed():
	$Feedback.hide()


func _on_FrontCreate_pressed():
	$Buttons.hide()
	$CreateMenu.show()


func _on_TrackEditor_pressed():
	$TrackEditorSelection.show()


func _on_CreateMenu_Back_pressed():
	$CreateMenu.hide()
	$Buttons.show()


func _on_ScenarioEditor_pressed():
	$ScenarioEditorSelection.show()
