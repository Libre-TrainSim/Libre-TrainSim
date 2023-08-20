extends Node

onready var world: LTSWorld = get_parent()
var step: int = 0
var player: LTSPlayer
var message_sent: bool = false

const THE_BASICS := preload("res://Worlds/Tutorials/scenarios/The Basics.tres")
const ADVANCED_TUTORIAL := preload("res://Worlds/Tutorials/scenarios/Advanced Train Driving.tres")

func _ready() -> void:
	if Root.Editor:
		queue_free()
		return

	yield(get_tree(), "idle_frame")
	player = world.get_node("Players/Player")
	assert(player)
	if world.current_scenario == THE_BASICS:
		Root.EasyMode = true
		player.control_type = player.ControlType.COMBINED
	elif world.current_scenario == ADVANCED_TUTORIAL:
			Root.EasyMode = false
			if player.get_node_or_null("SafetySystems/SifaModule") != null:
				player.get_node_or_null("SafetySystems/SifaModule")._force_enabled(true)
			player.control_type = player.ControlType.SEPARATE
			if player.get_node_or_null("SafetySystems/PZBModule") != null:
				player.get_node_or_null("SafetySystems/PZBModule")._force_enabled(false)


func _process(delta: float) -> void:
	send_message(delta)
	if world.current_scenario == THE_BASICS:
		basics()
		return
	if world.current_scenario == ADVANCED_TUTORIAL:
		advanced()
		return
#	if scenario == THE_BASICS_MOBILE:
#		basics_mobile_version()
#		return
	message_sent = true


func basics() -> void:
	match step:
		0:
#			message = "Welcome to Libre TrainSim!\nPlease have in mind that this is an early alpha version, in which many features are missing, and some bugs are possible.\nThe mode is now set to Easy.\n\nLet's start the engines!\nPress 'b' to set up the pantograph and wait a bit.\nAfter 5 sconds you can press 'e' to start the engines!"
			message = TranslationServer.translate("TUTORIAL_0_0")
			if player.pantograph:
				next_step()
		1:
			# message = Press e to start engines
			message = TranslationServer.translate("TUTORIAL_0_10")
			if player.engine:
				next_step()
		2:
#			message = "Great! To close the Doors, press 'o'.\n\nWhith 'i' you can open the left one,\nwith 'p' you open the right door."
			message = TranslationServer.translate("TUTORIAL_0_1")
			if player.are_doors_closed():
				next_step()
		3:
#			message = "Now we are able to drive.\nOur departure is at 12:00. Let's wait for the depart message in the bottom left corner."
			message = TranslationServer.translate("TUTORIAL_0_2")
			if not player.is_in_station:
				next_step()
				world.get_node("Signals/Signal2").set_status(SignalStatus.RED)
		4:
#			message = "Let’s abort! Use the arrow keys to drive. \n\n\tPress the up arrow key to accelerate / release the brakes.\n\tPress the down arrow key to release acceleration / apply the brakes. \n\nHint: You can see your current command at the right tachometer."
			message = TranslationServer.translate("TUTORIAL_0_3")
			if Math.speed_to_kmh(player.speed) > 20:
				next_step()
		5:
#			message = "Ahead you see an orange signal. That means that the next signal is going to be red. So make sure, you apply the brakes that you will stand before the red signal.\n\nWith the left arrow key you can easily set acceleration and brakes to zero. Try it, if you have brakes or accleration applied!"
			message = TranslationServer.translate("TUTORIAL_0_4")
			if Math.speed_to_kmh(player.speed) == 0:
				world.get_node("Signals/Signal2").set_status(SignalStatus.GREEN)
				next_step()
		6:
#			message = "Great... \nWait... the signal is now green! Now we need to accelerate very fast.\nTo do this, simply press the right arrow key. It instantly sets the train to max power."
			message = TranslationServer.translate("TUTORIAL_0_5")
			if player.distance_on_rail > 700 and player.currentRail.name == "Rail":
				next_step()
		7:
#			message = "The signal in front of you is blinking.. what does this mean?\nIf a signal is blinking, then its announcing a new speed limit, which is lower than your current one.\nNo fear, the blinking signal just announce it, the speed limit will become effective at the signal behind it.\n\nIf e.g. the signal displays a 8, then the speed limit is 80 km/h.\nOrange signs/digits are always announcing limits,\nWhite signs/digits will set the speed limit effective."
			message = TranslationServer.translate("TUTORIAL_0_6")
			if player.currentRail.name == "Rail2":
				next_step()
		8:
#			message = "In 600 meters there will be the next train station. Every station is announced in the left bottom corner, if its 1000m away. Certainly you already saw it.\n\nIt is recommended to brake down to about 70 or 60 km/h, and then brake softly if you are shortly before the train station.\nLets arrive!"
			message = TranslationServer.translate("TUTORIAL_0_7")
			if player.distance_on_rail > 250 and player.currentRail.name == "Rail2":
				next_step()
		9:
			# message: Hint: If you don't know further on at any time or you just want to enjoy the ride, press 'ctr' + 'a' to activate the autopilot.
			message = TranslationServer.translate("TUTORIAL_0_11")
			print(player.whole_train_in_station)
			if is_zero_approx(player.speed) and player.current_station_table_entry.station_name == "Tutorialbach" and player.whole_train_in_station:
				next_step()
		10:
#			message = "Great, you arrived securly!\nNow you have to open the doors.\nWith 'i' you can open the left one, with 'p' the right one.\nIn our case we have to open the left one with 'i'."
			message = TranslationServer.translate("TUTORIAL_0_8")
			if player.is_in_station:
				next_step()
		11:
#			message = "Thank you for playing! You can now exit the game with 'Esc'"
			message = TranslationServer.translate("TUTORIAL_0_9")


func advanced() -> void:
	match step:
		0:
			message = TranslationServer.translate("TUTORIAL_1_0")
			if player.engine:
				next_step()
		1:
			message = TranslationServer.translate("TUTORIAL_1_6")
			if player.current_station_node == null and player.are_doors_closed():
				next_step()
		2:
			message = TranslationServer.translate("TUTORIAL_1_1")
			if player.get_node_or_null("SafetySystems/SifaModule") != null and player.get_node_or_null("SafetySystems/SifaModule").stage > 0:
				next_step()
			elif player.get_node_or_null("SafetySystems/SifaModule") == null:
				step = 4
		3:
			message = TranslationServer.translate("TUTORIAL_1_2")
			if player.distance_on_rail > 800:
				next_step()
		4:
			message = TranslationServer.translate("TUTORIAL_1_5")
			if player.currentRail.name == "Rail2":
				next_step()
		5:
			message = TranslationServer.translate("TUTORIAL_1_3")
			if player.is_in_station:
				next_step()
		6:
			message = TranslationServer.translate("TUTORIAL_1_4")


func basics_mobile_version() -> void:
	match step:
		0:
#			message = "Welcome to Libre TrainSim!\nPlease have in mind that this is an early alpha version, in which many features are missing, and some bugs are possible.\nThe mode is now set to Easy.\n\nLet's start the engines!\nPress 'b' to set up the pantograph and wait a bit.\nAfter 5 sconds you can press 'e' to start the engines!"
			message = TranslationServer.translate("TUTORIAL_4_0")
			player.get_node("HUD/MobileHUD/Pantograph").modulate = Color(1, 0.5, 0, 1)
			if player.pantograph:
				next_step()
		1:
			# message = Press e to start engines
			player.get_node("HUD/MobileHUD/Pantograph").modulate = Color(1, 1, 1, 1)
			player.get_node("HUD/MobileHUD/Engine").modulate = Color(1, 0.5, 0, 1)
			message = TranslationServer.translate("TUTORIAL_4_1")
			if player.engine:
				next_step()
		2:
#			message = Our departure is at 12:00. Let's wait for the depart message in the bottom left corner."
			message = TranslationServer.translate("TUTORIAL_4_2")
			player.get_node("HUD/MobileHUD/Engine").modulate = Color(1, 1, 1, 1)
			player.get_node("HUD/MobileHUD/Camera").modulate = Color(1, 0.5, 0, 1)
			if player.current_station_node == null:
				next_step()
		3:
#			message = "Great! To close the Doors, press 'o'.\n\nWhith 'i' you can open the left one,\nwith 'p' you open the right door."
			message = TranslationServer.translate("TUTORIAL_4_3")
			player.get_node("HUD/MobileHUD/Camera").modulate = Color(1, 1, 1, 1)
			player.get_node("HUD/MobileHUD/DoorClose").modulate = Color(1, 0.5, 0, 1)
			if player.are_doors_closed():
				next_step()
		4:
#			message = "Let’s abort! Use the arrow keys to drive. \n\n\tPress the up arrow key to accelerate / release the brakes.\n\tPress the down arrow key to release acceleration / apply the brakes. \n\nHint: You can see your current command at the right tachometer."
			message = TranslationServer.translate("TUTORIAL_4_4")
			player.get_node("HUD/MobileHUD/DoorClose").modulate = Color(1, 1, 1, 1)
			player.get_node("HUD/MobileHUD/Up").modulate = Color(1, 0.5, 0, 1)
			player.get_node("HUD/MobileHUD/Down").modulate = Color(1, 0.5, 0, 1)
			if Math.speed_to_kmh(player.speed) > 20:
				next_step()
		5:
#			message = "Ahead you see an orange signal. That means that the next signal is going to be red. So make sure, you apply the brakes that you will stand before the red signal.\n\nWith the left arrow key you can easily set acceleration and brakes to zero. Try it, if you have brakes or accleration applied!"
			message = TranslationServer.translate("TUTORIAL_4_5")
			player.get_node("HUD/MobileHUD/Up").modulate = Color(1, 1, 1, 1)
			player.get_node("HUD/MobileHUD/Down").modulate = Color(1, 0.5, 0, 1)
			if Math.speed_to_kmh(player.speed) == 0:
				world.get_node("Signals/Signal2").set_status(SignalStatus.GREEN)
				next_step()
		6:
#			message = "Great... \nWait... the signal is now green! Now we need to accelerate very fast.\nTo do this, simply press the right arrow key. It instantly sets the train to max power."
			message = TranslationServer.translate("TUTORIAL_4_6")
			player.get_node("HUD/MobileHUD/Down").modulate = Color(1, 1, 1, 1)
			player.get_node("HUD/MobileHUD/Up").modulate = Color(1, 0.5, 0, 1)
			if player.distance_on_rail > 700 and player.currentRail.name == "Rail":
				next_step()
		7:
			player.get_node("HUD/MobileHUD/Up").modulate = Color(1, 1, 1, 1)
#			message = "The signal in front of you is blinking.. what does this mean?\nIf a signal is blinking, then its announcing a new speed limit, which is lower than your current one.\nNo fear, the blinking signal just announce it, the speed limit will become effective at the signal behind it.\n\nIf e.g. the signal displays a 8, then the speed limit is 80 km/h.\nOrange signs/digits are always announcing limits,\nWhite signs/digits will set the speed limit effective."
			message = TranslationServer.translate("TUTORIAL_4_7")
			if player.currentRail.name == "Rail2":
				next_step()
		8:
#			message = "In 600 meters there will be the next train station. Every station is announced in the left bottom corner, if its 1000m away. Certainly you already saw it.\n\nIt is recommended to brake down to about 70 or 60 km/h, and then brake softly if you are shortly before the train station.\nLets arrive!"
			message = TranslationServer.translate("TUTORIAL_4_8")
			if player.distance_on_rail > 250 and player.currentRail.name == "Rail2":
				next_step()
		9:
			# message: Hint: If you don't know further on at any time or you just want to enjoy the ride, press 'ctr' + 'a' to activate the autopilot.
			message = TranslationServer.translate("TUTORIAL_4_9")
			player.get_node("HUD/MobileHUD/Autopilot").modulate = Color(1, 0.5, 0, 1)
			if player.speed == 0 and player.current_station_table_entry.station_name == "Tutorialbach" and not player.whole_train_in_station:
				next_step()
		10:
#			message = "Great, you arrived securly!\nNow you have to open the doors.\nWith 'i' you can open the left one, with 'p' the right one.\nIn our case we have to open the left one with 'i'."
			message = TranslationServer.translate("TUTORIAL_4_10")
			player.get_node("HUD/MobileHUD/Autopilot").modulate = Color(1, 1, 1, 1)
			player.get_node("HUD/MobileHUD/DoorLeft").modulate = Color(1, 0.5, 0, 1)
			if player.is_in_station:
				next_step()
		11:
#			message = "Thank you for playing! You can now exit the game with 'Esc'"
			message = TranslationServer.translate("TUTORIAL_4_11")
			player.get_node("HUD/MobileHUD/DoorLeft").modulate = Color(1, 1, 1, 1)
			player.get_node("HUD/MobileHUD/PauseButton").modulate = Color(1, 0.5, 0, 1)


var send_message_timer: float = 0
var message: String = ""
func send_message(delta: float) -> void:
	send_message_timer += delta
	if not message_sent and send_message_timer > 1:
		message_sent = true
		player.show_textbox_message(message)


func next_step() -> void:
	step += 1
	message_sent = false
	send_message_timer = 0
