extends Spatial

var player: LTSPlayer
onready var wagon: Node = get_parent()

var sollCurveSound: float = -50
var sollDriveSound: float = -50

export (AudioStream) var drive_sound: AudioStream = preload("res://Resources/Sounds/Drive.ogg")
export (AudioStream) var curve_sound: AudioStream = preload("res://Resources/Sounds/Curve.ogg")
export (AudioStream) var switch_sound: AudioStream = preload("res://Resources/Sounds/DriveOverSwitch.ogg")
export (AudioStream) var brake_sound: AudioStream = preload("res://Resources/Sounds/Brakes.ogg")


func _process(delta: float) -> void:
	if player == null:
		player = get_parent().player
		return

	## sollCurveSound:
	if wagon.currentRail.radius == 0 or Math.speedToKmH(player.speed) < 35 or abs(wagon.currentRail.radius) > 600:
		sollCurveSound = -50
	else:
		sollCurveSound = -25.0 + (Math.speedToKmH(player.speed)/80.0 * abs(300.0/wagon.currentRail.radius))*5

#	print(sollCurveSound)
	$CurveSound.unit_db = lerp(sollCurveSound, $CurveSound.unit_db, delta)
#	$CurveSound.unit_db = 10

	## Drive Sound:
	$DriveSound.pitch_scale = 0.5 + Math.speedToKmH(player.speed)/200.0
	var driveSoundDb: float = -20.0 + Math.speedToKmH(player.speed)/2.0
	if driveSoundDb > 10:
		driveSoundDb = 10
	if player.speed == 0:
		driveSoundDb = -50.0
	$DriveSound.unit_db = lerp(driveSoundDb, $DriveSound.unit_db, delta)

	var sollBreakSound: float = -50.0
	if not (player.speed >= 5 or player.command >= 0 or player.speed == 0):
		sollBreakSound = -20.0 -player.command * 5.0/player.speed
		if sollBreakSound > 10:
			sollBreakSound = 10
	$BrakeSound.unit_db = lerp(sollBreakSound, $BrakeSound.unit_db, delta)

	$DriveSound.stream_paused = not wagon.visible or get_tree().paused
	$CurveSound.stream_paused = not wagon.visible or get_tree().paused
	$SwitchSound.stream_paused = not wagon.visible or get_tree().paused
	$SwitchSound2.stream_paused = not wagon.visible or get_tree().paused
	$BrakeSound.stream_paused = not wagon.visible or get_tree().paused

	checkAndPlaySwitchSound()


func _ready() -> void:
	$DriveSound.stream = drive_sound
	$CurveSound.stream = curve_sound
	$SwitchSound.stream = switch_sound
	$SwitchSound.stream.loop = false
	$SwitchSound2.stream = switch_sound
	$SwitchSound2.stream.loop = false
	$BrakeSound.stream = brake_sound

	$DriveSound.unit_db = -50
	$CurveSound.unit_db = -50
	$BrakeSound.unit_db = -50


var lastSwitchSoundRail: Spatial = null
var secondSwitchSoundDistance: float = -1 # If this distance is set, and its bigger than the complete distance of the wagon, the second switch sound will be played
func checkAndPlaySwitchSound():
	if secondSwitchSoundDistance != -1 and secondSwitchSoundDistance < wagon.distance_on_route:
		$SwitchSound2.play()
		secondSwitchSoundDistance = -1

	if not wagon.switch_on_next_change:
		return

	if wagon.forward:
		if wagon.currentRail.length - (wagon.distance_on_rail + wagon.length/2.0) < 1 and not wagon.currentRail == lastSwitchSoundRail:
			$SwitchSound.play()
			lastSwitchSoundRail = wagon.currentRail
			secondSwitchSoundDistance = wagon.distance_on_route + wagon.length -1
	else:
		if wagon.distance_on_rail - wagon.length/2.0 < 1 and not wagon.currentRail == lastSwitchSoundRail:
			$SwitchSound.play()
			lastSwitchSoundRail = wagon.currentRail
			secondSwitchSoundDistance = wagon.distance_on_route + wagon.length -1
