extends Node

onready var player: LTSPlayer = get_parent()

var is_ready: bool = false


func ready() -> void:
	if player.ai: return
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
	if player.ai or player.failed_scenario: return
	if not is_ready:
		is_ready = true
		ready()
	get_node("../Cabin/DisplayMiddle/Display").update_display(Math.speed_to_kmh(player.speed), player.technicalSoll, player.doorLeft, player.doorRight, player.doorsClosing, player.enforced_braking, player.automaticDriving, player.currentSpeedLimit, player.engine, player.reverser)

	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_time(player.world.time)
	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_voltage(player.voltage)
	get_node("../Cabin/DisplayLeft/ScreenLeft2").update_command(player.command)

	get_node("../Cabin/DisplayRight/ScreenRight").update_display(player.station_table, player.current_station_table_index, player.is_in_station)

	if player.control_type == player.ControlType.COMBINED:
		update_Brake_Roll(player.soll_command, get_node("../Cabin/BrakeRoll"))
		update_Acc_Roll(player.soll_command, get_node("../Cabin/AccRoll"))
	else:
		update_Brake_Roll(player.brakeRoll, get_node("../Cabin/BrakeRoll"))
		update_Acc_Roll(player.accRoll, get_node("../Cabin/AccRoll"))

	update_reverser(player.reverser, get_node("../Cabin/Reverser"))


func update_reverser(command: int, node: Node) -> void:
	match command:
		ReverserState.FORWARD:
			node.rotation.y = deg2rad(-120)
		ReverserState.NEUTRAL:
			node.rotation.y = -0.5 * PI
		ReverserState.REVERSE:
			node.rotation.y = deg2rad(-60)


func update_Combi_Roll(command: float, node: Node) -> void:
	node.rotation.z = (0.25 * PI)*command + deg2rad(1)


func update_Brake_Roll(command: float, node: Node) -> void:
	var rotation: float
	if command > 0:
		rotation = 0.25 * PI
	else:
		rotation = (0.25 * PI) + (command * 0.5 * PI)
	node.rotation.z = rotation


func update_Acc_Roll(command: float, node: Node) -> void:
	var rotation: float
	if command < 0:
		rotation = 0.25 * PI
	else:
		rotation = (0.25 * PI) - (command * 0.5 * PI)
	node.rotation.z = rotation
