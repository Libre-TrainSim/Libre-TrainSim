extends Node

export (bool) var enable = false
var step = 0

var message_sent = false

func _process(delta):
	var player = get_parent()
	match step:
		0:
			send_message("Welcome to the demo of Libre Train Sim!\nPlease have in mind that this is an early alpha version, in which many features are missing, and some bugs are possible.\n\nIn this scenario you will drive a german suburban train ('S-Bahn') from Wolfsfurt to Buchenhain. The ride takes about 15 Minutes.\n\nLet's start the engines!\nPress 'B' to set up the pantograph and wait a bit.")
			if player.pantograph:
				next_step()
		1:
			send_message("Great! To close the Doors, press 'O'.\n\nWhith 'I' you can open the left one,\nwith 'P' you open the right door.)")
			if  not (player.doorRight or player.doorLeft):
				next_step()
		2:
			send_message("Now we are able to drive.\nOur departure is at 12:01. Let's wait for the depart message in the bottom left corner.")
			if player.currentStation == "":
				next_step()
		3:
			send_message("Let’s abort! Use the arrow keys to drive. \n\n\tPress the up arrow key to accelerate / release the brakes.\n\tPress the down arrow key to release acceleration / apply the brakes. \n\tPress the left arrow key to set acceleration and brakes to zero.\n\tPress the right arrow key to set to max power\n\nHint: You can see your current command at the right tachometer.")
			if Math.speedToKmH(player.speed) > 20:
				next_step()
		4:	
			send_message("Great, keep going on!\nYou have to stop at every station. Please have in mind that your train is almost long as the train station, so you have to halt at the very end of the platforms.\n\nHint: Whith 'F1' you can see your speed in the bottom right corner.")
			if Math.speedToKmH(player.speed) > 50:
				next_step()
		5: 
			send_message("Let me explain the Signals:\n\n\tGreen: Full speed ahead!\n\tOrange: The next signal is red.\n\tRed: You should halt in front of the signal and wait for green or orange.\n\tBlinking: At the next signal there is a lower speed limit.")
			if player.currentSpeedLimit == 100:
				next_step()
		6:
			send_message("Let me explain the speed limits:\nThe signs are showing the limits divided by 10. So for example '9' means 90 km/h.\nOrange signs / numbers are announcing, that after them (commonly about after 1000m) the announced speed limit will apply.\nAt the white signs / numbers the new speed limit is effective\n\n That was it. Have fun!\n\nHint: Now youw current Speed Limit is 100 kmh.")
			if player.currentStation == "Buchenhain" and player.isInStation:
				next_step()
		7:
			send_message("Thank you for playing!\nIf you had any problems or have suggestions for improvement, let me know it at https://github.com/Jean28518/LibreTrainSim\n\n(Press 'Esc' to exit the Game)")



func send_message(string):
	if not message_sent:
		message_sent = true
		get_parent().get_node("HUD").show_textbox_message(string)

	
func next_step():
	step += 1
	message_sent = false
