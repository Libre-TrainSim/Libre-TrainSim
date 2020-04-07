extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var player = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("../DisplayMiddle").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = get_node("../DisplayMiddle").get_texture()
	get_node("../ScreenMiddle").material_override.emission_texture = texture
	
	get_node("../DisplayLeft").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../DisplayLeft").get_texture()
	get_node("../ScreenLeft").material_override.emission_texture = texture
	
	get_node("../DisplayRight").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../DisplayRight").get_texture()
	get_node("../ScreenRight").material_override.emission_texture = texture
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_node("../DisplayMiddle/Display").update_display(Math.speedToKmH(player.speed), player.technicalSoll, player.doorLeft, player.doorRight, player.doorsClosing, player.enforcedBreaking, player.sifa)

	get_node("../DisplayLeft/ScreenLeft2").update_time(player.time)
	get_node("../DisplayLeft/ScreenLeft2").update_voltage(player.voltage)
	get_node("../DisplayLeft/ScreenLeft2").update_command(player.command)
	
	var stations = player.stations
	get_node("../DisplayRight/ScreenRight").update_display(stations["arrivalTime"], stations["departureTime"], stations["stationName"], stations["stopType"], stations["passed"], player.isInStation)
	
	if player.controlType == 0:
		update_Brake_Roll(player.soll_command, get_node("../BrakeRoll"))
		update_Acc_Roll(player.soll_command, get_node("../AccRoll"))
	else:
		update_Brake_Roll(player.brakeRoll, get_node("../BrakeRoll"))
		update_Acc_Roll(player.accRoll, get_node("../AccRoll"))



func update_Combi_Roll(command, node):
	node.rotation_degrees.z = 45*command+1

func update_Brake_Roll(command, node):
	var rotation
	if command > 0:
		rotation = 45
	else:
		rotation = 45 + command*90
	node.rotation_degrees.z = rotation

func update_Acc_Roll(command, node):
	var rotation
	if command < 0:
		rotation = 45
	else:
		rotation = 45 - command*90
	node.rotation_degrees.z = rotation
