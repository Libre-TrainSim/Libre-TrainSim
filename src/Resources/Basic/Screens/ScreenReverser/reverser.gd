extends Control

func _ready():
	$VBoxContainer/Forward.set_text(tr("FORWARD"))
	$VBoxContainer/Neutral.set_text(tr("NEUTRAL"))
	$VBoxContainer/Reverse.set_text(tr("REVERSE"))
