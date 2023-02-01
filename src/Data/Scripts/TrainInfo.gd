extends Control

var red: Texture = preload("res://Data/Misc/DotRed.png")
var green: Texture = preload("res://Data/Misc/DotGreen.png")
var orange: Texture = preload("res://Data/Misc/DotOrange.png")

func update_info(player: LTSPlayer) -> void:
	if player.engine:
		$ScrollContainer/VBoxContainer/Engine/dot.texture = green
	else:
		$ScrollContainer/VBoxContainer/Engine/dot.texture = red

	## Pantograph:
	$ScrollContainer/VBoxContainer/Pantograpgh.visible = player.electric
	if player.pantograph:
		$ScrollContainer/VBoxContainer/Pantograpgh/dot.texture = green
	else:
		if player.pantographUp:
			$ScrollContainer/VBoxContainer/Pantograpgh/dot.texture = orange
		else:
			$ScrollContainer/VBoxContainer/Pantograpgh/dot.texture = red

	## Doors:
	$ScrollContainer/VBoxContainer/Doors.visible = player.doors
	if not (player.doorLeft or player.doorRight):
		$ScrollContainer/VBoxContainer/Doors/dot.texture = green
	else:
		if player.doorsClosing:
			$ScrollContainer/VBoxContainer/Doors/dot.texture = orange
		else:
			$ScrollContainer/VBoxContainer/Doors/dot.texture = red
			
	## Brakes:
	if player.technicalSoll < 0:
		$"ScrollContainer/VBoxContainer/Brakes/dot".texture = red
	else:
		if player.command < 0:
			$"ScrollContainer/VBoxContainer/Brakes/dot".texture = orange
		else:
			$"ScrollContainer/VBoxContainer/Brakes/dot".texture = green

	## Reverser:
	if player.reverser == ReverserState.NEUTRAL:
		$ScrollContainer/VBoxContainer/Reverser/Dot.texture = red
	else:
		$ScrollContainer/VBoxContainer/Reverser/Dot.texture = green


	## Acceleration:
	if player.blockedAcceleration:
		$"ScrollContainer/VBoxContainer/Acceleration/dot".texture = red
	else:
		$"ScrollContainer/VBoxContainer/Acceleration/dot".texture = green

	## EnforcedBreake
	if player.enforced_braking:
		$ScrollContainer/VBoxContainer/EnforcedBreaking/dot.texture = red
	else:
		$ScrollContainer/VBoxContainer/EnforcedBreaking/dot.texture = green

	$ScrollContainer/VBoxContainer/Autopilot.visible = Root.EasyMode
	if player.automaticDriving:
		$ScrollContainer/VBoxContainer/Autopilot/dot.texture = green
	else:
		$ScrollContainer/VBoxContainer/Autopilot/dot.texture = red

	if player.frontLight:
		$ScrollContainer/VBoxContainer/FrontLight/dot.texture = green
	else:
		$ScrollContainer/VBoxContainer/FrontLight/dot.texture = red

	if player.insideLight:
		$ScrollContainer/VBoxContainer/InsideLight/dot.texture = green
	else:
		$ScrollContainer/VBoxContainer/InsideLight/dot.texture = red
