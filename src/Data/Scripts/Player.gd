class_name LTSPlayer
extends WorldObject

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
## For your own scripting please use the attached Node "SpecificScripting"
################################################################################

################################################################################
## Interesting Variables for addOn Creators, which could be read out, (or set).
var soll_command: float = -1 # The input by the player. (0: Nothing, 1: Full acceleration, -1: Full Break). |soll_command| should be lesser than 1.
export (float) var acceleration: float # Unit: m/(s*s)
export (float) var brakeAcceleration: float # Unit: m/(s*s)
export (float) var friction: float # (-> Speed = Speed - Speed * fritction (*delta) )
export (float) var length: float # Train length. # Used in Train Stations for example
export (float) var speedLimit: float # Maximum Speed, the train can drive. (Unit: km/h)

enum ControlType {
	COMBINED = 0,  # Arrow Keys (Combined Control)
	SEPARATE = 1   # WASD (Separate Brake and Speed)
}
export (ControlType) var control_type: int = ControlType.COMBINED
export (bool) var electric: bool = true
var pantograph: bool = false   ## Please just use this variable, if to check, if pantograph is up or down. true: up
var pantographUp: bool = false ## is true, if pantograph is rising.
var engine: bool = false ## Describes wether the engine of the train is running or not.
var voltage: float = 0 # If this value = 0, the train wont drive unless you press ingame "B". If voltage is "up", then its at 15 by default. Unit (kV)
export (float) var pantographTime: float = 5
var speed: float = 0 # Initiats the speed. (Unit: m/s) ## You can convert it with var kmhSpeed = Math.speed2kmh(speed)
onready var currentSpeedLimit: float = speedLimit # Unit: km/h # holds the current speedlimit
var command: float = -1 # If Command is < 0 the train will brake, if command > 0 the train will accelerate. Set by the player with Arrow Keys.
var technicalSoll: float = 0 # Soll Command. This variable describes the "aim" of command
var blockedAcceleration: bool = false ## If true, then acceleration is blocked. e.g.  brakes, dooors, engine,....
var accRoll: float = 0 # describes the user input, (0 to 1)
var brakeRoll: float = -1 # describes the user input (0 to -1)
var currentAcceleration: float = 0 # Current Acceleration in m/(s*s) (Can also be neagtive) - JJust from brakes and engines
var currentRealAcceleration: float = 0
var enforced_braking: bool = false

var reverser: int = ReverserState.NEUTRAL

## For Station Control:
var current_station_table_index: int = 0 # Displays the index of the next or current station of station_table
var current_station_table_entry: Dictionary = {}
var current_station_node: Node = null # If we are in a station, this variable stores the current station node, otherwise its null.
var whole_train_in_station: bool = false # true if speed = 0, and the train is fully in the station
var is_in_station := false # true if the train speed = 0, the train is fully in the station, and doors were opened. - Until depart Message
var real_arrival_time: int # Time is set if train successfully arrived
var route_distance_at_station_begin: float = 0 # distance of the station begin on route
const GOODWILL_DISTANCE: float = 10.0 # distance the player can overdrive a station, or it's train end isn't in the station.

export var doors := true # Defines, if this train has doors.
export var doorsClosingTime: float = 7
var doorRight: bool = false # If Door is Open, then its true
var doorLeft: bool = false
var doorsClosing: bool = false

export var brakingSpeed: float = 0.3
export var brakeReleaseSpeed: float = 0.2
export var accelerationSpeed: float = 0.2
export var accerationReleaseSpeed: float = 0.5

export (String) var description: String = ""
export (String) var author: String = ""
export (String) var releaseDate: String = ""
export (String) var screenshotPath: String = ""

## 0: Free View 1: Cabin View, 2: Outer View
enum CameraState {
	FREE_VIEW = 0,
	CABIN_VIEW = 1,
	OUTER_VIEW = 2
}
var camera_state: int = CameraState.CABIN_VIEW

var camera_mid_point: Vector3 = Vector3(0,2,0)
var cameraY: float = 90
var cameraX: float = 0

var mouseSensitivity: float = 10

var camera_distance: float = 20
var has_camera_distance_changed: bool = false
const CAMERA_DISTANCE_MIN: float = 5.0
const CAMERA_DISTANCE_MAX: float = 200.0

onready var ref_fov: float = $Camera.fov # reference FOV for camera movement multiplier
onready var camera_fov: float =$Camera.fov # current FOV
onready var camera_fov_soll: float = $Camera.fov # FOV user wants
const CAMERA_FOV_MIN: float = 20.0
const CAMERA_FOV_MAX: float = 90.0

var soundMode: int = 0 # 0: Interior, 1: Outer   ## Not currently used


export (Array, NodePath) var wagons: Array
export var wagonDistance: float = 0.5 ## Distance between the wagons
var wagonsVisible: bool = false
var wagonsI: Array = [] # Over this the wagons can be accessed

var automaticDriving: bool = false # Autopilot
var sollSpeed: float = 0 ## Unit: km/h
var sollSpeedTolerance: float = 4 # Unit km/h
var sollSpeedEnabled: bool = false ## Automatic Speed handlement

var nextSignal: Spatial = null ## Type: Node (object)
var distanceToNextSignal: float = 0
var nextSpeedLimitNode: Spatial = null ## Type: Node (object)
var distanceToNextSpeedLimit: float = 0

var ai: bool = false # It will be set by the scenario manger from world node. -> Every train which is not controlled by player has this value = true.
var rendering: bool = true
var despawning: bool = false
var initialSpeed: float = -1 ## Set by the scenario manager form the world node. Only works for ai. When == -1, it will be ignored

var frontLight: bool = false
var insideLight: bool = false

var last_driven_signal: Spatial = null ## In here the reference of the last driven signal is saved

## For Sound:
var currentRailRadius: float = 0

export (float) var soundIsolation: float = -8

var failed_scenario: bool = false # True, if player drive beyond last rail or drove over a red signal

## callable functions:
# send_message()
# show_textbox_message(string)
################################################################################


# type is LTSWorld, but I cannot use that because Godot is stupid and does some cyclic import or something
var world: Node # Node Reference to the world node.

export var cameraFactor: float = 1 ## The Factor, how much the camaere moves at acceleration and braking
export var camera_shaking_factor: float = 1.0 ## The Factor how much the camera moves at high speeds
var forward: bool = true # does the train drive at the rail direction, or against it?
var debug: bool  ## used for driving fast at the track, if true. Set by world node. Set only for Player Train
var route_information: Array # baked route from route manager, which is containing every rail_name and direction, in which the given rail should be driven. TODO: bake_route() and baked_route are complete obsolete now. We should switch in the future to only use this route_information Array for driving the train with every component. Calculated by RouteManager, delivered by world.
var distance_on_rail: float = 0  # It is the current position on the rail.
var distance_on_route: float = 0 # Current position on the whole route (Doesn't count the complete driven distance, will be resetted, if player drives loop)
var currentRail: Spatial # Node Reference to the current Rail on which we are driving.
var route_index: int = 0 # Index of the baked route Array.
var next_signal_index: int = 0 # Index of NEXT signal on baked route signal array
var spawn_information: Dictionary # Calculated by RouteManager, delivered by world.
var station_table: Array # Calculated by RouteManager, delivered by world.
var despawn_information: Dictionary # Calculated by RouteManager, delivered by world.

# Reference delta at 60fps
const refDelta: float = 0.0167 # 1.0 / 60

onready var cameraNode: Camera = $Camera
var cameraZeroTransform: Transform # Saves the camera position at the beginning. The Camera Position will be changed, when the train is accelerating, or braking

### SCORE SYSTEM ###
var score: int = 0
# scoring points
const SCORE_ARRIVE_AT_STATION: int = 100  # when you arrive at a station
# losing points
const SCORE_MULTIPLIER_TOO_FAST: float = 1.0  # score -= (speed - speedLimit) * multiplier
const SCORE_PENALTY_RED_LIGHT: int = 1000  # when you drive over a red light
const SCORE_PENALTY_ARRIVE_LATE: int = 10  # when you arrive at a station late
const SCORE_PENALTY_ARRIVE_VERY_LATE: int = 50  # when you arrive at a station more than a minute late
const SCORE_PENALTY_DEPART_EARLY: int = 50  # when you leave a station too early
const SCORE_PENALTY_EMERGENCY_BRAKE: int = 100  # when you get an emergency braking

