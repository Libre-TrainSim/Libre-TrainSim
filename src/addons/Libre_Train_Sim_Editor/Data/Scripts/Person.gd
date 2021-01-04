extends Spatial

export (float) var walkingSpeed = 1.5

var attachedStation = null
var attachedWagon = null
var assignedDoor = null
var destinationIsSeat = false

var transitionToWagon = false

var status = 0
#0 Walking To Position
#1: Sitting

var destinationPos = []

func _ready():
	walkingSpeed = rand_range(walkingSpeed, walkingSpeed+0.3)
	
	pass # Replace with function body.

func _process(delta):
	handleWalk(delta)
	
func handleWalk(delta):
	if destinationPos.size() == 0:
		if transitionToWagon: 
			attachedStation.deregisterPerson(self)
			attachedStation = null
			transitionToWagon = false
			attachedWagon.registerPerson(self, assignedDoor)
			assignedDoor = null
		if destinationIsSeat:
			destinationIsSeat = false
			## Animation
		return
		
	
	if translation.distance_to(destinationPos[0]) < 0.1:
		destinationPos.pop_front()
		return
	else:
		translation = translation.move_toward(destinationPos[0], delta*walkingSpeed)
	
