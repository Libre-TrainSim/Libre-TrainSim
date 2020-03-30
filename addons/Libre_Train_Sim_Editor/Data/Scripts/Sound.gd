extends Node2D

onready var drivePitchShift = AudioServer.get_bus_effect(2, 0)

export (float) var AccelerationTransitionTime 
export (float) var AccelerationTransitionSpeed 


var sollAccelerationVolume = -50

func _ready():
	pass

func _process(delta):
	pass
	if Input.is_action_just_pressed("ui_accept"):
		$Test.play(0.0)

	var speed = Math.speedToKmH((get_parent().speed))
	var command = get_parent().command

	handleDrive(speed)
	handleAcceleration(command, speed, delta)
	var currentAccelerationVolume = AudioServer.get_bus_volume_db(1)
#	print(String(sollAccelerationVolume)+"  " + String(currentAccelerationVolume))
	AudioServer.set_bus_volume_db(1, ((sollAccelerationVolume-currentAccelerationVolume)*delta+currentAccelerationVolume))
	
func handleDrive(speed):
#	var volume = 0
#	if speed < 5:
#		volume = -50 + speed*10
#	else:
#		volume = 0
	AudioServer.set_bus_volume_db(2, 0)
	$Drive.pitch_scale = 0.5 + speed/100.0

var lastspeed = 0
var timerstatus = ""

func handleAcceleration(command, speed, delta):
	if !$AccelerationTransition.playing:
		sollAccelerationVolume = -50+(command*50) - speed*0.1
			
	if lastspeed <= AccelerationTransitionSpeed and speed > AccelerationTransitionSpeed:
		$AccelerationTransition.play()
		$Timer.wait_time = AccelerationTransitionTime
		$Timer.start()
		sollAccelerationVolume = -50
	if lastspeed > AccelerationTransitionSpeed and speed <= AccelerationTransitionSpeed:
		$Acceleration2.stop()
		$Acceleration1.play()
	
	$AccelerationTransition.volume_db = -50+(command*50)
	lastspeed = speed
	
	
	
#func handleEngine(command, speed):
#	$Engine.volume_db = volume
#	$Engine.pitch_scale = 1.0 + speed/10.0



	


func _on_Timer_timeout():
	sollAccelerationVolume = 0
	$Acceleration2.play()
	$Acceleration1.stop()
