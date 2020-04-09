extends Spatial

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
## For your own scripting please use the attached Node "SpecificScripting"
################################################################################

################################################################################
## Interesting Variables for addOn Creators, which could be read out, (or set).
var soll_command = -1 # The input by the player. (0: Nothing, 1: Full acceleration, -1: Full Break). Shouldnt be lesser or greater than absolute 1
export (float) var acceleration # Unit: m/(s*s)
export (float) var brakeAcceleration # Unit: m/(s*s)
export (float) var friction # (-> Speed = Speed - Speed * fritction (*delta) )
export (float) var length # Train length. # Used in Train Stations for example
export (float) var speedLimit # Maximum Speed, the train can drive. (Unit: km/h)
export (int) var controlType = 0 # 0: Arrowkeys (Combi Control), 1: WASD (Separate brake and speed (1 Currently not implemented))
export (bool) var electric = true
var pantograph = false   ## Please just use this variable, if to check, if pantograph is up or down. true: up
var pantographUp = false ## is true, if pantograph is rising.
var voltage = 0 # If this value = 0, the train wont drive unless you press ingame "B". If voltage is "here", then its at 15. Unit (kV)
export (float) var pantographTime = 5
var speed = 0 # Initiats the speed. (Unit: m/s) ## You can convert it with var kmhSpeed = Math.speed2kmh(speed)
var distance = 0 # Initiates the complete driven distance since the startposition of the Ride. Used for example the TrainStations.
onready var currentSpeedLimit = speedLimit # Unit: km/h # holds the current speedlimit
var hardOverSpeeding = false # If Speed > speedlimit + 10 this is set to true
var nextSpeedLimit = -1 # it stores the value of the last "Warn Speed Limit Node". Currently not further used. Unit: km/h
var command = -1 # If Command is < 0 the train will brake, if command > 0 the train will accelerate. Set by the player with Arrow Keys.
var technicalSoll = 0 # Soll Command. This variable describes the "aim" of command
var blockedAcceleration = false ## If true, then acceleration is blocked. e.g.  brakes
var accRoll = 0 # describes the user input, (0 to 1)
var brakeRoll = -1 # describes the user input (0 to -1)
var currentAcceleration = 0 # Current Acceleration in m/(s*s) (Can also be neagtive)
var time = [23,59,59] ## actual time Indexes: [0]: Hour, [1]: Minute, [2]: Second
var ai = false # Currently not used. It will set by the scenario manger from world node.
var enforcedBreaking = false 
var overrunRedSignal = false
## set by the world scneario manager. Holds the timetable. PLEASE DO NOT EDIT THIS TIMETABLE! The passed variable displays, if the train was already there. (true/false)
var stations = {"nodeName" : [], "stationName" : [], "arrivalTime" : [], "departureTime" : [], "haltTime" : [], "stopType" : [], "passed" : []} 
## StopType: 0: Dont halt at this station, 1: Halt at this station, 2: Beginning Station, 3: End Station

## For current Station:
var currentStationName = "" # If we are in a station, this variable stores the current station name
var wholeTrainNotInStation = false # true if speed = 0, and the train is not fully in the station
var isInStation = false # true if the train speed = 0, the train is fully in the station, and doors were opened. - Until depart Message
var realArrivalTime = time # Time is set if train successfully arrived
var stationLength = 0 # stores the stationlength
var stationHaltTime = 0 # stores the minimal halt time from station 
var arrivalTime = time # stores the arrival time. (from the timetable)
var depatureTime = time # stores the departure time. (from the timetable)
var platformSide = 0 # Stores where the plaform is. #0: No platform, 1: at left side, 2: at right side, 3: at both sides

export var doors = true
export var doorsClosingTime = 7
var doorRight = false # If Door is Open, then its true
var doorLeft = false
var doorsClosing = false

export var brakingSpeed = 0.3
export var brakeReleaseSpeed = 0.2
export var accelerationSpeed = 0.2
export var accerationReleaseSpeed = 0.5

