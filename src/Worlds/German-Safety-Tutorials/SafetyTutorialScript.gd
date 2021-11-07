extends Node

var scenario: String = ""
var world: Node = null
var player: LTSPlayer = null

var message_sent: bool = false
var send_message_timer: float = 0
var message: String = ""

var step: int = 0

var sifa_module: Node
var pzb_module: Node

var init_done: bool = false
func init() -> void:
	if Root.Editor:
		return
	
	scenario = Root.currentScenario
	world = find_parent("World")
	player = world.get_node("Players/Player")

	player.find_node("PZBModule")._force_enabled(true)
	player.find_node("SifaModule")._force_enabled(true)

	player.force_close_doors()
	player.force_pantograph_up()
	player.startEngine()
	player.enforced_braking = false
	player.command = 0
	player.soll_command = 0
	player.reverser = ReverserState.FORWARD

	if player != null and scenario == "Sifa":
		player.find_node("PZBModule").queue_free()
		sifa_module = player.find_node("SifaModule")
		sifa_module.set_process_unhandled_key_input(false)
	if player != null and scenario == "PZB":
		player.speed = Math.kmHToSpeed(120)
		player.currentSpeedLimit = 120
		player.find_node("SifaModule").queue_free()
		pzb_module = player.find_node("PZBModule")

	if scenario != null and player != null and world != null:
		init_done = true


func _process(delta: float) -> void:
	if not init_done:
		init()
		return
	if Root.Editor:
		set_process(false)
		return

	send_message(delta)

	if scenario == "Sifa":
		sifa(delta)
		return
	elif scenario == "PZB":
		pzb(delta)
		return

	message_sent = true


func sifa(delta: float) -> void:
	match step:
		0:
			message = tr("SIFA_TUTORIAL_1")
			if not sifa_module.get_node("SifaTimer").is_stopped():
				next_step()
		1:
			message = tr("SIFA_TUTORIAL_2") % InputHelper.make_strings_from_actions(["SiFa"])
			if sifa_module.stage == 1:
				next_step()
		2:
			message = tr("SIFA_TUTORIAL_3")
			if sifa_module.stage == 2:
				next_step()
		3:
			message = tr("SIFA_TUTORIAL_4")
			if sifa_module.stage == 3:
				next_step()
		4:
			message = tr("SIFA_TUTORIAL_5") % InputHelper.make_strings_from_actions(["SiFa"])
			sifa_module.set_process_unhandled_key_input(true)
			if sifa_module.stage == 0:
				next_step()
		5:
			message = tr("SIFA_TUTORIAL_6")
			yield( get_tree().create_timer(1, false), "timeout" )  # required, else 5 is skipped
			if Input.is_action_just_released("SiFa"):
				next_step()
		6:
			message = tr("SIFA_TUTORIAL_7")
			_sig_green_timer += delta
			if _sig_green_timer > 3:
				LoadingScreen.load_main_menu()


var _sig_green_timer: float = 0
var _restrictive_timer: float = 0
func pzb(delta: float) -> void:
	match step:
		0:
			message = tr("PZB_TUTORIAL_1")
			var signal1: Node = world.get_node("Signals/Signal")
			if player.global_transform.origin.distance_to(signal1.global_transform.origin) < 100:
				next_step()
		1:
			message = tr("PZB_TUTORIAL_2") % InputHelper.make_strings_from_actions(["pzb_ack"])
			if pzb_module.pzb_mode & pzb_module.PZBMode.MONITORING:
				next_step()
			elif pzb_module.pzb_mode & pzb_module.PZBMode.EMERGENCY:
				step = 100
				message_sent = false
				send_message_timer = 0
		100:
			message = tr("PZB_TUTORIAL_100")
		2:
			message = tr("PZB_TUTORIAL_3")
			if pzb_module.pzb_speed_limit == Math.kmHToSpeed(85):
				next_step()
			elif pzb_module.pzb_mode & pzb_module.PZBMode.EMERGENCY:
				step = 200
				message_sent = false
				send_message_timer = 0
		200:
			message = tr("PZB_TUTORIAL_200")
		3:
			message = tr("PZB_TUTORIAL_4")
			if pzb_module.pzb_mode & pzb_module.PZBMode._HIDDEN:
				next_step()
		4:
			message = tr("PZB_TUTORIAL_5") % InputHelper.make_strings_from_actions(["pzb_free"])
			#\n\nIn diesem Fall zeigt das nächste Signal Rot, das bedeutet, dass Sie Ihre Geschwindigkeit auf 65 km/h reduzieren müssen, bevor Sie den 500Hz Magneten erreichen. Bremsen Sie weiter ab."
			var pzbmagnet2: PZBMagnet = world.get_node("Signals/PZBMagnet2")
			if player.global_transform.origin.distance_to(pzbmagnet2.global_transform.origin) < 75:
				world.get_node("Signals/Signal2").set_status(SignalStatus.GREEN)
				next_step()
		5:
			message = tr("PZB_TUTORIAL_6") % InputHelper.make_strings_from_actions(["pzb_free"])
			if pzb_module.pzb_mode & pzb_module.PZBMode.IDLE:
				next_step()
		6:
			message = tr("PZB_TUTORIAL_7")
			var pzbmagnet5: PZBMagnet = world.get_node("Signals/PZBMagnet5")
			if player.global_transform.origin.distance_to(pzbmagnet5.global_transform.origin) < 200:
				next_step()
		7:
			message = tr("PZB_TUTORIAL_8")
			if pzb_module.pzb_mode & pzb_module.PZBMode._500Hz:
				next_step()
		8:
			message = tr("PZB_TUTORIAL_9")
			if player.speed == 0:
				next_step()
		9:
			message = tr("PZB_TUTORIAL_10")
			_sig_green_timer += delta
			if _sig_green_timer > 15:
				next_step()
		10:
			message = tr("PZB_TUTORIAL_11")
			_sig_green_timer += delta
			if _sig_green_timer > 20:
				world.get_node("Signals/Signal4").set_status(SignalStatus.GREEN)
			if not (pzb_module.pzb_mode & pzb_module.PZBMode._500Hz):
				next_step()
		11:
			_sig_green_timer = 0
			message = tr("PZB_TUTORIAL_12") % InputHelper.make_strings_from_actions(["pzb_free"])
			if pzb_module.pzb_mode == pzb_module.PZBMode.IDLE:
				next_step()
		12:
			message = tr("PZB_TUTORIAL_13") % InputHelper.make_strings_from_actions(["pzb_free"])
			_sig_green_timer += delta
			if _sig_green_timer > 3:
				LoadingScreen.load_main_menu()


func send_message(delta: float) -> void:
	send_message_timer += delta
	if not message_sent and send_message_timer > 1:
		message_sent = true
		player.show_textbox_message(message)


func next_step() -> void:
	step += 1
	message_sent = false
	send_message_timer = 0
