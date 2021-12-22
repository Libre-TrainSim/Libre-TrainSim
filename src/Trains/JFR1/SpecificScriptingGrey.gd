extends Node

onready var player: LTSPlayer = get_parent()

var is_ready: bool = false

func ready() -> void:
	if player.ai:
		return
	get_node("../Cabin/DisplayMiddle").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture: Texture = get_node("../Cabin/DisplayMiddle").get_texture()
	get_node("../Cabin/ScreenMiddle").material_override.emission_texture = texture
	get_node("../Cabin/DisplayMiddle/Display").blinkingTimer = player.get_node("HUD").get_node("IngameInformation/TrainInfo/Screen1").blinkingTimer

	get_node("../Cabin/DisplayLeft").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayLeft").get_texture()
	get_node("../Cabin/ScreenLeft").material_override.emission_texture = texture

	get_node("../Cabin/DisplayRight").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayRight").get_texture()
	get_node("../Cabin/ScreenRight").material_override.emission_texture = texture

	get_node("../Cabin/DisplayReverser").set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = get_node("../Cabin/DisplayReverser").get_texture()
	get_node("../Cabin/ScreenReverser").material_override.emission_texture = texture


func _process(_delta: float) -> void:
	if player.ai:
		return
	if not is_ready:
		is_ready = true
		ready()
	get_node("../Cabin/DisplayMiddle/Display").update_display(Math.speedToKmH(player.speed), player.technicalSoll, player.doorLeft, player.doorRight, player.doorsClosing, player.enforced_braking, player.automaticDriving, player.currentSpeedLimit, player.engine, player.reverser)

	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_time(player.world.time)
	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_voltage(player.voltage)
	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_command(player.command)

	get_node("../Cabin/DisplayRight/ScreenRight").update_display(player.station_table, player.current_station_table_index, player.is_in_station)

	update_Combi_Roll(player.soll_command, get_node("../Cabin/BrakeRoll"))
	update_reverser(player.reverser, get_node("../Cabin/Reverser"))


func update_reverser(command: int, node: Node) -> void:
	match command:
		ReverserState.FORWARD:
			node.rotation_degrees.y = -120
		ReverserState.NEUTRAL:
			node.rotation_degrees.y = -90
		ReverserState.REVERSE:
			node.rotation_degrees.y = -60


func update_Combi_Roll(command: float, node: Node) -> void:
	node.rotation_degrees.z = 45*command+1


func update_Brake_Roll(command: float, node: Node) -> void:
	var rotation: float
	if command > 0:
		rotation = 45
	else:
		rotation = 45 + command*90
	node.rotation_degrees.z = rotation


func update_Acc_Roll(command: float, node: Node) -> void:
	var rotation: float
	if command < 0:
		rotation = 45
	else:
		rotation = 45 - command*90
	node.rotation_degrees.z = rotation
