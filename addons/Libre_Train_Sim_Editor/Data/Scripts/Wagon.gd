extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (float) var length = 17.5

var bakedRoute
var bakedRouteDirection
var routeIndex = 0
var forward
var currentRail 
var distanceOnRail = 0
var distance = 0
var speed = 0

var distanceToPlayer = -1

export var pantographEnabled = false


var player
var world

var initialSet = false
# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_parent().name != "Players": return
	if distanceToPlayer == -1:
		distanceToPlayer = abs(player.distanceOnRail - distanceOnRail)
	speed = player.speed
	visible = player.wagonsVisible
	
	if speed != 0 or not initialSet:
		drive(delta)
		initialSet = true
	check_doors()
	
	if pantographEnabled:
		check_pantograph()



func drive(delta):
	if currentRail  == player.currentRail:
		if player.forward:
			distanceOnRail = player.distanceOnRail - distanceToPlayer
		else:
			distanceOnRail = player.distanceOnRail + distanceToPlayer
		
	else: 
		## Real Driving - Only used, if wagon isn't at the same rail as his player.
		var drivenDistance
		if forward:
			drivenDistance = speed * delta
			distanceOnRail += drivenDistance
			distance += drivenDistance
			if distanceOnRail > currentRail.length:
				change_to_next_rail()
		else:
			drivenDistance = speed * delta
			distanceOnRail -= drivenDistance
			distance += drivenDistance
			if distanceOnRail < 0:
				change_to_next_rail()
	
	if forward:
		self.transform = currentRail.get_transform_at_rail_distance(distanceOnRail)
	else:
		self.transform = currentRail.get_transform_at_rail_distance(distanceOnRail)
		rotate_object_local(Vector3(0,1,0), deg2rad(180))

#func change_to_next_rail():
#	print("Changing Rail..")
#	routeIndex += 1
#	currentRail =  world.get_node("Rails").get_node(bakedRoute[routeIndex])
#	forward = bakedRouteDirection[routeIndex]
#
#	if forward:
#		distanceOnRail = 0
#	else:
#		distanceOnRail = currentRail.length

func change_to_next_rail():
	if forward:
		distanceOnRail -= currentRail.length
	print("Changing Rail..")
	routeIndex += 1
	currentRail =  world.get_node("Rails").get_node(bakedRoute[routeIndex])
	forward = bakedRouteDirection[routeIndex]

	if not forward:
		distanceOnRail += currentRail.length

var lastDoorRight = false
var lastDoorLeft = false
var lastDoorsClosing = false
func check_doors():
	if player.doorRight and not lastDoorRight:
		$DoorRight.play("open")
	if player.doorRight and not lastDoorsClosing and player.doorsClosing:
		$DoorRight.play_backwards("open")
	if player.doorLeft and not lastDoorLeft:
		$DoorLeft.play("open")
	if player.doorLeft and not lastDoorsClosing and player.doorsClosing:
		$DoorLeft.play_backwards("open")
		
	
	lastDoorRight = player.doorRight
	lastDoorLeft = player.doorLeft
	lastDoorsClosing = player.doorsClosing

var lastPantograph = false
var lastPantographUp = false
func check_pantograph():
	if not self.has_node("Pantograph"): return
	if not lastPantographUp and player.pantographUp:
		print("Started Pantograph Animation")
		$Pantograph/AnimationPlayer.play("Up")
	if lastPantograph and not player.pantograph:
		$Pantograph/AnimationPlayer.play_backwards("Up")
	lastPantograph = player.pantograph
	lastPantographUp = player.pantographUp