export var sifaEnabled = true
var sifa = false # If this is true, the player has to press the sifa key (Space)

export (String) var description = ""
export (String) var author = ""
export (String) var releaseDate = ""
export (String) var screenshotPath = ""

## callable functions:
# send_message()
# show_textbox_message(string)
################################################################################


var world # Node Reference to the world node.

export var cameraFactor = 0.1 ## The Factor, how much the camaere moves at acceleration and braking
var startPosition # on rail, given by scenario manager in world node
var forward = true # does the train drive at the rail direction, or against it? 
var debug  ## used for driving fast at the track, if true.
var route # String conataining all importand Railnames for e.g. switches. Set by the scenario manager of the world
var distanceOnRail  # It is the current position on the rail.
var currentRail # Node Reference to the current Rail on which we are driving.
var routeIndex = 0 # Index of the baked route Array.
var startRail # Rail, on which the train is starting. Set by the scenario manger of the world





onready var cameraNode = $Camera
var cameratZeroTranslation # Saves the camera position at the beginning. The Camera Position will be changed, when the train is accelerating, or braking



func ready(): ## Called by World!
	cameratZeroTranslation = cameraNode.translation
	world = get_parent().get_parent()
	
	route = route.split(" ")
	bake_route()
	
	if Root.EasyMode:
		pantograph = true
		controlType = 0
		sifaEnabled = false

	if not doors:
		doorLeft = false
		doorRight = false
		doorsClosing = false
	
	if not electric:
		pantograph = true
	
	if sifaEnabled:
		$Sound/SiFa.play()
	
	## Get driving handled
	## Set the Train at the beginning of the rail, and after that set the distance on the Rail forward, which is standing in var startPosition
	distanceOnRail = startPosition#
	currentRail = world.get_node("Rails/"+startRail)
	if currentRail == null:
		print("Error: can't find Rail. Check the route of the Train "+ self.name)
		return

	## Set Train to Route:
	if forward:
		rotation_degrees.y = currentRail.rotation_degrees.y
		self.translation = currentRail.translation
		# (For drinving on the rail or setting a object on the rail both functions getNextPos and getNextDeg mmust be called.
		self.translation = Math.getNextPos(currentRail.radius, self.get_translation(), self.rotation_degrees.y, distanceOnRail)
		self.rotation_degrees.y = Math.getNextDeg(currentRail.radius, self.rotation_degrees.y, distanceOnRail)
	else:
		rotation_degrees.y = currentRail.endrot + 180.0
		self.translation = currentRail.startpos
		distanceOnRail = startPosition
		# (For drinving on the rail or setting a object on the rail both functions getNextPos and getNextDeg mmust be called.
		self.translation = Math.getNextPos(currentRail.radius, self.get_translation(), self.rotation_degrees.y+180, distanceOnRail)
		self.rotation_degrees.y = Math.getNextDeg(-currentRail.radius, self.rotation_degrees.y, distanceOnRail)
	if debug: 
		command = 0
		soll_command = 0
	
	## get chunks handled:
	if not ai:
		world.activeChunk = world.pos2Chunk(self.translation) 

func _process(delta):
	if world == null:
		return
	getCommand(delta)
	
	getSpeed(delta)
	
	if speed != 0:
		drive(delta)
	
	handleCamera(delta)
	
	get_time()
	
	if electric:
		check_pantograph(delta)
	
	if not debug:
		check_security()
	
	if doors:
		check_doors(delta)
	
	check_signals()
	
	check_station(delta)
	
	checkSpeedLimit(delta)
	
	check_for_next_station(delta)
	
	check_for_player_help(delta)
	
	check_horn()
	
	if sifaEnabled:
		check_sifa(delta)
	
func get_time():
	time = world.time



