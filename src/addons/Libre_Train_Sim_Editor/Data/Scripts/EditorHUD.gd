extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_ShowSettings_pressed():
	if $Settings.visible:
		hide_settings()
		$ShowSettingsButton.text = "Show Settings"
	else:
		show_settings()
		$ShowSettingsButton.text = "Hide Settings"
	
func hide_settings():
	$Settings.hide()

func show_settings():
	$Settings.show()
