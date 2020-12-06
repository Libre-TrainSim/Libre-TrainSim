extends Node

var scenario = Root.currentScenario
var world = find_parent("World")
var step = 0
var player
var message_sent = false

func _ready():
	if scenario == "The Basics" or scenario == "The Basics (Duplicate)":
		Root.EasyMode = true
	if scenario == "Advanced Train Driving":
		Root.EasyMode = false


func _process(delta):
	if world == null:
		world = find_parent("World")
	if player == null:
		player = world.get_node("Players/Player")
	send_message(delta)
	if scenario == "The Basics" or scenario == "The Basics (Duplicate)":
		basics(delta)
	if scenario == "Advanced Train Driving":
		advanced(delta)
	if scenario == "New Functions in 0.7":
		newFunctionsZeroDotSeven(delta)
	

func basics(delta):
	match step:
		0:
			message = "Welcome to Libre TrainSim!\nPlease have in mind that this is an early alpha version, in which many features are missing, and some bugs are possible.\nThe mode is now set to Easy.\n\nLet's start the engines!\nPress 'b' to set up the pantograph and wait a bit."
			if player.pantograph:
				next_step()
		1:
			message = "Great! To close the Doors, press 'o'.\n\nWith 'i' you can open the left one,\nwith 'p' you open the right door."
			if  not (player.doorRight or player.doorLeft):
				next_step()
		2:
			message = "Now we are able to drive.\nOur departure is at 12:00. Let's wait for the depart message in the bottom left corner."
			if player.currentStationName == "":
				next_step()
		3:
			message = "Let’s start! Use the arrow keys to drive. \n\n\tPress the up arrow key to accelerate / release the brakes.\n\tPress the down arrow key to release acceleration / apply the brakes. \n\nHint: You can see your current command at the right tachometer."
			if Math.speedToKmH(player.speed) > 20:
				next_step()
		4:
			message = "Ahead you can see an orange signal. That means that the next signal is going to be red. So make sure, you apply the brakes that you will stand before the red signal.\n\nWith the left arrow key you can easily set acceleration and brakes to zero. Try it, if you have brakes or accleration applied!"
			if Math.speedToKmH(player.speed) == 0 and not player.overrunRedSignal:
				world.get_node("Signals/Signal2").status = 1
				next_step()
		5:	
			message = "Great... \nWait... the signal is now green! Now we need to accelerate very fast.\nTo do this, simply press the right arrow key. It instantly sets the train to max power."
			if player.distanceOnRail > 700 and player.currentRail.name == "Rail":
				next_step()
		6: 
			message = "The signal in front of you is blinking.. what does this mean?\nIf a signal is blinking, then its announcing a new speed limit, which is lower than your current one.\nNo fear, the blinking signal just announce it, the speed limit will become effective at the signal behind it.\n\nIf e.g. the signal displays a 8, then the speed limit is 80 km/h.\nOrange signs/digits are always announcing limits,\nWhite signs/digits will set the speed limit effective."
			if player.currentRail.name == "Rail2":
				next_step()
		7:
			message = "In 600 meters there will be the next train station. Every station is announced in the left bottom corner, if its 1000m away. Certainly you already saw it.\n\nIt is recommended to brake down to about 70 or 60 km/h, and then brake softly if you are shortly before the train station.\nLets arrive!"
			if player.speed == 0 and player.currentStationName == "Tutorialbach" and not player.wholeTrainNotInStation:
				next_step()
		8:
			message = "Great, you arrived securely!\nNow you have to open the doors.\nWith 'i' you can open the left one, with 'p' the right one.\nIn our case we have to open the left one with 'i'."
			if player.isInStation:
				next_step()
		9:
			message = "Thank you for playing! You can now exit the game with 'Esc'"

