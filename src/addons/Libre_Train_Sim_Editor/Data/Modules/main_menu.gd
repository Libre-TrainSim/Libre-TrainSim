extends Control

var save_path := "user://config.cfg"
export var version = ""


func _ready():
	$Version.text = "Version: %s" % version
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
	OS.shell_open("https://www.libre-trainsim.de/feedback")


func _on_OpenWebBrowser_pressed():
	_on_ButtonFeedback_pressed()
	$Feedback.hide()


func _on_Later_pressed():
	$Feedback.hide()


func _on_FrontCreate_pressed():
	$EditorConfiguration.show()