func getCommand(delta):
	if controlType == 0: ## Combi Roll
		if Input.is_action_pressed("ui_up"):
			soll_command += 0.7 * delta
		if Input.is_action_pressed("ui_down"):
			soll_command -= 0.7 * delta
		if soll_command >= 1:
			soll_command = 1
		if soll_command <= -1:
			soll_command = -1
		if Input.is_action_pressed("ui_left"):
			soll_command = 0
		if Input.is_action_pressed("ui_right"):
			soll_command = 1
		if soll_command > 1: soll_command = 1
		if soll_command < -1: soll_command = -1
		
	elif controlType == 1: ## Seperate Brake and Acceleration
		if Input.is_action_pressed("acc+"):
			accRoll += 0.7 * delta
		if Input.is_action_pressed("acc-"):
			accRoll -= 0.7 * delta
		if accRoll > 1: accRoll = 1
		if accRoll < 0: accRoll = 0
		if Input.is_action_pressed("brake+"):
			brakeRoll -= 0.7 * delta
		if Input.is_action_pressed("brake-"):
			brakeRoll += 0.7 * delta
		if brakeRoll > 0: brakeRoll = 0
		if brakeRoll < -1: brakeRoll = -1
		
		soll_command = accRoll
		if brakeRoll != 0: soll_command = brakeRoll
		
	if soll_command == 0 or Root.EasyMode and not enforcedBreaking:
		blockedAcceleration = false
	if command < 0 and not Root.EasyMode:
		blockedAcceleration = true
	if (doorRight or doorLeft):
		blockedAcceleration = true
		
	technicalSoll = soll_command
	
	if technicalSoll > 0 and blockedAcceleration:
		technicalSoll = 0
	
	if enforcedBreaking and not debug:
		technicalSoll = -1
	
	
	var missing_value = (technicalSoll-command)
	if missing_value == 0: return
	if command > 0:
		if missing_value > 0:
			missing_value = accelerationSpeed
		if missing_value < 0:
			missing_value = -accerationReleaseSpeed
	if command < 0:
		if missing_value > 0:
			missing_value = brakeReleaseSpeed
		if missing_value < 0:
			missing_value = -brakingSpeed
	command = command + missing_value*delta
	if ((technicalSoll-command) > 0 and missing_value < 0) or ((technicalSoll-command) < 0 and missing_value > 0):
		command = technicalSoll

	
	
func getSpeed(delta):
	var sollAcceleration
	if command < 0:
		sollAcceleration = brakeAcceleration * command
	else:
		sollAcceleration = acceleration * command
	
	currentAcceleration = sollAcceleration
	speed += sollAcceleration * delta
	
	speed -= speed *friction * delta
	
	if speed < 0:
		speed = 0
	if Math.speedToKmH(speed) > speedLimit:
		speed = Math.kmHToSpeed(speedLimit)
		
	if debug:
		speed = 200*command

func drive(delta):
	var drivenDistance
	if forward:
		drivenDistance = speed * delta
		distanceOnRail += drivenDistance
		distance += drivenDistance
		if distanceOnRail > currentRail.length:
			drivenDistance = distanceOnRail - currentRail.length
			change_to_next_rail()
	else:
		drivenDistance = speed * delta
		distanceOnRail -= drivenDistance
		distance += drivenDistance
		if distanceOnRail < 0:
			drivenDistance = 0 - distanceOnRail
			change_to_next_rail()
	
	if forward:
		self.translation = Math.getNextPos(currentRail.radius, self.get_translation(), self.rotation_degrees.y, drivenDistance)
		self.rotation_degrees.y = Math.getNextDeg(currentRail.radius, self.rotation_degrees.y, drivenDistance)
	else:
		self.translation = Math.getNextPos(-currentRail.radius, self.get_translation(), self.rotation_degrees.y, drivenDistance)
		self.rotation_degrees.y = Math.getNextDeg(-currentRail.radius, self.rotation_degrees.y, drivenDistance)

