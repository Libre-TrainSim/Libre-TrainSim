extends Node2D

export (float) var SpeedPointerRotationAt100: float
export (float) var SollSpeedPointerRotationAt100: float
var SpeedPointerZero: float
var SpeedPerKmH: float
var SollSpeedPointerZero: float
var SollSpeedPerKmH: float

onready var world: Node = find_parent("World")

export (float) var CommandPointerRotationAt100: float
export (float) var blinkingTime: float = 0.8
var CommandPointerZero: float
var CommandPerPercent: float

var syncronizingScreen: bool = false


func _ready():
	if not  world.globalDict.has("Screen1.BlinkingStatus"):
		syncronizingScreen = true
		world.globalDict["Screen1.BlinkingStatus"] = false

	SpeedPointerZero = $SpeedPointer.rotation_degrees
	SpeedPerKmH = (SpeedPointerRotationAt100-SpeedPointerZero)/100.0

	SollSpeedPointerZero = $SpeedLimitPointer.rotation_degrees
	SollSpeedPerKmH = (SollSpeedPointerRotationAt100 - SollSpeedPointerZero)/100.0

	CommandPointerZero = $CommandPointer.rotation_degrees
	CommandPerPercent = (CommandPointerRotationAt100-CommandPointerZero)/100.0
	#print("DISPLAY: " + String(SpeedPerKmH) + " " + String(SpeedPointerZero) + " " + String(SpeedPointerRotationAt100))

	$Info/Sifa.visible = false


var SollCommandPointer: float = 0
var SollSpeedLimitPointer: float = 0
var blinkingTimer: float = 0
var blinkStatus: bool = false
func _process(delta: float) -> void:
	$CommandPointer.rotation_degrees = (SollCommandPointer - $CommandPointer.rotation_degrees)*delta*4.0 + $CommandPointer.rotation_degrees
	$SpeedLimitPointer.rotation_degrees = (SollSpeedLimitPointer - $SpeedLimitPointer.rotation_degrees)*delta*4.0 + $SpeedLimitPointer.rotation_degrees
	if syncronizingScreen:
		blinkingTimer += delta
		if blinkingTimer > blinkingTime:
			blinkStatus = !blinkStatus
			world.globalDict["Screen1.BlinkingStatus"] = blinkStatus
			blinkingTimer = 0
	blinkStatus = world.globalDict["Screen1.BlinkingStatus"]


var lastAutoPilot: bool = false
func update_display(speed: float, command: float, doorLeft: bool, doorRight: bool,
					doorsClosing: float, enforced_braking: bool, autopilot: bool,
					speedLimit: float, engine: bool, reverser: int):
	## Tachos:
	$SpeedPointer.rotation_degrees = SpeedPointerZero+SpeedPerKmH*speed
	SollCommandPointer = CommandPointerZero+CommandPerPercent*command*100
	SollSpeedLimitPointer = SollSpeedPointerZero+SollSpeedPerKmH*speedLimit

	$Speed.text = String(int(speed))
	$Time.text = Math.time_seconds2String(world.time)

	## Engine:
	$Info/Engine.visible = !engine

	## Enforced Breaking
	if enforced_braking:
		$Info/EnforcedBraking.visible = blinkStatus
	else:
		$Info/EnforcedBraking.visible = false

	## Doors:
	if doorsClosing:
		$Doors.visible = blinkStatus
	else:
		$Doors.visible = true
	$Doors/Right.visible = doorRight
	$Doors/Left.visible = doorLeft
	$Doors/Door.visible = doorLeft or doorRight

	$Reverser/Forward.visible = reverser == ReverserState.FORWARD
	$Reverser/Backward.visible = reverser == ReverserState.REVERSE
	$Reverser/Neutral.visible = reverser == ReverserState.NEUTRAL

#	if not lastAutoPilot and autopilot:
#		$AnimationPlayerAutoPilot.play("autopilot")
	$Info/Autopilot.visible = autopilot and blinkStatus
#	lastAutoPilot = autopilot


func _on_sifa_visual_hint(is_turned_on: bool) -> void:
	$Info/Sifa.visible = is_turned_on