### SIGNALS ###
signal passed_signal(signal_instance)
signal reverser_changed(reverser_state)
signal _textbox_closed


func ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	# Initiliaze Camera:
	$Camera.pause_mode = Node.PAUSE_MODE_PROCESS
	if not ai:
		$HUD.connect("textbox_closed", self, "_on_textbox_closed")
		cameraZeroTransform = cameraNode.transform
		cameraX = -$Camera.rotation.x
		cameraY = $Camera.rotation.y
		$Camera.current = true
	world = get_parent().get_parent()

	if ai:
		initialSpeed = Math.kmHToSpeed(spawn_information.initial_speed)
	if spawn_information.initial_speed_limit != -1:
		currentSpeedLimit = spawn_information.initial_speed_limit
	else:
		currentSpeedLimit = speedLimit
	if station_table.size() > 0 and station_table[0].type == StopType.BEGINNING:
		match world.get_signal(station_table[0].node_name).platform_side:
			PlatformSide.NONE:
				pass
			PlatformSide.LEFT:
				open_left_doors()
			PlatformSide.RIGHT:
				open_right_doors()
			PlatformSide.BOTH:
				open_left_doors()
				open_right_doors()

	if station_table.size() > 0:
		current_station_table_entry = station_table[current_station_table_index]

	# Obsolete. route_information contains every information about the route with directions. This is calculated by the route manager.
	for route_entry in route_information:
		route.append(route_entry.rail.name)
	forward = route_information[0].forward
	bake_route()

	if Root.EasyMode or ai:
		pantograph = true
		control_type = ControlType.COMBINED
		reverser = ReverserState.FORWARD

	if not doors:
		doorLeft = false
		doorRight = false
		doorsClosing = false

	if not electric:
		pantograph = true
		voltage = 15

	## Get driving handled
	## Set the Train at the beginning of the rail, and after that set the distance on the Rail forward, which is standing in var startPosition
	distance_on_rail = spawn_information.distance
	forward = spawn_information.forward
	currentRail = world.get_rail(spawn_information.rail_name)
	assert(currentRail != null)

	if forward:
		distance_on_route = spawn_information.distance
	else:
		distance_on_route = currentRail.length - spawn_information.distance

	## Set Train to Route:
	if forward:
		self.transform = currentRail.get_transform_at_distance(distance_on_rail)
	else:
		self.transform = currentRail.get_transform_at_distance(distance_on_rail)
		rotate_object_local(Vector3(0,1,0), PI)
	if debug and not ai:
		command = 0
		soll_command = 0

	spawnWagons()

	## Prepare Signals:
	if not ai:
		set_signalWarnLimits()
		set_signalAfters()

	if ai:
		soundMode = 1
		wagonsVisible = true
		automaticDriving = true
		$Camera.queue_free()
		$HUD.queue_free()
		camera_state = CameraState.CABIN_VIEW # Not for the camera, for the components who want to see, if the player sees the train from the inside or outside. AI is seen from outside whole time ;)
		insideLight = true
		frontLight = true

	Logger.log("Train " + name + " spawned sucessfully at " + currentRail.name)


var initialSwitchCheck: bool = false
var processLongDelta: float = 0.5 # Definition of Period, every which seconds the function is called.
func processLong(delta: float) -> void: ## All functions in it are called every (processLongDelta * 1 second).
	updateNextSignal(delta)
	updateNextSpeedLimit(delta)
	updateNextStation()
	checkDespawn()
	checkSpeedLimit(delta)
	check_for_next_station(delta)
	check_for_player_help(delta)
	checkFreeLastSignal()
	checkVisibility(delta)
	handle_station_signal()
	if automaticDriving:
		autopilot()

	if not initialSwitchCheck:
		updateSwitchOnNextChange()
		initialSwitchCheck = true


var processLongTimer: float = 0
func _process(delta: float):
	if get_tree().paused and not Root.ingame_pause:
		return

	if world == null:
		return

	if not ai:
		handleCamera(delta)

	if get_tree().paused:
		return

	processLongTimer += delta
	if processLongTimer > processLongDelta:
		processLong(processLongTimer)
		processLongTimer = 0

	if Root.EasyMode and not ai:
		if Input.is_action_just_pressed("autopilot"):
			jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
			toggle_automatic_driving()

	if sollSpeedEnabled:
		handleSollSpeed()

	getCommand(delta)

	getSpeed(delta)

	if speed != 0:
		drive(delta)

	if despawning:
		queue_free()

	if electric:
		check_pantograph(delta)

	if not debug and not ai:
		check_security()

	if doors:
		check_doors(delta)

	check_signals()

	check_station(delta)

	currentRailRadius = currentRail.radius

	if not ai:
		updateTrainAudioBus()

	handleEngine()

	check_overdriving_a_switch()


func _unhandled_key_input(event) -> void:
	if event.is_action_pressed("debug") and not event.is_echo() and not ai:
		debug = !debug
		if debug:
			send_message("DEBUG_MODE_ENABLED")
			force_close_doors()
			force_pantograph_up()
			startEngine()
			enforced_braking = false
			command = 0
			soll_command = 0
		else:
			enforced_braking = false
			command = 0
			soll_command = 0
			send_message("DEBUG_MODE_DISABLED")


func set_speed_to_zero() -> void:
	command = 0
	soll_command = 0
	speed = 0


func handleEngine() -> void:
	if not pantograph:
		engine = false
	if not ai and Input.is_action_just_pressed("engine"):
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		if not engine:
			startEngine()
		else:
			stopEngine()


func startEngine() -> void:
	if pantograph:
		engine = true


func stopEngine() -> void:
	engine = false


