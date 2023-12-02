extends Node2D

export var speed_rotation_100kmh: float
export var command_rotation_100percent: float

onready var world: Node = find_parent("World")
onready var speed_rotation_0kmh: float = $SpeedPointer.rotation
onready var command_rotation_0percent: float = $CommandPointer.rotation

var speed_rotation_per_kmh: float
var command_rotation_per_percent: float

var command_target := 0.0
var blink_status := false


func _ready():
	# convert export vars to radians
	speed_rotation_100kmh = deg2rad(speed_rotation_100kmh)
	command_rotation_100percent = deg2rad(command_rotation_100percent)

	# calculate step sizes
	speed_rotation_per_kmh = (speed_rotation_100kmh - speed_rotation_0kmh)/100.0
	command_rotation_per_percent = (command_rotation_100percent - command_rotation_0percent)
	#print("DISPLAY: " + String(SpeedPerKmH) + " " + String(SpeedPointerZero) + " " + String(SpeedPointerRotationAt100))

	$BlinkTimer.connect("timeout", self, "_toggle_blink_status")

	# SIFA
	var player = find_parent("Player")
	if is_instance_valid(player):
		player.get_node("SafetySystems/SifaModule").connect("sifa_visual_hint", self, "_on_sifa_visual_hint")
	$Info/Sifa.visible = false


func _toggle_blink_status():
	blink_status = !blink_status


func _process(delta: float) -> void:
	$CommandPointer.rotation = move_toward($CommandPointer.rotation, command_target, delta*4.0)


var lastAutoPilot: bool = false
func update_display(speed: float, command: float, door_left: bool, door_right: bool,
					doors_closing: bool, enforced_braking: bool, autopilot: bool,
					speedLimit: float, engine: bool, reverser: int):
	## Tachos:
	$SpeedPointer.rotation = speed_rotation_0kmh + (speed_rotation_per_kmh * speed)
	command_target = command_rotation_0percent + (command_rotation_per_percent * command)

	$Speed.text = String(int(speed))
	$Time.text = Math.seconds_to_string(world.time)

	## Engine:
	$Info/Engine.visible = !engine

	## Enforced Breaking
	if enforced_braking:
		$Info/EnforcedBraking.visible = blink_status
	else:
		$Info/EnforcedBraking.visible = false

	## Doors:
	if doors_closing:
		$Doors.visible = blink_status
	else:
		$Doors.visible = true
	$Doors/Right.visible = door_right
	$Doors/Left.visible = door_left
	$Doors/Door.visible = door_left or door_right

	$Reverser/Forward.visible = reverser == ReverserState.FORWARD
	$Reverser/Backward.visible = reverser == ReverserState.REVERSE
	$Reverser/Neutral.visible = reverser == ReverserState.NEUTRAL

#	if not lastAutoPilot and autopilot:
#		$AnimationPlayerAutoPilot.play("autopilot")
	$Info/Autopilot.visible = autopilot and blink_status
#	lastAutoPilot = autopilot


func _on_sifa_visual_hint(is_turned_on: bool) -> void:
	$Info/Sifa.visible = is_turned_on
