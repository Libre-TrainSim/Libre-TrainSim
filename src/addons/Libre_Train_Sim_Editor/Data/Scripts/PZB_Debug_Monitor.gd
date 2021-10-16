extends Control

onready var pzb = get_parent()


func _ready() -> void:
	if not visible:
		set_process(false)


func _process(delta: float) -> void:
	$PanelContainer/GridContainer/PZBType.text = str(pzb.pzb_type)
	
	var pzb_mode = pzb.pzb_mode & 0b0000_1111
	var pzb_magnet = (pzb.pzb_mode & 0b1111_0000) >> 4

	match pzb_mode:
		0: $PanelContainer/GridContainer/PZBMode.text = "DISABLED"
		1: $PanelContainer/GridContainer/PZBMode.text = "IDLE"
		2: $PanelContainer/GridContainer/PZBMode.text = "MONITORING"
		4: $PanelContainer/GridContainer/PZBMode.text = "RESTRICTIVE"
		8: $PanelContainer/GridContainer/PZBMode.text = "EMERGENCY"

	match pzb_magnet:
		0: $PanelContainer/GridContainer/PZBMagnet.text = "NONE"
		1: $PanelContainer/GridContainer/PZBMagnet.text = "HIDDEN"
		2: $PanelContainer/GridContainer/PZBMagnet.text = "500Hz"
		4: $PanelContainer/GridContainer/PZBMagnet.text = "1000Hz"
		8: $PanelContainer/GridContainer/PZBMagnet.text = "2000Hz"
	
	$PanelContainer/GridContainer/PZBSpeed.text = str(Math.speedToKmH(pzb.pzb_speed_limit))
	
	if $"../AckTimer".is_stopped():
		$PanelContainer/GridContainer/AckTimer.text = "STOPPED"
	else:
		$PanelContainer/GridContainer/AckTimer.text = str($"../AckTimer".time_left)
	
	if $"../RestrictiveTimer".is_stopped():
		$PanelContainer/GridContainer/RestrictiveTimer.text = "STOPPED"
	else:
		$PanelContainer/GridContainer/RestrictiveTimer.text = str($"../RestrictiveTimer".time_left)
	
	if $"../153mMonitor".is_stopped:
		$PanelContainer/GridContainer/Monitor153m.text = "STOPPED"
	else:
		$PanelContainer/GridContainer/Monitor153m.text = str($"../153mMonitor".distance_left())
	
	if $"../250mMonitor".is_stopped:
		$PanelContainer/GridContainer/Monitor250m.text = "STOPPED"
	else:
		$PanelContainer/GridContainer/Monitor250m.text = str($"../250mMonitor".distance_left())
	
	if $"../700mMonitor".is_stopped:
		$PanelContainer/GridContainer/Monitor700m.text = "STOPPED"
	else:
		$PanelContainer/GridContainer/Monitor700m.text = str($"../700mMonitor".distance_left())
	
	if $"../1250mMonitor".is_stopped:
		$PanelContainer/GridContainer/Monitor1250m.text = "STOPPED"
	else:
		$PanelContainer/GridContainer/Monitor1250m.text = str($"../1250mMonitor".distance_left())

	$PanelContainer/GridContainer/Brakes.text = str(pzb.requires_emergency_braking)