func change_to_next_rail():
	print("Changing Rail..")
	routeIndex += 1
	currentRail =  world.get_node("Rails").get_node(baked_route[routeIndex])
	forward = baked_route_direction[routeIndex]
	
	if forward:
		##forward:
		distanceOnRail = 0
		self.translation = currentRail.translation
		self.rotation_degrees = currentRail.rotation_degrees
	else:
		##backward:
		distanceOnRail = currentRail.length
		self.translation = currentRail.endpos
		self.rotation_degrees = Vector3(0, currentRail.endrot+180,0)

func handleCamera(delta):
	## Camera x Position
	var sollCameraPosition = cameratZeroTranslation.x + (currentAcceleration * -cameraFactor)
	if speed == 0:
		sollCameraPosition = cameratZeroTranslation.x
	var missingCameraPosition = cameraNode.translation.x - sollCameraPosition
	cameraNode.translation.x -= missingCameraPosition * delta

## Signals:
var signalsRailName # Just stores the name of the Rail, which signals are loaded into "signals"
var signals # name of the signals, which are on the current track
func check_signals():
	if signalsRailName != currentRail.name:
		signals = currentRail.attachedSignals.duplicate(true)
	signalsRailName = currentRail.name
		
	for signalname in signals.keys():
		if forward and signalname != "" and signals[signalname] < distanceOnRail:
			handle_signal(signalname)
			signals.erase(signalname)
		if not forward and signalname != "" and signals[signalname] > distanceOnRail:
			handle_signal(signalname)
			signals.erase(signalname)
			
func handle_signal(signalname):
	var signal = world.get_node("Signals/"+signalname)
	if signal.forward != forward: return
	print("SIGNAL: " + signalname)
	if signal.type == "Signal": ## Signal
		if signal.speed != -1:
			currentSpeedLimit = signal.speed
		if signal.warnSpeed != -1: 
			nextSpeedLimit = signal.warnSpeed
		if signal.status == 0:
			send_message("You overrun a red signal. The game is over!")
			overrunRedSignal = true
		signal.status = 0
	elif signal.type == "Station": ## Station
		if not stations["nodeName"].has(signal.name):
			print("Station not found in repository, ingoring station. Maybe you are at the wrong track...")
			return
		var index = stations["nodeName"].find(signal.name)
		match stations["stopType"][index]:
			0:
				stations["passed"][index] = true
			1:
				endStation = false
				stationBeginning = false
			2:
				endStation = false
				stationBeginning = true
			3:
				endStation = true
				stationBeginning = false
		currentStationName = stations["stationName"][index]		
		isInStation = false
		platformSide = signal.platformSide
		stationHaltTime = stations["haltTime"][index]
		stationLength = signal.stationLength
		distanceOnStationBeginning = distance
		arrivalTime = stations["arrivalTime"][index]
		depatureTime = stations["departureTime"][index]
		doorOpenMessageSentTimer = 0
		doorOpenMessageSent = false
	elif signal.type == "Speed":
		currentSpeedLimit = signal.speed
	elif signal.type == "WarnSpeed":
		nextSpeedLimit = signal.warnSpeed
		print("Next Speed Limit: "+String(nextSpeedLimit))
	pass




