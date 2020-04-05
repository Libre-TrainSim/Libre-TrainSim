extends Spatial

## Variables for the train.
export (String) var route_ # Insert here the Names of the RailNodes seperated by a blank. For example: "Rail1 Rail2 Rail3". THe train will first drive Rail1, then it will drive on Rail2, and in the end at Rail3.
export (float) var speedLimit # Maximum Speed, the train can drive. (Unit: km/h)
export (float) var acceleration # Unit: m/(s*s)
export (float) var brakeAcceleration # Unit: m/(s*s)
export (float) var friction # (-> Speed = Speed - Speed * fritction (*delta) )
export (float) var length # Train length. Currently not used
export (float) var startPosition # on rail.
export var cameraFactor = 0.1

export (bool) var forward = true

export (bool) var debug 

var route = route_.split(" ") # Turns the String to a readable Array.
var speed = 0 # Initiats the speed. (Unit: m/s)
var distance = 0 # Initiates the Start Position of the Ride. Used for example the TrainStations.
var distanceOnRail  # It is the current position on the rail.
var currentRail # Node Reference to the current Rail on which we are driving.
var routeIndex = 0 # Index of the route Array.
onready var currentSpeedLimit = speedLimit # Unit: km/h
var nextSpeedLimit = -1 # it stores the value of the last "Warn Speed Limit Node". Currently not further used. Unit: km/h
var voltage = 0 # If this value = 0, the train wont drive unless you press ingame b

var command = -1 # If Command is < 0 the train will brake, if command > 0 the train will accelerate. Set by the player with Arrow Keys.
var currentAcceleration = 0 # Current Acceleration in m/(s*s)



var world # Node Reference to the world node.

var cameratZeroTranslation # Saves the camera position at the beginning. The Camera Position will be changed, when the train is accelerating, or braking

var time = []

onready var cameraNode = $Camera2

export (bool) var startUpGuide = false

func ready(): ## Called by World!
	$StartUpGuide.enable = startUpGuide
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = $Viewport.get_texture()
	$Screen.material_override.emission_texture = texture
	
	$DisplayLeft.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	texture = $DisplayLeft.get_texture()
	$ScreenLeft.material_override.emission_texture = texture
	
	cameratZeroTranslation = cameraNode.translation
	route = route_.split(" ")
	world = get_parent().get_parent()

	bake_route()
	
	## Get driving handled
	## Set the Train at the beginning of the rail, and after that set the distance on the Rail forward, which is standing in var startPosition
	distanceOnRail = startPosition#
	currentRail = get_parent().get_parent().get_node("Rails/"+route[routeIndex])
	if currentRail == null:
		print("Error: can't find Rail. Check the route of the Train "+ self.name)
		return
	print(currentRail)
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
	world.activeChunk = world.pos2Chunk(self.translation) 

var signalsforRail # Just stores the name of the Rail, which signals are loaded into "signals"

func _process(delta):
	#print(translation)
	if signalsforRail != currentRail.name:
		get_all_signals()
		signalsforRail = currentRail.name
	
	getCommand(delta)
	
	getSpeed(delta)
	if speed != 0:
		drive(delta)
	
	get_time()
	
	handleCamera(delta)
	
	check_pantograph(delta)
	
	check_doors(delta)
	
	$Viewport/Display.update_display(Math.speedToKmH(speed), soll_command, doorLeft, doorRight, doorsClosing)
	
	$DisplayLeft/ScreenLeft2.update_time(time)
	$DisplayLeft/ScreenLeft2.update_voltage(voltage)
	$DisplayLeft/ScreenLeft2.update_command(command)
	
	check_signals()
	
	update_Brake_Roll(soll_command, $BrakeRoll)
	
	update_Acc_Roll(soll_command, $AccRoll)
	
	check_station(delta)
	
	checkSpeedLimit(delta)
	
	
func get_time():
	time = world.time

	
		

	
	

var soll_command = -1
func getCommand(delta):
	
	
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
	
	if not pantograph and not debug:
		if command > 0:
			command = 0
		soll_command = -1
	elif (doorRight or doorLeft):
		if soll_command > 0:
			soll_command = 0
	
	var missing_value = (soll_command-command)
	if missing_value > 0.2:
		missing_value = 0.2
	if missing_value < -0.3:
		missing_value = -0.3
	command = command + missing_value*delta
	
	if (doorRight or doorLeft ) and command > 1:
		command 
	
	
		
		
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
	#print("Distance " + String(distanceOnRail))
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

var signals

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
	
	## Camera Rotation
#	var sollCameraRotation
#	if currentRail.radius == 0:
#		sollCameraRotation = -90
#	else:
#		sollCameraRotation = -1/currentRail.radius*3000.0 - 90.0
#	var missingCameraRotation = cameraNode.rotation_degrees.y - sollCameraRotation
#	cameraNode.rotation_degrees.y -= missingCameraRotation * 0.7 * delta

