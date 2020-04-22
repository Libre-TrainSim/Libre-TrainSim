extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
var red = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/DotRed.png")
var green = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/DotGreen.png")
var orange = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/DotOrange.png")

func update_info(player):
	## Pantograph:
	$VBoxContainer/Pantograpgh.visible = player.electric
	if player.pantograph:
		$VBoxContainer/Pantograpgh/dot.texture = green
	else:
		if player.pantographUp:
			$VBoxContainer/Pantograpgh/dot.texture = orange
		else:
			$VBoxContainer/Pantograpgh/dot.texture = red
	
	## Doors:
	$VBoxContainer/Doors.visible = player.doors
	if not (player.doorLeft or player.doorRight):
		$VBoxContainer/Doors/dot.texture = green
	else:
		if player.doorsClosing:
			$VBoxContainer/Doors/dot.texture = orange
		else:
			$VBoxContainer/Doors/dot.texture = red
	
	## Control Type:
	if player.controlType == 0:
		$"VBoxContainer/Brakes-1".hide()
		$"VBoxContainer/Acceleration-1".hide()
	else:
		$"VBoxContainer/Brakes-0".hide()
		$"VBoxContainer/Acceleration-0".hide()
		
		
	## Brakes:
	if player.technicalSoll < 0:
		$"VBoxContainer/Brakes-0/dot".texture = red
		$"VBoxContainer/Brakes-1/dot".texture = red
	else:
		if player.command < 0:
			$"VBoxContainer/Brakes-0/dot".texture = orange
			$"VBoxContainer/Brakes-1/dot".texture = orange
		else:
			$"VBoxContainer/Brakes-0/dot".texture = green
			$"VBoxContainer/Brakes-1/dot".texture = green
	
	## Acceleration:
	if player.blockedAcceleration:
		$"VBoxContainer/Acceleration-0/dot".texture = red
		$"VBoxContainer/Acceleration-1/dot".texture = red
	else:
		$"VBoxContainer/Acceleration-0/dot".texture = green
		$"VBoxContainer/Acceleration-1/dot".texture = green
	
	## EnforcedBreake
	if player.enforcedBreaking:
		$VBoxContainer/EnforcedBreaking/dot.texture = red
	else:
		$VBoxContainer/EnforcedBreaking/dot.texture = green
	
	## SiFa
	$VBoxContainer/SiFa.visible = player.sifaEnabled
	if player.sifaTimer > 35:
		$VBoxContainer/SiFa/dot.texture = red
	elif player.sifaTimer > 25:
		$VBoxContainer/SiFa/dot.texture = orange
	else:
		$VBoxContainer/SiFa/dot.texture = green
	
	$VBoxContainer/Autopilot.visible = Root.EasyMode
	if player.automaticDriving:
		$VBoxContainer/Autopilot/dot.texture = green
	else:
		$VBoxContainer/Autopilot/dot.texture = red