## For Station: 
var endStation = false
var stationBeginning = true
var stationTimer = 0
var distanceOnStationBeginning = 0
var doorOpenMessageSentTimer = 0
var doorOpenMessageSent = false
func check_station(delta):
	if currentStationName != "":
		if (speed == 0 and not isInStation and distance-distanceOnStationBeginning<length) and not wholeTrainNotInStation:
			wholeTrainNotInStation = true
			send_message("The End of your Train haven't already reached the Station. Please drive a bit forward, and try it again.")
		if ((speed == 0 and not isInStation and distance-distanceOnStationBeginning>=length) and not (doorLeft or doorRight)):
			doorOpenMessageSentTimer += delta
			if doorOpenMessageSentTimer > 5 and not doorOpenMessageSent:
				send_message("Hint: You have to open the doors with 'i' or 'p', to arrive at the station.")
				doorOpenMessageSent = true
		if ((speed == 0 and not isInStation and distance-distanceOnStationBeginning>=length) and (doorLeft or doorRight)) or (stationBeginning and not isInStation):
			realArrivalTime = time
			var lateMessage = "."
			if not stationBeginning:
				var minutesLater = -arrivalTime[1] + realArrivalTime[1] + (-arrivalTime[0] + realArrivalTime[0])*60
				if minutesLater > 0:
					lateMessage = ". You are " + String(minutesLater) + " minutes later." 
			send_message("Welcome to " + currentStationName + lateMessage)
			stationTimer = 0
			
			isInStation = true
		elif (speed == 0 and isInStation ) :
			if stationTimer > stationHaltTime:
				if endStation:
					send_message("Scenario successfully finished!")
					stations["passed"][stations["stationName"].find(currentStationName)] = true
					currentStationName = ""
					nextStation = ""
					isInStation = false
					return
				if depatureTime[0] <= time[0] and depatureTime[1] <= time[1] and depatureTime[2] <= depatureTime[2]:
					send_message("You can now depart")
					stations["passed"][stations["stationName"].find(currentStationName)] = true
					currentStationName = ""
					nextStation = ""
					isInStation = false
		elif (stationLength<distance-distanceOnStationBeginning) and currentStationName != "":
			if isInStation:
				send_message("You departed earlier than allowed! Please wait for the depart message next time!")
			else:
				send_message("You missed a station! Please drive further on.")
			stations["passed"][stations["stationName"].find(currentStationName)] = true
			currentStationName = ""
			nextStation = ""
			isInStation = false
		stationTimer += delta
		if (speed != 0):
			wholeTrainNotInStation = false


## Pantograph
var pantographTimer = 0

func check_pantograph(delta):
	if Input.is_action_just_pressed("pantograph"):
		pantographUp = !pantographUp
		pantographTimer = 0
	if pantograph != pantographUp:
		pantographTimer+= delta
		if pantograph:
			pantograph = false
		if pantographTimer > pantographTime:
			pantograph = pantographUp
	if pantograph:
		voltage = voltage + (20-voltage)*delta*2.0
	else:
		voltage = voltage + (0-voltage)*delta*2.0
		


var checkSpeedLimitTimer = 0
func checkSpeedLimit(delta):
	if Math.speedToKmH(speed) > currentSpeedLimit + 5 and checkSpeedLimitTimer <= 0:
		send_message("You are driving to fast! The current Limit is: "+String(currentSpeedLimit))
		checkSpeedLimitTimer = 10
		print(String(currentSpeedLimit) + " " + String(Math.speedToKmH(speed)))
	hardOverSpeeding = Math.speedToKmH(speed) > currentSpeedLimit + 10
	if checkSpeedLimitTimer > 0:
		checkSpeedLimitTimer -= delta
	
func send_message(string):
	print("Sending Message: " + string )
	$HUD.send_Message(string)
		

## Doors:

var doorsClosingTimer = 0

func check_doors(delta):
	if Input.is_action_just_pressed("doorClose"):
		if not doorsClosing and (doorLeft or doorRight):
			doorsClosing = true
			$Sound/DoorsClose.play()
	if Input.is_action_just_pressed("doorLeft"):
		if not doorLeft and speed == 0:
			if not $Sound/DoorsOpen.playing: 
				$Sound/DoorsOpen.play()
			doorLeft = true
	if Input.is_action_just_pressed("doorRight"):
		if not doorRight and speed == 0:
			if not $Sound/DoorsOpen.playing: 
				$Sound/DoorsOpen.play()
			doorRight = true
	if doorsClosing:
		doorsClosingTimer += delta
	if doorsClosingTimer > doorsClosingTime:
		doorsClosing = false
		doorRight = false
		doorLeft = false
		doorsClosingTimer = 0
		
		

	