func _unhandled_input(event) -> void:
	if ai:
		return
	if get_tree().paused and not Root.ingame_pause:
		return
	if event is InputEventMouseMotion:
		mouseMotion = mouseMotion + event.relative

	# The following input events should only happen when the button is first pressed,
	# not when it is held down. Hence, we'll return early if it's an echo.
	if event.is_echo():
		return

	if event.is_action_pressed("acc+") and reverser == ReverserState.NEUTRAL:
		send_message("HINT_REVERSER_NEUTRAL", ["reverser+", "reverser-"])

	if event.is_action_pressed("InsideLight"):
		toggle_cabin_light()
	elif event.is_action_pressed("FrontLight"):
		toggle_front_light()

	if event.is_action_pressed("Horn"):
		horn()

	if event.is_action_pressed("reverser+"):
		change_reverser(+1)

	if event.is_action_pressed("reverser-"):
		change_reverser(-1)

	# Handle camera zoom
	if event.is_action_pressed("zoom_in") or event.is_action_pressed("zoom_out"):
		# zoom out
		if event.is_action_pressed("zoom_out"):
			if camera_state == CameraState.CABIN_VIEW:
				camera_fov_soll = camera_fov + 5
			elif camera_state == CameraState.OUTER_VIEW:
				camera_distance += camera_distance*0.2
				has_camera_distance_changed = true
		# zoom in
		if event.is_action_pressed("zoom_in"):
			if camera_state == CameraState.CABIN_VIEW:
				camera_fov_soll = camera_fov - 5
			elif camera_state == CameraState.OUTER_VIEW:
				camera_distance -= camera_distance*0.2
				has_camera_distance_changed = true

		camera_fov_soll = clamp(camera_fov_soll, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
		camera_distance = clamp(camera_distance, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)


func getCommand(delta: float) -> void:
	if control_type == ControlType.COMBINED and not automaticDriving:
		if Input.is_action_pressed("acc+"):
			soll_command += 0.7 * delta
		if Input.is_action_pressed("acc-"):
			soll_command -= 0.7 * delta
		if soll_command >= 1:
			soll_command = 1
		if soll_command <= -1:
			soll_command = -1
		if Input.is_action_pressed("brake-"):
			soll_command = 0
		if Input.is_action_pressed("brake+"):
			soll_command = 1
		if soll_command > 1: soll_command = 1
		if soll_command < -1: soll_command = -1

	elif control_type == ControlType.SEPARATE and not automaticDriving:
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

	if soll_command == 0 or Root.EasyMode or ai and not enforced_braking:
		blockedAcceleration = false
	if command < 0 and not Root.EasyMode and not ai:
		blockedAcceleration = true
	if (doorRight or doorLeft):
		blockedAcceleration = true
	if reverser == ReverserState.NEUTRAL:
		blockedAcceleration = true

	technicalSoll = soll_command

	if technicalSoll > 0 and blockedAcceleration:
		technicalSoll = 0

	if enforced_braking and not debug:
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


func getSpeed(delta: float) -> void:
	if initialSpeed != -1 and not enforced_braking and command > 0 and ai:
		speed = initialSpeed
		initialSpeed = -1
		return
	var lastspeed = speed
	## Slope:
	var currentSlope = currentRail.get_height_rot(distance_on_rail)
	if not forward:
		currentSlope = -currentSlope
	if reverser == ReverserState.REVERSE:
		currentSlope = -currentSlope
	var slopeAcceleration = -currentSlope/10
	speed += slopeAcceleration * delta

	var sollAcceleration
	if command < 0:
		## Brake:
		sollAcceleration = brakeAcceleration * command
		if speed < 0:
			sollAcceleration = -sollAcceleration
	else:
		sollAcceleration = acceleration * command

	currentAcceleration = sollAcceleration
	speed += sollAcceleration * delta

	speed -= speed *friction * delta

	if abs(speed) < 0.2 and command < 0 and abs(sollAcceleration) > abs(slopeAcceleration):
		speed = 0

#	if speed < 0:
#		speed = 0
	if Math.speed_to_kmh(speed) > speedLimit:
		speed = Math.kmh_to_speed(speedLimit)
	if delta != 0:
		currentRealAcceleration = (speed - lastspeed) * 1/delta
	if debug:
		speed = max(0, 200*command)


func drive(delta: float) -> void:
	var driven_distance = speed * delta
	if reverser == ReverserState.REVERSE:
		driven_distance = -driven_distance
	distance_on_route += driven_distance

	if not forward:
		driven_distance = -driven_distance
	distance_on_rail += driven_distance

	if distance_on_rail > currentRail.length or distance_on_rail < 0:
		change_to_next_rail()

	if not rendering: return
	if forward:
		self.transform = currentRail.get_transform_at_distance(distance_on_rail)
	else:
		self.transform = currentRail.get_transform_at_distance(distance_on_rail)
		rotate_object_local(Vector3(0,1,0), PI)


func change_to_next_rail() -> void:
	var old_radius = currentRail.radius
	if forward:
		old_radius = -old_radius

	if forward and (reverser == ReverserState.FORWARD):
		distance_on_rail -= currentRail.length
	if not forward and (reverser == ReverserState.REVERSE):
		distance_on_rail -= currentRail.length

	if not ai:
		Logger.vlog("Player: Changing Rail...")

	if reverser == ReverserState.REVERSE:
		route_index -= 1
	else:
		route_index += 1

	if baked_route.size() == route_index or route_index == -1:
		if baked_route_is_loop:
			if route_index == baked_route.size():
				route_index = 0
				distance_on_route -= complete_route_length
				next_signal_index = 0 # Just reset signal index, if we drive our normal route forward
			else: # If we drive backwards (reverse)
				route_index = baked_route.size() -1
				distance_on_route += complete_route_length
		else:
			if ai:
				Logger.log(name + ": Route no more rail found, despawning me...")
				despawn()
			else:
				fail_scenario(tr("FAILED_SCENARIO_DROVE_OVER_LAST_RAIL"))
				connect("_textbox_closed", LoadingScreen, "load_main_menu", [], CONNECT_ONESHOT)
				return


	currentRail =  world.get_node("Rails").get_node(baked_route[route_index])
	forward = baked_route_direction[route_index]

	var new_radius = currentRail.radius
	if forward:
		new_radius = -new_radius

	if not forward and (reverser == ReverserState.FORWARD):
		distance_on_rail += currentRail.length
	if forward and (reverser == ReverserState.REVERSE):
		distance_on_rail += currentRail.length

	# Get radius difference:
	if old_radius == 0: # prevent diviging through Zero, and take a very very big curve radius instead.
		old_radius = 1000000000
	if new_radius == 0: # prevent diviging through Zero, and take a very very big curve radius instead.
		new_radius = 1000000000
	var radius_difference_factor = abs(1/new_radius - 1/old_radius)*2000

	Logger.vlog(new_radius)
	Logger.vlog(old_radius)

	Logger.vlog(radius_difference_factor)
	curve_shaking_factor = radius_difference_factor * Math.speed_to_kmh(speed) / 100.0 * camera_shaking_factor


var mouseMotion: Vector2 = Vector2()
func remove_free_camera() -> void:
	if world.has_node("FreeCamera"):
		world.get_node("FreeCamera").queue_free()


func switch_to_cabin_view() -> void:
	camera_state = CameraState.CABIN_VIEW
	wagonsVisible = false
	cameraNode.transform = cameraZeroTransform
	cameraX = -cameraNode.rotation.x
	cameraY = cameraNode.rotation.y
	$Camera.fov = camera_fov # reset to first person FOV (zoom)
	$Cabin.show()
	remove_free_camera()
	$Camera.current = true


func switch_to_outer_view() -> void:
	wagonsVisible = true
	camera_state = CameraState.OUTER_VIEW
	has_camera_distance_changed = true # FIX for camera not properly setting itself until 1st input
	$Camera.fov = ref_fov # reset to reference FOV, zooming works different in this view
	$Cabin.hide()
	remove_free_camera()
	$Camera.current = true


func handleCamera(delta: float) -> void:
	if Input.is_action_just_pressed("Cabin View"):
		switch_to_cabin_view()
	if Input.is_action_just_pressed("Outer View"):
		switch_to_outer_view()
	if Input.is_action_just_pressed("FreeCamera"):
		$Cabin.hide()
		wagonsVisible = true
		camera_state = CameraState.FREE_VIEW
		get_node("Camera").current = false
		var cam = load("res://Data/Modules/FreeCamera.tscn").instance()
		cam.current = true
		world.add_child(cam)
		cam.owner = world
		cam.transform = transform.translated(camera_mid_point)

	var playerCameras: Array = get_tree().get_nodes_in_group("PlayerCameras")
	for i in range(3, 9):
		if Input.is_action_just_pressed("player_camera_" + str(i)) and playerCameras.size() >= i - 2:
			wagonsVisible = true
			camera_state = i
			playerCameras[i -3].current = true
			$Cabin.hide()
			remove_free_camera()

	if camera_state == CameraState.CABIN_VIEW:
		## Camera x Position
		var sollCameraPosition_x = cameraZeroTransform.origin.x + (currentRealAcceleration/20.0 * -cameraFactor * reverser)
		if speed == 0 or debug:
			sollCameraPosition_x = cameraZeroTransform.origin.x
		var missingCameraPosition_x = cameraNode.translation.x - sollCameraPosition_x
		var soll_camera_translation = cameraNode.translation
		soll_camera_translation.x -= missingCameraPosition_x * delta

		## Handle Camera Shaking:
		soll_camera_translation += get_camera_shaking(delta)
		cameraNode.translation = soll_camera_translation

		# FIXME: in the first frame, delta == 0, why?
		if mouseMotion.length() > 0 and delta > 0 and (Input.is_mouse_button_pressed(BUTTON_RIGHT) or Root.mobile_version):
			var motionFactor = (refDelta / delta * refDelta) * mouseSensitivity * (camera_fov / ref_fov) * deg2rad(1)
			cameraY += -mouseMotion.x * motionFactor
			cameraX += +mouseMotion.y * motionFactor
			cameraX = clamp(cameraX, deg2rad(-85), deg2rad(85))
			cameraNode.rotation.y = cameraY
			cameraNode.rotation.x = -cameraX
		mouseMotion = Vector2(0,0)


		if abs(camera_fov - camera_fov_soll) > 1:
			camera_fov += sign(camera_fov_soll-camera_fov)
			cameraNode.fov = camera_fov

	elif camera_state == CameraState.OUTER_VIEW:
		if mouseMotion.length() > 0 or has_camera_distance_changed:
			var motionFactor = (refDelta / delta * refDelta) * mouseSensitivity * deg2rad(1)
			cameraY += -mouseMotion.x * motionFactor
			cameraX += +mouseMotion.y * motionFactor
			cameraX = clamp(cameraX, deg2rad(-85), deg2rad(85))
			var cameraVector = Vector3(camera_distance, 0, 0)
			cameraVector = cameraVector.rotated(Vector3(0,0,1), cameraX).rotated(Vector3(0,1,0), cameraY)
			cameraNode.translation = cameraVector + camera_mid_point
			cameraNode.rotation.y = cameraY + (0.5 * PI)
			cameraNode.rotation.x = -cameraX
			mouseMotion = Vector2(0,0)
			has_camera_distance_changed = false


## Signals:
func check_signals() -> void:
	if reverser == ReverserState.REVERSE:
		# search through signals BACKWARDS, since we are driving BACKWARDS
		var search_array = baked_route_signal_names.slice(0, next_signal_index-1)
		search_array.invert()
		for signal_name in search_array:
			if baked_route_signal_positions[signal_name] > distance_on_route:
				next_signal_index -= 1 # order is important
				handle_signal(signal_name)
			else:
				break
	else:
		var search_array = baked_route_signal_names.slice(next_signal_index, baked_route_signal_names.size()-1)
		for signal_name in search_array:
			if baked_route_signal_positions[signal_name] < distance_on_route:
				next_signal_index += 1
				handle_signal(signal_name)
			else:
				break


func find_previous_speed_limit() -> float:
	# reset to max speed limit, in case no previous signal is found
	var return_value = speedLimit
	var search_array = get_all_previous_signals_of_types(["Signal", "Speed"])
	for signal_name in search_array:
		var signal_instance = world.get_node("Signals/"+signal_name)
		if signal_instance.speed != -1:
			return_value = signal_instance.speed
			break
	return return_value


func handle_signal(signal_name: String) -> void:
	nextSignal = null
	nextSpeedLimitNode = null
	var signal_passed = world.get_node("Signals/"+signal_name)
	if signal_passed.forward != forward: return

	Logger.log(name + ": SIGNAL: " + signal_passed.name)

	if signal_passed.type == "Signal": ## Signal
		if speed == 0: # Train is standing, and a signal get's activated that only happens at beginning or after jumping
			Logger.log("Ignoring signal " + signal_name)
			return
		if reverser == ReverserState.FORWARD:
			if signal_passed.speed != -1:
				currentSpeedLimit = signal_passed.speed
			if signal_passed.warn_speed != -1:
				pass
			if signal_passed.status == SignalStatus.RED:
				if not ai and not debug: # If player train
					fail_scenario(tr("FAILED_SCENARIO_DROVE_OVER_RED_SIGNAL"))
					score -= SCORE_PENALTY_RED_LIGHT
			else:
				free_signal_after_driven_train_length(last_driven_signal)
			signal_passed.set_status(SignalStatus.RED)
			last_driven_signal = signal_passed
		else:
			if signal_passed.speed != -1:
				currentSpeedLimit = find_previous_speed_limit()
			signal_passed.set_status(SignalStatus.GREEN)  # turn green, we are no longer in the block!
			# reset last signal, and turn it RED
			var prev = get_all_previous_signals_of_types(["Signal"])
			if prev.size() > 0:
				last_driven_signal = world.get_node("Signals/"+prev[0])
				last_driven_signal.set_status(SignalStatus.RED)

	elif signal_passed.type == "Station": ## Station
		if current_station_node != null: # Then the player didn't depart from the last station properly. That happens normally when player jumps between stations
			return
		var station_table_index: int = get_station_table_index_of_station_node_name(signal_passed.name)
		if station_table_index == -1:
			Logger.warn(name + ": Station not found in repository, ingoring station. Maybe you are at the wrong track, or the nodename in the station table of the player is incorrect...", self)
			return
		if current_station_table_index < station_table_index: # Train is standing, and a signal get's activated that only happens at beginning or after jumping
			if speed == 0:
				return
			else:
				Logger.err("Route incorrect! Reached station %s but the next_station should be %s." % [signal_passed.name, world.get_signal(station_table[current_station_table_index].node_name).name], self)

		current_station_table_index = station_table_index
		current_station_table_entry = station_table[current_station_table_index]
		if StopType.DO_NOT_STOP == current_station_table_entry.stop_type:
			current_station_table_index += 1
			return

		current_station_node = signal_passed
		is_in_station = false
		route_distance_at_station_begin = baked_route_signal_positions[current_station_node.name]

		if current_station_table_entry.stop_type != StopType.BEGINNING:
			for wagonI in wagonsI:
				wagonI.sendPersonsToDoor(current_station_node.platform_side, current_station_table_entry.leaving_persons/100.0)

	elif signal_passed.type == "Speed":
		if reverser == ReverserState.REVERSE:
			currentSpeedLimit = find_previous_speed_limit()
		else:
			currentSpeedLimit = signal_passed.speed
	elif signal_passed.type == "WarnSpeed":
		Logger.log(name + ": Next Speed Limit: "+String(signal_passed.warn_speed))
	elif signal_passed.type == "ContactPoint":
		signal_passed.activateContactPoint(name)

	emit_signal("passed_signal", signal_passed)


## For Station:

var _door_open_message_timer: float = 0
var _door_open_message_sent: bool = false
func check_station(delta: float) -> void:
	if current_station_node == null:
		return

	var distance_in_station: float = distance_on_route - route_distance_at_station_begin

	# handle code independent of speed
	# whole train drove further than distance is long (except first station)
	# if part of train is still within station, this will not trigger (allow player to back into station again)
	if distance_in_station > current_station_node.length+length+GOODWILL_DISTANCE and current_station_table_entry.stop_type != StopType.BEGINNING:
		# if it hadn't stopped yet, it missed the station
		send_message("YOU_MISSED_A_STATION")
		# finally, leave the station
		leave_current_station()
		return

	# If the player is in station and starts driving very early
	if speed != 0:
		if is_in_station and not (doorLeft or doorRight):
			score -= SCORE_PENALTY_DEPART_EARLY
			send_message("YOU_DEPARTED_EARLIER")
			leave_current_station()
		return

	whole_train_in_station = distance_in_station+GOODWILL_DISTANCE > length and distance_in_station < current_station_node.length+GOODWILL_DISTANCE
	# if train not fully in station, speed = 0
	if whole_train_in_station and current_station_table_entry.stop_type != StopType.BEGINNING and speed == 0:
		if distance_in_station+GOODWILL_DISTANCE < length:
			send_message("END_OF_YOUR_TRAIN_NOT_IN_STATION")
		if distance_in_station > current_station_node.length+GOODWILL_DISTANCE:
			send_message("FRONT_OF_YOUR_TRAIN_NOT_IN_STATION", ["reverser+", "reverser-"])

	# train in station but doors closed
	if not is_in_station and whole_train_in_station and not (doorLeft or doorRight):
		_door_open_message_timer += delta
		if _door_open_message_timer > 5 and not _door_open_message_sent:
			_door_open_message_timer = 0
			send_message("HINT_OPEN_DOORS", ["doorLeft", "doorRight"])
			_door_open_message_sent = true

	# train just now fully in station and doors opened, or first station -> welcome him
	if (not is_in_station and whole_train_in_station and \
			((doorLeft and current_station_node.platform_side == PlatformSide.LEFT) \
			or (doorRight and current_station_node.platform_side == PlatformSide.RIGHT)\
			or (doorLeft and doorRight and current_station_node.platform_side == PlatformSide.BOTH)\
			or current_station_node.platform_side == PlatformSide.NONE)\
			or (current_station_table_entry.stop_type == StopType.BEGINNING and not is_in_station)):
#		if current_station_table_entry.stop_type == StopType.BEGINNING:
#			nextStationNodeOnTrack = current_station_node
		is_in_station = true
		real_arrival_time = world.time
		score += SCORE_ARRIVE_AT_STATION

		# send a "you are x minutes late" message if player is late
		var lateMessage: String = ". "
		if current_station_table_entry.stop_type != StopType.BEGINNING:
			var secondsLater = real_arrival_time - current_station_table_entry.arrival_time
			if secondsLater < 60:
				lateMessage = ""
			elif secondsLater < 120:
				score -= SCORE_PENALTY_ARRIVE_LATE
				lateMessage += tr("YOU_ARE_LATE_1") + " %d %s" % [int(secondsLater/60), tr("YOU_ARE_LATE_2_ONE_MINUTE")]
			else:
				score -= SCORE_PENALTY_ARRIVE_VERY_LATE
				lateMessage += tr("YOU_ARE_LATE_1") + " %d %s" % [int(secondsLater/60), tr("YOU_ARE_LATE_2")]

		# send "welcome to station" message
		if current_station_table_entry.stop_type == StopType.BEGINNING:
			current_station_node.set_waiting_persons(current_station_table_entry.waiting_persons/100.0 * world.default_persons_at_station)
			match current_station_node.platform_side:
				PlatformSide.LEFT:
					open_left_doors()
				PlatformSide.RIGHT:
					open_right_doors()
				PlatformSide.BOTH:
					open_right_doors()
					open_left_doors()
			jEssentials.call_delayed(1.2, self, "send_message", [tr("WELCOME_TO") + " " + current_station_table_entry.station_name])
		else:
			send_message(tr("WELCOME_TO") + " " + current_station_table_entry.station_name + lateMessage)

		# play station announcement
		if !current_station_table_entry.arrival_sound_path.empty():
			if camera_state != CameraState.CABIN_VIEW:
				for wagon in wagonsI:
					jTools.call_delayed(1, wagon, "play_outside_announcement", [current_station_table_entry.arrival_sound_path])
			elif not ai:
				jTools.call_delayed(1, jAudioManager, "play_game_sound", [current_station_table_entry.arrival_sound_path])

		# send door position, so persons can get in
		if current_station_table_entry.stop_type != StopType.END:
			sendDoorPositionsToCurrentStation()

	# train waited long enough in station
	elif is_in_station and world.time >= current_station_table_entry.departure_time and \
			world.time >= real_arrival_time + current_station_table_entry.minimal_halt_time:
		# scenario finished if last station
		if current_station_table_entry.stop_type == StopType.END:
			show_textbox_message(tr("SCENARIO_FINISHED") + "\n\n" + tr("SCENARIO_SCORE") % score)
			connect("_textbox_closed", LoadingScreen, "load_main_menu", [], CONNECT_ONESHOT)
			leave_current_station()
			update_waiting_persons_on_next_station()
			return
		# else, send "you can depart" message once the time is up
		else:
			send_message("YOU_CAN_DEPART")
			if current_station_table_entry.departure_sound_path != "":
				if camera_state != CameraState.CABIN_VIEW:
					for wagon in wagonsI:
						wagon.play_outside_announcement(current_station_table_entry.departure_sound_path)
				elif not ai:
					jAudioManager.play_game_sound(current_station_table_entry.departure_sound_path)
			leave_current_station()



func leave_current_station() -> void:
	is_in_station = false
	current_station_table_index += 1
	if current_station_table_index < station_table.size():
		current_station_table_entry = station_table[current_station_table_index]
	current_station_node = null
	_door_open_message_sent = false
	nextStation = ""
	update_waiting_persons_on_next_station()


func update_waiting_persons_on_next_station() -> void:
	var station_nodes = get_all_upcoming_signals_of_types(["Station"])
	if station_nodes.size() != 0:
		var station_node = world.get_node("Signals/"+station_nodes[0])
		station_node.set_waiting_persons(current_station_table_entry.waiting_persons/100.0 * world.default_persons_at_station)


## Pantograph
var pantographTimer: float = 0
func force_pantograph_up() -> void:
	pantograph = true
	pantographUp = true


func rise_pantograph() -> void:
	if not pantograph:
		pantographUp = true
		pantographTimer = 0


func check_pantograph(delta: float) -> void:
	if Input.is_action_just_pressed("pantograph") and not ai:
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
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


var checkSpeedLimitTimer: float = 0
func checkSpeedLimit(delta: float) -> void:
	if Math.speed_to_kmh(speed) > currentSpeedLimit + 5 and checkSpeedLimitTimer > 5:
		checkSpeedLimitTimer = 0
		score -= int(round((Math.speed_to_kmh(speed) - currentSpeedLimit) * SCORE_MULTIPLIER_TOO_FAST))
		send_message(tr("YOU_ARE_DRIVING_TO_FAST") + " " +  String(currentSpeedLimit))
	checkSpeedLimitTimer += delta


func send_message(string : String, actions := []) -> void:
	if not ai:
		Logger.log("Sending Message: " + tr(string) % actions )
		$HUD.send_message(string, actions)


## Doors:
var doorsClosingTimer: float = 0
func open_left_doors() -> void:
	if not doorLeft and speed == 0 and not doorsClosing and doors:
		if not $Sound/DoorsOpen.playing:
			$Sound/DoorsOpen.play()
		doorLeft = true


func open_right_doors() -> void:
	if not doorRight and speed == 0 and not doorsClosing and doors:
		if not $Sound/DoorsOpen.playing:
			$Sound/DoorsOpen.play()
		doorRight = true


func close_doors() -> void:
	if not doorsClosing and (doorLeft or doorRight) and doors:
		doorsClosing = true
		$Sound/DoorsClose.play()


func force_close_doors() -> void:
	doorsClosing = true
	doorsClosingTimer = doorsClosingTime - 0.1


func check_doors(delta: float) -> void:
	if Input.is_action_just_pressed("doorClose") and not ai:
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		close_doors()
	if Input.is_action_just_pressed("doorLeft") and not ai:
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		if doorLeft:
			close_doors()
		else:
			open_left_doors()
	if Input.is_action_just_pressed("doorRight") and not ai:
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		if doorRight:
			close_doors()
		else:
			open_right_doors()

	if doorsClosing:
		doorsClosingTimer += delta

	if doorsClosingTimer > doorsClosingTime:
		doorsClosing = false
		doorRight = false
		doorLeft = false
		doorsClosingTimer = 0


## BAKING
func sort_signals_by_distance(a: Dictionary, b: Dictionary) -> bool:
	if a["distance"] < b["distance"]:
		return true
	return false

var route: Array = [] # Array of strings. Is obsolete, like bake_route().
var baked_route: Array = [] ## Route, which will be generated at start of the game. Array of strings
var baked_route_direction: Array = [] # Array of booleans
var baked_route_signal_names: Array = [] # sorted array of all signal names along the route
var baked_route_signal_positions: Dictionary = {} # dictionary of all signal positions along the route (key = signal name)
var baked_route_is_loop: bool = false
var complete_route_length: float = 0 # length of whole route. Exspecially used for loops in routes..

# Obsolete... Should be removed in the future. This is now also calculated by the route manager. But this doesn't allow loops for the time.
# For more information look to the comment at the variable definition of 'route_information'.
func bake_route() -> void: ## Generate the whole route for the train.
	baked_route = []
	baked_route_direction = [forward]

	baked_route.append(spawn_information.rail_name)
	var currentR = world.get_node("Rails").get_node(baked_route[0]) ## imagine: current rail, which the train will drive later

	var currentpos: Vector3
	var currentrot: float
	var currentF: bool = forward

	if currentF: ## Forward
		currentpos = currentR.end_pos
		currentrot = currentR.end_rot
	else: ## Backward
		currentpos = currentR.start_pos
		currentrot = currentR.start_rot - PI

	var rail_signals: Array = currentR.attached_signals

	rail_signals.sort_custom(self, "sort_signals_by_distance")
	if not currentF:
		rail_signals.invert()

	for signal_dict in rail_signals:
		var signal_instance: Spatial = world.get_node("Signals/"+signal_dict["name"])
		if signal_instance.forward != currentF:
			continue
		var position_on_route: float = complete_route_length
		if currentF:
			position_on_route += signal_dict["distance"]
		else:
			position_on_route += currentR.length - signal_dict["distance"]
		baked_route_signal_names.append(signal_dict["name"])
		baked_route_signal_positions[signal_dict["name"]] = position_on_route
	complete_route_length += currentR.length

	while(true): ## Find next Rail
		var possibleRails: Array = []
		for rail in world.get_node("Rails").get_children(): ## Get Rails, which are in the near of the end_position of current rail:
			if rail.name != currentR.name and currentpos.distance_to(rail.start_pos) < 0.2 and Math.angle_distance_rad(currentrot, rail.start_rot) < deg2rad(1):
				possibleRails.append(rail.name)
			elif rail.name != currentR.name and currentpos.distance_to(rail.end_pos) < 0.2 and Math.angle_distance_rad(currentrot, rail.end_rot+PI) < deg2rad(1):
				possibleRails.append(rail.name)

		var rail_candidate: String = ""
		if possibleRails.size() == 0: ## If no Rail was found
			break
		elif possibleRails.size() == 1: ## If only one Rail is possible to switch
			rail_candidate = possibleRails[0]
		else: ## if more Rails are available:
			var selectedRail = possibleRails[0]
			for rail in possibleRails:
				for routeName in route:
					if routeName == rail:
						selectedRail = rail
						break
			rail_candidate = selectedRail

		## Set Rail to "End" of newly added Rail
		currentR = world.get_node("Rails").get_node(rail_candidate) ## Get "current Rail"
		if currentpos.distance_to(currentR.translation) < currentpos.distance_to(currentR.end_pos):
			currentF = true
		else:
			currentF = false

		# Check for loop:
		if baked_route.has(rail_candidate) and baked_route_direction[baked_route.find(rail_candidate)] == currentF:
			Logger.log("found loop for " + name)
			baked_route_is_loop = true
			break
		else:
			baked_route.append(rail_candidate)
			baked_route_direction.append(currentF)


		# bake signals
		rail_signals = currentR.attached_signals
		rail_signals.sort_custom(self, "sort_signals_by_distance")
		if not currentF:
			rail_signals.invert()
		for signal_dict in rail_signals:
			var signal_instance: Spatial = world.get_node("Signals/"+signal_dict["name"])
			if signal_instance.forward != currentF:
				continue
			var position_on_route: float = complete_route_length
			if currentF:
				position_on_route += signal_dict["distance"]
			else:
				position_on_route += currentR.length - signal_dict["distance"]
			baked_route_signal_names.append(signal_dict["name"])
			baked_route_signal_positions[signal_dict["name"]] = position_on_route
		complete_route_length += currentR.length

		if currentF: ## Forward
			currentpos = currentR.end_pos
			currentrot = currentR.end_rot
		else: ## Backward
			currentpos = currentR.start_pos
			currentrot = currentR.start_rot - PI
	Logger.log(name + ": Baking Route finished:")
	Logger.log(name + ": Baked Route: "+ String(baked_route))
	Logger.log(name + ": Baked Route: Direction "+ String(baked_route_direction))


func show_textbox_message(string: String) -> void:
	$HUD.show_textbox_message(string)


func _on_textbox_closed() -> void:
	emit_signal("_textbox_closed")


# returns an sorted array with the names of the signals. The first entry is the nearest.
func get_all_upcoming_signals_of_types(types : Array) -> Array:
	var return_value: Array = []
	var search_array: Array = baked_route_signal_names.slice(next_signal_index, baked_route_signal_names.size()-1)
	if baked_route_is_loop:
		search_array.append_array(baked_route_signal_names.slice(0, next_signal_index-1))
	for signal_name in search_array:
		var signal_instance: Spatial = world.get_node("Signals/"+signal_name)
		if signal_instance == null: continue
		if types.has(signal_instance.type):
			return_value.append(signal_name)
	return return_value


# returns an sorted array with the names of the signals. The first entry is the nearest.
func get_all_previous_signals_of_types(types: Array) -> Array:
	var return_value: Array = []
	var search_array: Array = baked_route_signal_names.slice(0, next_signal_index-1)
	search_array.invert()
	if baked_route_is_loop:
		var additional_array: Array = baked_route_signal_names.slice(next_signal_index, baked_route_signal_names.size()-1)
		additional_array.invert()
		search_array.append_array(additional_array)
	for signal_name in search_array:
		var signal_instance: Spatial = world.get_node("Signals/"+signal_name)
		if signal_instance == null: continue
		if types.has(signal_instance.type):
			return_value.append(signal_name)
	return return_value


# If you expect negative values, try to subtract complete_route_length from return value.
func get_distance_to_signal(signal_name: String):
	var distance_without_loop: float = baked_route_signal_positions[signal_name] - distance_on_route
	if distance_without_loop > 0:
		return distance_without_loop
	else: # If next signal is beyond loop edge:
		return distance_without_loop + complete_route_length


var nextStation: String = ""
var _check_for_next_stationTimer: float = 0
var stationMessageSent: bool = false
func check_for_next_station(delta: float) -> void:  ## Used for displaying (In 1000m there is ...)
	_check_for_next_stationTimer += delta
	if _check_for_next_stationTimer < 1:
		return

	_check_for_next_stationTimer = 0
	if nextStation == "":
		var nextStations: Array = get_all_upcoming_signals_of_types(["Station"])
		if nextStations.size() == 0:
			stationMessageSent = true
			return
		nextStation = nextStations[0]
		stationMessageSent = false

	if not stationMessageSent and get_distance_to_signal(nextStation) < 1001 and current_station_table_entry.node_name == nextStation and current_station_table_entry.stop_type != StopType.DO_NOT_STOP and not is_in_station:
		stationMessageSent = true
		var distanceS: String = String(int(get_distance_to_signal(nextStation)/100)*100+100)
		if distanceS == "1000":
			distanceS = "1km"
		else:
			distanceS+= "m"
		send_message(tr("THE_NEXT_STATION_IS_1") + " " + current_station_table_entry.station_name + ". " + tr("THE_NEXT_STATION_IS_2")+ " " + distanceS + " " + tr("THE_NEXT_STATION_IS_3"))
		if camera_state != CameraState.OUTER_VIEW and camera_state != CameraState.FREE_VIEW and not ai:
			jTools.call_delayed(10, jAudioManager, "play_game_sound", [current_station_table_entry.approach_sound_path])


func check_security() -> void:
	var oldEnforcedBrake: bool = enforced_braking

	enforced_braking = not engine
	for sys in $SafetySystems.get_children():
		enforced_braking = enforced_braking or sys.requires_emergency_braking

	if not oldEnforcedBrake and enforced_braking and speed > 0 and not ai:
		score -= SCORE_PENALTY_EMERGENCY_BRAKE
		$Sound/EnforcedBrake.play()


var check_for_player_helpTimer: float = 0
var check_for_player_helpTimer2: float = 0
var check_for_player_helpSent: bool = false
func check_for_player_help(delta: float) -> void:
	if not check_for_player_helpSent and speed == 0:
		check_for_player_helpTimer += delta
		if check_for_player_helpTimer > 8 and not pantographUp and not check_for_player_helpSent:
			if not Root.mobile_version:
				send_message("HINT_F2", ["trainInfoAbove"])
			check_for_player_helpSent = true
		if check_for_player_helpTimer > 15 and command < -0.5 and not check_for_player_helpSent:
			if not Root.mobile_version:
				send_message("HINT_F2", ["trainInfoAbove"])
			check_for_player_helpSent = true
	else:
		check_for_player_helpTimer = 0

	check_for_player_helpTimer2 += delta
	if blockedAcceleration and accRoll > 0 and brakeRoll == 0 and not (doorRight or doorLeft) and check_for_player_helpTimer2 > 10 and not is_in_station:
		send_message("HINT_ADVANCED_DRIVING", ["acc-", "acc+"])
		check_for_player_helpTimer2 = 0


func horn() -> void:
	if not ai:
		jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
	$Sound/Horn.play()


func set_signalWarnLimits() -> void: # Called in the beginning of the route
	var signals: Array = get_all_upcoming_signals_of_types(["Signal"])
	var speedLimits: Array = get_all_upcoming_signals_of_types(["Speed"])
	for sl in speedLimits:
		signals.append(sl)
	var signalT: Dictionary = {"name" : signals, "position" : []}
	for signalS in signalT["name"]:
		signalT["position"].append(get_distance_to_signal(signalS))
	var sortedSignals: Array = Math.sort_signals(signalT, true)
	var limit: float = speedLimit
	for i in range(0,sortedSignals.size()):
		var signalN: Spatial = world.get_node("Signals").get_node(sortedSignals[i])
		if signalN.speed != -1:
			if signalN.speed < limit and i > 0:
				var signalNBefore = world.get_node("Signals").get_node(sortedSignals[i-1])
				if signalNBefore.type == "Signal":
					signalNBefore.warn_speed = signalN.speed
			limit = signalN.speed


func set_signalAfters() -> void:
	var signals: Array = get_all_upcoming_signals_of_types(["Signal"])
	for i in range(1,signals.size()):
		var signalN = world.get_node("Signals").get_node(signals[i-1])
		signalN.signal_after = signals[i]


func spawnWagons() -> void:
	var nextWagonPosition: float = spawn_information.distance
	for wagon in wagons:
		var wagonNode: Spatial = get_node(wagon)
		var newWagon: Spatial = wagonNode.duplicate()
		newWagon.show()
		newWagon.baked_route = baked_route.duplicate()
		newWagon.baked_route_direction = baked_route_direction.duplicate()
		newWagon.baked_route_is_loop = baked_route_is_loop
		newWagon.complete_route_length = complete_route_length
		newWagon.forward = forward
		newWagon.currentRail = currentRail
		newWagon.distance_on_rail = nextWagonPosition
		newWagon.player = self
		newWagon.world = world
		newWagon.add_to_group("Wagon")
		if forward:
			nextWagonPosition -= wagonNode.length + wagonDistance
		else:
			nextWagonPosition += wagonNode.length + wagonDistance
		get_parent().add_child(newWagon)
		newWagon.owner = self.owner
		wagonsI.append(newWagon)
		newWagon.initalize()

	# Handle Cabin:
	if ai:
		$Cabin.queue_free()
		return
	$Cabin.baked_route = baked_route
	$Cabin.baked_route_direction = baked_route_direction
	$Cabin.baked_route_is_loop = baked_route_is_loop
	$Cabin.complete_route_length = complete_route_length
	$Cabin.forward = forward
	$Cabin.currentRail = currentRail
	$Cabin.distance_on_rail = nextWagonPosition
	$Cabin.player = self
	$Cabin.world = world
	$Cabin.add_to_group("Cabin")


func toggle_automatic_driving() -> void:
	reverser = ReverserState.FORWARD
	automaticDriving = !automaticDriving
	if not automaticDriving:
		sollSpeedEnabled = false
		Logger.log("AutomaticDriving disabled")
	else:
		Logger.log("AutomaticDriving enabled")


var autoPilotInStation: bool = true
var updateNextSignalTimer: float = 0
func updateNextSignal(delta):
	if nextSignal == null:
		var upcoming = get_next_signal()
		if upcoming == "":
			return
		nextSignal = world.get_node("Signals/"+upcoming)
		updateNextSignalTimer = 1 ## Force Update Signal
	updateNextSignalTimer += delta
	if updateNextSignalTimer > 0.2:
		distanceToNextSignal = get_distance_to_signal(nextSignal.name)
		updateNextSignalTimer = 0


func get_next_signal() -> String:
	var all: Array = get_all_upcoming_signals_of_types(["Signal"])
	if all.size() > 0:
		return all[0]
	return ""


var updateNextSpeedLimitTimer: float = 0
func updateNextSpeedLimit(delta: float) -> void:
	if nextSpeedLimitNode == null:
		nextSpeedLimitNode = get_next_SpeedLimit()
		if nextSpeedLimitNode == null:
			return
		updateNextSpeedLimitTimer = 1 ## Force Update Signal
	updateNextSpeedLimitTimer += delta
	if updateNextSpeedLimitTimer > 0.2:
		distanceToNextSpeedLimit = get_distance_to_signal(nextSpeedLimitNode.name)
		updateNextSpeedLimitTimer = 0


func get_next_SpeedLimit() -> Spatial:
	var allLimits: Array = get_all_upcoming_signals_of_types(["Speed", "Signal"])
	for limit in allLimits:
		if world.get_node("Signals/" + limit).speed != -1:
			return world.get_node("Signals/" + limit) as Spatial
	return null


var distanceToNextStation: float = 0
var updateNextStationTimer: float = 0
func updateNextStation() -> void:  ## Used for Autopilot
	if current_station_table_index >= station_table.size():
		distanceToNextStation = 0
		return
	# Because get_distance_to_signal can regulary only used, if signal is before the train. In this case, signal is after the train,
	# so get_distance_to_signal thinks, we are at a loop edge, and adds the complete route length to it. So we remove the complete_route_length here.
	if not is_in_station:
		distanceToNextStation = get_distance_to_signal(current_station_table_entry.node_name) + world.get_signal(current_station_table_entry.node_name).length
		if distanceToNextStation > complete_route_length:
			distanceToNextStation -= complete_route_length

# If signal of the current station was set to green, this is stored in this value.
var _signal_was_freed_for_station_index: int = -1
func handle_station_signal():
	# Signal of next station already set to green or we reached endstation
	if current_station_table_index == _signal_was_freed_for_station_index or station_table.size() == 0\
	or _signal_was_freed_for_station_index+1 > station_table.size():
		return
	var station_table_entry: Dictionary = station_table[_signal_was_freed_for_station_index+1]
	var signal_node: Node = world.get_signal(world.get_signal(station_table_entry.node_name).assigned_signal)
	if signal_node == null:
		_signal_was_freed_for_station_index += 1
		return
	var departure_time: int = station_table_entry.departure_time
	var signal_free_time: int = departure_time - station_table_entry.signal_time
	if signal_free_time <= world.time and station_table_entry.stop_type != StopType.END:
		signal_node.set_status(1)
		_signal_was_freed_for_station_index += 1



func get_next_station_name_on_track() -> String:
	var all: Array = get_all_upcoming_signals_of_types(["Station"])
	if all.size() > 0:
		return all[0]
	return ""

func autopilot() -> void:
	debugLights(self)
	if not pantographUp:
		pantographUp = true
	if not engine:
		startEngine()
	if is_in_station:
		sollSpeed = 0
		return
	if (doorLeft or doorRight) and not doorsClosing:
		close_doors()
	var sollSpeedArr: Dictionary = {}

	## Red Signal:
	sollSpeedArr[0] = speedLimit
	if nextSignal != null and nextSignal.status == SignalStatus.RED:
		sollSpeedArr[0] = min(sqrt(15*distanceToNextSignal+20), (distanceToNextSignal+10)/4.0)
		if sollSpeedArr[0] < 10:
			sollSpeedArr[0] = 0
	## Next SpeedLimit
	sollSpeedArr[1] = currentSpeedLimit
	if nextSpeedLimitNode != null and nextSpeedLimitNode.speed != -1:
		sollSpeedArr[1] = nextSpeedLimitNode.speed + (distanceToNextSpeedLimit-50)/((speed+2)/2)
		if (distanceToNextSignal < 50):
			sollSpeedArr[1] = nextSpeedLimitNode.speed

	## Next Station:
	sollSpeedArr[2] = speedLimit
	if not is_in_station and station_table.size() != 0:
		if get_station_table_index_of_station_node_name(current_station_table_entry.node_name) != -1:
			sollSpeedArr[2] = min(sqrt(15*distanceToNextStation+20), (distanceToNextStation+10)/4.0)
			if sollSpeedArr[2] < 10:
				sollSpeedArr[2] = 0


	## Open Doors:
	if (current_station_node != null and speed == 0 and not is_in_station and distance_on_route - route_distance_at_station_begin >= length):
		if current_station_node.platform_side == PlatformSide.LEFT:
			open_left_doors()
		elif current_station_node.platform_side == PlatformSide.RIGHT:
			open_right_doors()
		elif current_station_node.platform_side == PlatformSide.BOTH:
			open_left_doors()
			open_right_doors()

	sollSpeedArr[3] = currentSpeedLimit

	sollSpeed = sollSpeedArr.values().min()
	sollSpeedEnabled = true


func handleSollSpeed() -> void:
	var speedDifference: float = sollSpeed - Math.speed_to_kmh(speed)
	if abs(speedDifference) > 4:
		if speedDifference > 10:
			soll_command = 1
		elif speedDifference < 10 and speedDifference > 0:
			soll_command = 0.5
		elif speedDifference > -10 and speedDifference < 0:
			soll_command = -0.5
		elif speedDifference < -10:
			soll_command = -1
	elif abs(speedDifference) < 1:
		soll_command = 0
	if sollSpeed == 0 and abs(speedDifference) < 10:
		soll_command = -0.5


func checkDespawn() -> void:
	if not ai:
		return

	if despawn_information.type == RoutePointType.STATION and despawn_information.stop_type == StopType.END:
		# Despawn if the train has arrived at the endstation and the planned arrival is two minutes in the past
		if world.time > despawn_information.arrival_time + 60*2 and get_station_table_index_of_station_node_name(despawn_information.node_name) >= current_station_table_index:
			despawn()

	if despawn_information.type == RoutePointType.DESPAWN_POINT:
		if currentRail.name == despawn_information.rail_name:
			if forward and distance_on_rail > despawn_information.distance:
				despawn()
			if not forward and distance_on_rail < despawn_information.distance:
				despawn()

func despawn() -> void:
	freeLastSignalBecauseOfDespawn()
	Logger.log("Despawning Train: " + name)
	despawning = true


var checkVisibilityTimer: float = 0
func checkVisibility(delta: float) -> void:
	checkVisibilityTimer += delta
	if checkVisibilityTimer < 1:
		return
	checkVisibilityTimer = 0
	if ai:
		# We need to update the position when the train is invisible because the accurate drive() function
		# doesn't update the 3D postition in this state. We don't need the accurate 3D Postition if you can't
		# see the train.
		if not rendering:
			self.translation = currentRail.get_pos_at_RailDistance(distance_on_rail)

		rendering = world.chunk_manager.is_position_in_loaded_chunk(self.global_transform.origin)
		self.visible = rendering
		wagonsVisible = rendering


func debugLights(node: Node) -> void:
	for child in node.get_children():
		if child.name != "HUD":
			debugLights(child)
	if node.has_meta("energy"):
		node.visible = false
		node.visible = true
		Logger.log("Spotlight updated")


func toggle_cabin_light() -> void:
	if not has_node("CabinLight"):
		return
	jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
	insideLight = !insideLight
	$CabinLight.visible = insideLight


func toggle_front_light() -> void:
	if not has_node("FrontLight"):
		return
	jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
	frontLight = !frontLight
	$FrontLight.visible = frontLight


var signal_to_free: Spatial = null
var signal_to_free_distance: float = 0
func free_signal_after_driven_train_length(signal_instance: Spatial) -> void: # Called, when overdrove the next signal
	signal_to_free = signal_instance
	signal_to_free_distance = distance_on_route


func checkFreeLastSignal() -> void: #called by process
	if signal_to_free != null and (distance_on_route - signal_to_free_distance) > length:
		signal_to_free.give_signal_free()
		signal_to_free = null # sucessfully freed, don't do it again :)


func freeLastSignalBecauseOfDespawn() -> void:
	if  last_driven_signal != null:
		last_driven_signal.give_signal_free()


func updateTrainAudioBus() -> void:
	if camera_state == CameraState.FREE_VIEW or camera_state == CameraState.OUTER_VIEW:
		AudioServer.set_bus_volume_db(2,0)
	else:
		AudioServer.set_bus_volume_db(2,soundIsolation)


func sendDoorPositionsToCurrentStation() -> void:
	Logger.log("Sending Door Postions...")
	var doorsArray := []
	var doorsWagon := []
	for wagon in wagonsI:
		if (current_station_node.platform_side == PlatformSide.LEFT):
			for door in wagon.leftDoors:
				doorsArray.append(door)
				doorsWagon.append(wagon)
		if (current_station_node.platform_side == PlatformSide.RIGHT):
			for door in wagon.rightDoors:
				doorsArray.append(door)
				doorsWagon.append(wagon)
	current_station_node.setDoorPositions(doorsArray, doorsWagon)


var curve_shaking_factor: float = 0.0
var camera_shaking_time: float = 0.0
func get_camera_shaking(delta: float) -> Vector3:
	camera_shaking_time += delta
	curve_shaking_factor = lerp(0.0, curve_shaking_factor, delta)

	var camera_shaking: Vector3 = Vector3(sin(camera_shaking_time*10.0), cos(camera_shaking_time*7.0), sin(camera_shaking_time*13.0)) / 10000.0

	var shaking_factor: float = Math.speed_to_kmh(speed) / 100.0 * abs(sin(camera_shaking_time/5)) * camera_shaking_factor

	shaking_factor = max(shaking_factor, curve_shaking_factor)

	var current_camera_shaking: Vector3 = camera_shaking * shaking_factor

	return current_camera_shaking


var switch_on_next_change: bool = false
func updateSwitchOnNextChange():
	if forward and currentRail.switch_part[1] != "":
		switch_on_next_change = true
		return
	elif not forward and currentRail.switch_part[0] != "":
		switch_on_next_change = true
		return

	if baked_route.size() > route_index+1:
		var nextRail: Spatial = world.get_node("Rails").get_node(baked_route[route_index+1])
		var nextForward: bool = baked_route_direction[route_index+1]
		if nextForward and nextRail.switch_part[0] != "":
			switch_on_next_change = true
			return
		elif not nextForward and nextRail.switch_part[1] != "":
			switch_on_next_change = true
			return

	switch_on_next_change = false


var last_switch_rail: Spatial = null ## Last Rail, where was overdriven a switch
func check_overdriving_a_switch():
	if not switch_on_next_change:
		return

	var camera_translation: float = 0
	if has_node("Camera"):
		camera_translation = $Camera.translation.x
	if forward:
		if currentRail.length - (distance_on_rail + camera_translation) < 0 and not currentRail == last_switch_rail:
			last_switch_rail = currentRail
	else:
		if distance_on_rail - camera_translation < 0 and not currentRail == last_switch_rail:
			last_switch_rail = currentRail


func change_reverser(change: int) -> void:
	if speed != 0:
		return

	match reverser:
		ReverserState.FORWARD:
			if change < 0:
				reverser = ReverserState.NEUTRAL
				jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
		ReverserState.NEUTRAL:
			jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")
			if change > 0: reverser = ReverserState.FORWARD
			else: reverser = ReverserState.REVERSE
		ReverserState.REVERSE:
			if change > 0:
				reverser = ReverserState.NEUTRAL
				jAudioManager.play_game_sound("res://Resources/Sounds/click.ogg")

	emit_signal("reverser_changed", reverser)


func fail_scenario(text: String) -> void:
	failed_scenario = true
	show_textbox_message(text)


# rail has to be in baked_route
func jump_to_rail(rail_name: String, distance: float, fwd: bool = true) -> void:
	set_speed_to_zero()
	currentRail = world.get_rail(rail_name)
	distance_on_rail = distance
	self.forward = fwd

	# Calculate new distance on route and set new route_index
	distance_on_route = 0
	for baked_route_index in range(baked_route.size()):
		var baked_rail_name: String = baked_route[baked_route_index]
		if baked_rail_name == rail_name and fwd == baked_route_direction[baked_route_index] and route_index <= baked_route_index:
			route_index = baked_route_index
			break
		distance_on_route += world.get_rail(baked_rail_name).length
	if fwd:
		distance_on_route += distance
	else:
		distance_on_route += currentRail.length - distance

	drive(0)

	for wagon in wagonsI:
		wagon.route_index = route_index
		wagon.currentRail = currentRail
		wagon.forward = fwd
		if fwd:
			wagon.distance_on_rail = distance_on_rail - wagon.distanceToPlayer
			wagon.distance_on_route = distance_on_route - wagon.distanceToPlayer
		else:
			wagon.distance_on_rail = distance_on_rail + wagon.distanceToPlayer
			wagon.distance_on_route = distance_on_route + wagon.distanceToPlayer
		wagon.drive(0)


func jump_to_station(station_table_index : int) -> void:
	set_speed_to_zero()

	var station_node: Spatial = world.get_signal(station_table[station_table_index].node_name)
	var rail_name: String = station_node.rail.name
	var local_forward: bool = station_node.forward
	var local_distance_on_rail: float = station_node.get_perfect_halt_distance_on_rail(length)
	jump_to_rail(rail_name, local_distance_on_rail, local_forward)
	force_to_be_in_station(station_table_index)
	sendDoorPositionsToCurrentStation()


func force_to_be_in_station(station_table_index: int) -> void:
	current_station_node = world.get_signal(station_table[station_table_index].node_name)
	current_station_table_index = station_table_index
	current_station_table_entry = station_table[current_station_table_index]
	route_distance_at_station_begin = distance_on_route - length - 1.0
	is_in_station = true
	real_arrival_time = world.time
	_door_open_message_timer = 0
	_door_open_message_sent = false
	whole_train_in_station = true
	if current_station_node.platform_side == PlatformSide.LEFT:
		open_left_doors()
	if current_station_node.platform_side == PlatformSide.RIGHT:
		open_right_doors()


# Returns -1, if station node not found in station_table
func get_station_table_index_of_station_node_name(node_name: String) -> int:
	for i in range(station_table.size()):
		if station_table[i].node_name == node_name:
			return i
	return -1