func get_all_signals():
	signals = currentRail.attachedSignals.duplicate(true)
	print(signals)

func check_signals():

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
			$HUD.send_Message("You overrun a red signal. The game is over!")
		signal.status = 0
	elif signal.type == "Station": ## Station
		print("Station: "+signal.stationName)
		if signal.regularStop:
			currentStation = signal.stationName
			isInStation = false
			stationTimer = 0
			stationBeginning = signal.beginningStation
			stationHaltTime = signal.stopTime
			distanceOnStationBeginning = distance
			endStation = signal.endStation
			stationLength = signal.stationLength
			depatureTime = [signal.departureH, signal.departureM, signal.departureS]
	elif signal.type == "Speed":
		currentSpeedLimit = signal.speed
	elif signal.type == "WarnSpeed":
		nextSpeedLimit = signal.warnSpeed
		print("Next Speed Limit: "+String(nextSpeedLimit))
	pass

## For Station:
var currentStation = ""
var arrivalTime = time
var isInStation = false
var stationTimer
var stationHaltTime
var stationLength
var distanceOnStationBeginning = 0
var endStation = false
var depatureTime
var stationBeginning
var wholeTrainNotInStation
func check_station(delta):
	if currentStation != "":
		if (speed == 0 and not isInStation and distance-distanceOnStationBeginning<length) and not wholeTrainNotInStation:
			wholeTrainNotInStation = true
			$HUD.send_Message("The End of your Train haven't already reached the Station. Please drive a bit forward, and try it again.")
		if ((speed == 0 and not isInStation and distance-distanceOnStationBeginning>=length) and (doorLeft or doorRight)) or (stationBeginning and not isInStation):
			arrivalTime = time
			var lateMessage = "."
			var minutesLater = -depatureTime[1] + arrivalTime[1] + (-depatureTime[0] + arrivalTime[0])*60
			if minutesLater > 0:
				lateMessage = ". You are " + String(minutesLater) + " minutes later." 
			$HUD.send_Message("Welcome to " + currentStation + lateMessage)
			stationTimer = 0
			
			isInStation = true
		elif (speed == 0 and isInStation ) :
			if stationTimer > stationHaltTime:
				if endStation:
					$HUD.send_Message("Scenario successfully finished!")
					currentStation = ""
					return
				if depatureTime[0] <= time[0] and depatureTime[1] <= time[1] and depatureTime[2] <= depatureTime[2]:
					$HUD.send_Message("You can now depart")
					currentStation = ""
		elif (stationLength<distance-distanceOnStationBeginning) and currentStation != "":
			$HUD.send_Message("You missed a station! Please drive further on.")
			currentStation = ""
		stationTimer += delta
		if (speed != 0):
			wholeTrainNotInStation = false


# Pantograph
var pantographTimer = 0
var pantograph = false
var pantographUp = false
export (float) var pantographTime = 5

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

var checkSpeedLimitTimer = 0
func checkSpeedLimit(delta):
	if Math.speedToKmH(speed) > currentSpeedLimit + 5 and checkSpeedLimitTimer <= 0:
		$HUD.send_Message("You are driving to fast! The current Limit is: "+String(currentSpeedLimit))
		checkSpeedLimitTimer = 10
		print(String(currentSpeedLimit) + " " + String(Math.speedToKmH(speed)))
	if checkSpeedLimitTimer > 0:
		checkSpeedLimitTimer -= delta
		
		

## Doors:
var doorsClosing = false
var doorsClosingTimer = 0
export var doorsClosingTime = 7
export var doorRight = false # If Door is Open, then its true
export var doorLeft = false
func check_doors(delta):
	if Input.is_action_just_pressed("doorClose"):
		if not doorsClosing:
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
		
		
func show_textbox_message(string):
	$HUD.show_textbox_message(string)
	
var baked_route ## Route, which will be generated at start of the game.
var baked_route_direction
func bake_route(): ## Generate the whole route for the train.
	baked_route = []
	baked_route_direction = [forward]
	baked_route.append(route[0])
	var currentR = world.get_node("Rails").get_node(baked_route[baked_route.size()-1]) ## imagine: current rail, which the train will drive later
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
		if translation.distance_to(currentR.translation) < translation.distance_to(currentR.endpos):
			currentF = true
		else:
			currentF = false
		baked_route_direction.append(currentF)
		if currentF: ## Forward
			currentpos = currentR.endpos
			currentrot = currentR.endrot
		else: ## Backward
			currentpos = currentR.startpos
			currentrot = currentR.startrot - 180.0
	print("Baking Route finished.")
	print("Baked Route: "+ String(baked_route))
	print("Baked Route: Direction "+ String(baked_route_direction))
	
	
	
	