var baked_route ## Route, which will be generated at start of the game.
var baked_route_direction
var baked_route_railLength
func bake_route(): ## Generate the whole route for the train.
	baked_route = []
	baked_route_direction = [forward]
	
	baked_route.append(startRail)
	print("BAKED ROUTE:"  +String(baked_route))
	var currentR = world.get_node("Rails").get_node(baked_route[0]) ## imagine: current rail, which the train will drive later
	baked_route_railLength = [currentR.length]
	var currentpos
	var currentrot
	var currentF = forward
	if currentF: ## Forward
		currentpos = currentR.endpos
		currentrot = currentR.endrot
	else: ## Backward
		currentpos = currentR.startpos
		currentrot = currentR.startrot - 180.0
	
	while(true): ## Find next Rail
		var possibleRails = []
		for rail in world.get_node("Rails").get_children(): ## Get Rails, which are in the near of the endposition of current rail:
			if currentpos.distance_to(rail.startpos) < 0.1 and abs(Math.normDeg(currentrot) - Math.normDeg(rail.startrot)) < 1 and rail.name != currentR.name:
				possibleRails.append(rail.name)
			elif currentpos.distance_to(rail.endpos) < 0.1 and abs(Math.normDeg(currentrot) - Math.normDeg(rail.endrot+180.0)) < 1 and rail.name != currentR.name:
				possibleRails.append(rail.name)
		
		if possibleRails.size() == 0: ## If no Rail was found
			break
		elif possibleRails.size() == 1: ## If only one Rail is possible to switch
			baked_route.append(possibleRails[0])
		else: ## if more Rails are available:
			var selectedRail = possibleRails[0]
			for rail in possibleRails:
				for routeName in route:
					if routeName == rail:
						selectedRail = rail
						break
			baked_route.append(selectedRail)
		
		## Set Rail to "End" of newly added Rail
		currentR = world.get_node("Rails").get_node(baked_route[baked_route.size()-1]) ## Get "current Rail"
		if currentpos.distance_to(currentR.translation) < currentpos.distance_to(currentR.endpos):
			currentF = true
		else:
			currentF = false
		baked_route_direction.append(currentF)
		baked_route_railLength.append(currentR.length)
		if currentF: ## Forward
			currentpos = currentR.endpos
			currentrot = currentR.endrot
		else: ## Backward
			currentpos = currentR.startpos
			currentrot = currentR.startrot - 180.0
	print("Baking Route finished.")
	print("Baked Route: "+ String(baked_route))
	print("Baked Route: Direction "+ String(baked_route_direction))
	
func show_textbox_message(string):
	$HUD.show_textbox_message(string)
	
func get_all_upcoming_signalPoints_of_one_type(type): # returns an sorted aray with the names of the signals. The first entry is the nearest.
	var returnValue = []
	var index = routeIndex
	while(index != baked_route.size()):
		var rail = world.get_node("Rails").get_node(baked_route[index])
		var signalsAtRail = {}
		for signalName in rail.attachedSignals.keys():
			var signalN = world.get_node("Signals").get_node(signalName)
			if signalN == null:
				continue
			if signalN.type == type and signalN.forward == baked_route_direction[index]:
				if rail != currentRail:
					signalsAtRail[signalName] = signalN.onRailPosition
				else:
					if forward and signalN.onRailPosition > distanceOnRail:
						signalsAtRail[signalName] = signalN.onRailPosition
					elif not forward and  signalN.onRailPosition < distanceOnRail:
						signalsAtRail[signalName] = signalN.onRailPosition
						
		var sortedSignals = Math.sort_signals(signalsAtRail, baked_route_direction[index])
		for signalName in sortedSignals:
			returnValue.append(signalName)
		index += 1
	return returnValue

