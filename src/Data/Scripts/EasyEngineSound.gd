extends Spatial

var player: LTSPlayer
onready var wagon: Spatial = get_parent()

export (AudioStream) var engine_idle: AudioStream = preload("res://Resources/Sounds/EngineIdle.ogg")
export (AudioStream) var acceleration: AudioStream = preload("res://Resources/Sounds/Acceleration3.ogg")


func _ready() -> void:
	$Idle.stream = engine_idle
	$Acceleration.stream = acceleration

	$Idle.unit_db = -50
	$Acceleration.unit_db = -50

func _process(delta: float) -> void:
	if player == null:
		player = get_parent().player
		return

	if player.engine:
		$Idle.unit_db = Root.clampViaTime(0, $Idle.unit_db, delta)
	else:
		$Idle.unit_db = Root.clampViaTime(-50, $Idle.unit_db, delta)

	var sollAcceleration: float = -50
	if player.command > 0 and player.engine and player.speed != 0:
		if  Math.speedToKmH(player.speed) < 60:
			sollAcceleration = -30 + abs(player.command*30)
		else:
			sollAcceleration = -30 + abs(player.command*30) - (Math.speedToKmH(player.speed)-60)*3.0

	$Acceleration.unit_db = Root.clampViaTime(sollAcceleration, $Acceleration.unit_db, delta)

	$Idle.stream_paused = not wagon.visible
	$Acceleration.stream_paused = not wagon.visible
#
#
### sollCurveSound:
#	if wagon.currentRail.radius == 0 or Math.speedToKmH(player.speed) < 35:
#		sollCurveSound = -50
#	else:
#		sollCurveSound = -25.0 + (Math.speedToKmH(player.speed)/80.0 * abs(300.0/wagon.currentRail.radius))*5
#
##	print(sollCurveSound)
#	$CurveSound.unit_db = Root.clampViaTime(sollCurveSound, $CurveSound.unit_db, delta)
##	$CurveSound.unit_db = 10
#
#	## Drive Sound:
#	$DriveSound.pitch_scale = 0.5 + Math.speedToKmH(player.speed)/200.0
#	var driveSoundDb = -20.0 + Math.speedToKmH(player.speed)/2.0
#	if driveSoundDb > 10:
#		driveSoundDb = 10
#	if player.speed == 0:
#		driveSoundDb = -50.0
#	$DriveSound.unit_db = Root.clampViaTime(driveSoundDb, $DriveSound.unit_db, delta)
#
#	var sollBreakSound = -50.0
#	if not (player.speed >= 5 or player.command >= 0 or player.speed == 0):
#		sollBreakSound = -20.0 -player.command * 5.0/player.speed
#		if sollBreakSound > 10:
#			sollBreakSound = 10
#	$BrakeSound.unit_db = Root.clampViaTime(sollBreakSound, $BrakeSound.unit_db, delta)
