extends Control

onready var sifa: Node = get_parent()


func _ready() -> void:
	if not visible:
		set_process(false)


func _process(_delta: float) -> void:
	if $"../SifaTimer".is_stopped():
		$PanelContainer/GridContainer/SifaTimer.text = "STOPPED"
	else:
		$PanelContainer/GridContainer/SifaTimer.text = str($"../SifaTimer".time_left)

	if $"../WarningTimer".is_stopped():
		$PanelContainer/GridContainer/WarningTimer.text = "STOPPED"
	else:
		$PanelContainer/GridContainer/WarningTimer.text = str($"../WarningTimer".time_left)

	$PanelContainer/GridContainer/Reset.text = str(sifa.was_sifa_reset)
	$PanelContainer/GridContainer/Stage.text = str(sifa.stage)
	$PanelContainer/GridContainer/enforceBrakes.text = str(sifa.requires_emergency_braking)