func get_distance_to_signal(signalName):
	var returnValue = 0
	if forward:
		returnValue += currentRail.length - distanceOnRail
	else:
		returnValue += distanceOnRail
	var index = routeIndex +1 
	var signalN = world.get_node("Signals").get_node(signalName)
	var searchedRailName =  signalN.attachedRail
	while(index != baked_route.size()):
#		print (String(baked_route[index]) + "  " + String(searchedRailName))
		if baked_route[index] != searchedRailName:
			returnValue += baked_route_railLength[index]
		else: ## End Rail Found (where Signal is Standing)
			if baked_route_direction[index]:
				returnValue += signalN.onRailPosition
			else:
				returnValue += baked_route_railLength[index] - signalN.onRailPosition
			break
		index += 1
	return returnValue

var nextStation = ""
var check_for_next_stationTimer = 0
var stationMessageSent = false
func check_for_next_station(delta):
	check_for_next_stationTimer += delta
	if check_for_next_stationTimer < 1: return
	else:
		check_for_next_stationTimer = 0
		if nextStation == "":
			var nextStations = get_all_upcoming_signalPoints_of_one_type("Station")
			print(nextStations)
			if nextStations.size() == 0:
				stationMessageSent = true
				return
			nextStation = nextStations[0]
			stationMessageSent = false
		
		
		#var station = world.get_node("Signals").get_node(nextStation)
		#print("The next station is: "+ stations["stationName"][stations["nodeName"].find(nextStation)]+ ". It is "+ String(int(get_distance_to_signal(nextStation))) + "m away.")
		
		if not stationMessageSent and get_distance_to_signal(nextStation) < 1001 and stations["nodeName"].has(nextStation) and stations["stopType"][stations["nodeName"].find(nextStation)] != 0:
			var station = world.get_node("Signals").get_node(nextStation)
			stationMessageSent = true
			send_message("The next station is: "+ stations["stationName"][stations["nodeName"].find(nextStation)]+ ". It is "+ String(int(get_distance_to_signal(nextStation)/100)*100+100) + "m away.")
		

func check_security():#
	var oldEnforcedBrake = 	enforcedBreaking
	enforcedBreaking = hardOverSpeeding or overrunRedSignal or not pantograph or sifaTimer > 33 
	if not oldEnforcedBrake and enforcedBreaking and speed > 0:
		$Sound/EnforcedBrake.play()

var check_for_player_helpTimer = 0
var check_for_player_helpTimer2 = 0
var check_for_player_helpSent = false
func check_for_player_help(delta):
	if not check_for_player_helpSent and speed == 0:
		check_for_player_helpTimer += delta
		if check_for_player_helpTimer > 8 and not pantographUp and not check_for_player_helpSent:
			send_message("Hint: Problems with the train? Under 'F2' you can see what is wrong")
			check_for_player_helpSent = true
		if check_for_player_helpTimer > 15 and command < -0.5 and not check_for_player_helpSent:
			send_message("Hint: Problems with the train? Under 'F2' you can see what is wrong")
			check_for_player_helpSent = true
	else:
		check_for_player_helpTimer = 0
	
	check_for_player_helpTimer2 += delta
	if blockedAcceleration and accRoll > 0 and brakeRoll == 0 and not (doorRight or doorLeft) and not overrunRedSignal and check_for_player_helpTimer2 > 10 and not isInStation:
		send_message("Hint: Try to set the acceleration to zero with 's', and give speed (=acceleration) with 'w' again.")
		check_for_player_helpTimer2 = 0
		

func check_horn():
	if Input.is_action_just_pressed("Horn"):
		$Sound/Horn.play()

var sifaTimer = 0
func check_sifa(delta):
	sifaTimer += delta
	if speed == 0 or Input.is_action_just_pressed("SiFa"):
		sifaTimer = 0
	sifa =  sifaTimer > 25
	$Sound/SiFa.stream_paused = not sifaTimer > 30
		