func advanced(delta):
	match step:
		0:
			Root.EasyMode = false 
			message = "It is highly recommended, to do the 'Basics' tutorial first. The Easy-Mode is now deactivated.\n\nNow let's start the engines! Set up your train properly and wait to the departure at 12:00.\n\nHint to check all components of the Train, press 'F2'. Try it out!"
			if player.currentStationName == "" and not (player.doorRight or player.doorLeft):
				next_step()
		1:
			message = "Great!\nIf you disabled Easy Mode, some trains will have another control:\nThere exists a brake and a acceleration roll.\nThe brake roll you can use with 'a' and 'd'.\nThe acceleration roll you can use with 'w' and 's'.\n\nVery important:\nThe acceleration system locks, if you apply the doors or brake. To unlock the acceleration system, you have to close the doors and release the brakes completely. (The yellow bars at the left screen have to be completely dissapeared). Then you have to set the acceleration to zero with s. If it's zero, and everthing is green under 'F2' you can apply acceleration."
			if player.sifa:
				next_step()
		2:
			message = "Some trains have the 'SiFa' System. It's a security System, which ensures that the train driver is wake up during the train ride. Every 30 seconds you have to press the SiFa button, what is in our case 'space'. Otherwise it will initiate a enforced brake.\n\nNow it's time to press 'space' after closing this window."
			if player.currentRail.name == "Rail2":
				next_step()
		3:
			message = "Did you already send feedback? Then the developers know what you whish at most, and will work on this feature. You can find a feedback button at the main menu.\n\nThank you very much!"
			if player.isInStation: 
				next_step()
		4:
			message = "Thank you for playing! \nNow you are ready for every track in Libre TrainSim."
			
func newFunctionsZeroDotSeven(delta):
	match step:
		0:
			message = "At first: We don't want to drive ourself today.\n\nPress 'Ctrl + a' for activating the autopilot.\nIf you are in the easy mode, it will be available, and can turned on every time."
			if player.automaticDriving:
				next_step()
		1:
			message = "Great!\n\nAlso now an outer view of the train has been added. Press '2' for that."
			if player.cameraState == 2:
				next_step()#
		2: 
			message = "Nice! Just move your mouse to move around to look around.\nUse your mouse wheel to zoom in and out.\n\nAfter that please press '1' to get back to the cabin view."
			if player.cameraState == 1:
				next_step()
		3: 
			message = "If it is hard to read the display you can now press 'F1' to activate/deactivate the train HUD at your screen."
			if Input.is_key_pressed(KEY_F1):
				next_step()
		4: 
			message = "Did you already recognize the route information in the top left corner?\nIt displays following Information:\n- Distance to the next signal, and the signal status\n- Distance to the next speed limit and the speed limit itself\n-The distance and arrival time to the next station, or the departure of the current station\n\nYou can disable this by pressing 'F3'."
			if not player.isInStation:
				next_step()
		5: 
			message = "Also some more settings where added to the main menu.\nAnd shadows where added! Great, isn't it?\n\nEnjoy the ride!"
			if player.distanceOnRail > 500 and player.currentRail.name == "Rail":
				next_step()
		6: 
			message = "The track can now be pitched, or tended in curves. Do you see the tendency?\nNow more realistic tracks could be builded."
			if player.currentRail.name == "Rail2":
				next_step()
		7:
			message = "We have now a homepage!\nThe domain is: https://www.libre-trainsim.de/\n\nThere you get all information and news about Libre TrainSim."
			if player.currentRail.name == "Rail2" and player.distanceOnRail > 200:
				next_step()
		8: 
			message = "You are also able to create tracks for Libre TrainSim!\nCheck out the Button 'Create' in the main menu for that.\n\nBut creating an own track takes a lot of time and needs some endurance."
			if player.currentRail.name == "Rail2" and player.distanceOnRail > 400:
				next_step()
		9: 
			message = "We come to the next station!\n\nLets see the train arriving from the platform.\nPress '0' for the free camera."
			if player.cameraState == 0:
				next_step()
		10: 
			message = "Great!\n\nYou can move with WASD, and the mouse.\nIf you want to move fast, press 'shift' while pressing e.g. 'w'."
			if player.isInStation:
				next_step()
		11: 
			message = "Thanks for playing!\n\nIf you already didn't, try out the new Track U2-Nuremberg with the new train JFR1-Grey. It's a brand new metro track with all new features.\nBut Wolfsfurt-Buchenhain was updated too.\n\nHave fun with Libre TrainSim!"

			
		
	

var send_message_timer = 0
var message = ""
func send_message(delta):
	send_message_timer += delta
	if not message_sent and send_message_timer > 1:
		message_sent = true
		player.show_textbox_message(message)

	
func next_step():
	step += 1
	message_sent = false
	send_message_timer = 0
