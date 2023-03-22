extends Spatial

export (float) var length: float = 17.5
export (bool) var cabinMode: bool = false

var baked_route: Array
var complete_route_length: float = 0
var route_index: int = 0
var forward: bool
var currentRail
var distance_on_rail: float = 0
var distance_on_route: float = 0
var speed: float = 0

var leftDoors := []
var rightDoors := []

var seats := [] # In here the Seats Refernces are safed
var seatsOccupancy := [] # In here the Persons are safed, they are currently sitting on the seats. Index equal to index of seats

var passengerPathNodes := []

var distanceToPlayer: float= -1

export var pantographEnabled: bool = false

onready var player: LTSPlayer
var world: Node

var attachedPersons := []


func initalize() -> void:
	assert(player != null)
	pause_mode = Node.PAUSE_MODE_PROCESS
	if cabinMode:
		length = 4
		return
	registerDoors()
	registerPassengerPathNodes()
	registerSeats()

	$MeshInstance.show()

	var personsNode := Spatial.new()
	personsNode.name = "Persons"
	add_child(personsNode)
	personsNode.owner = self

	initialize_outside_announcement_player()

	# Move wagon into correct start position
	if distanceToPlayer == -1:
		distanceToPlayer = abs(player.distance_on_rail - distance_on_rail)
	drive(0)
	set_transform_on_rail()

	# TODO: this is a performance hotfix, we should do a better implementation in 0.10
	if not ProjectSettings["game/graphics/enable_dynamic_lights"]:
		if get_node_or_null("Lights") != null:
			$Lights.queue_free()
		if get_node_or_null("InteriorLights") != null:
			$InteriorLights.queue_free()


var initialSwitchCheck: bool = false
func _process(delta: float) -> void:
	if get_tree().paused:
		if player != null and not cabinMode:
			visible = player.wagonsVisible
		return

	if (player == null or player.despawning) and not cabinMode:
		queue_free()
		return

	if not initialSwitchCheck:
		updateSwitchOnNextChange()
		initialSwitchCheck = true

	speed = player.speed

	if cabinMode:
		drive(delta)
		return

	assert(get_parent().name == "Players")
	if get_parent().name != "Players":
		return
	if distanceToPlayer == -1:
		distanceToPlayer = abs(player.distance_on_rail - distance_on_rail)
	visible = player.wagonsVisible
	if speed != 0:
		drive(delta)
	set_transform_on_rail()
	check_doors()

	if pantographEnabled:
		check_pantograph()

	if not visible:
		return

	if has_node("InsideLight"):
		$InsideLight.visible = player.insideLight


func set_transform_on_rail() -> void:
	if forward:
		self.transform = currentRail.get_transform_at_distance(distance_on_rail)
	else:
		self.transform = currentRail.get_transform_at_distance(distance_on_rail)
		rotate_object_local(Vector3(0,1,0), PI)


func drive(delta: float) -> void:
	if currentRail == player.currentRail:
		## It is IMPORTANT that the `distance > length` and `distance < 0` are SEPARATE!
		if player.forward:
			distance_on_rail = player.distance_on_rail - distanceToPlayer # possibly < 0 !
			distance_on_route = player.distance_on_route - distanceToPlayer
			if distance_on_rail > currentRail.length:
				change_to_next_rail()
		else:
			distance_on_rail = player.distance_on_rail + distanceToPlayer # possibly > currentRail.length !
			distance_on_route = player.distance_on_route + distanceToPlayer
			if distance_on_rail < 0:
				change_to_next_rail()
	else:
		## Real Driving - Only used, if wagon isn't at the same rail as his player.
		var driven_distance: float = speed * delta
		if player.reverser == ReverserState.REVERSE:
			driven_distance = -driven_distance
		distance_on_route += driven_distance

		if not forward:
			driven_distance = -driven_distance
		distance_on_rail += driven_distance

		if distance_on_rail > currentRail.length or distance_on_rail < 0:
			change_to_next_rail()


# TODO: this is almost 100% duplicate code also in Player.gd
#       can we have a single method that both of them use?
func change_to_next_rail() -> void:
	if forward and (player.reverser == ReverserState.FORWARD):
		distance_on_rail -= currentRail.length
	if not forward and (player.reverser == ReverserState.REVERSE):
		distance_on_rail -= currentRail.length

	if player.reverser == ReverserState.REVERSE:
		route_index -= 1
	else:
		route_index += 1

	if baked_route.size() == route_index or route_index == -1:
		if route_index == baked_route.size():
			route_index = 0
			distance_on_route = 0
		else:
			Logger.vlog(name + ": Route no more rail found, despawning me...", self)
			despawn()
			return

	currentRail = baked_route[route_index].rail
	forward = baked_route[route_index].forward

	updateSwitchOnNextChange()

	if not forward and (player.reverser == ReverserState.FORWARD):
		distance_on_rail += currentRail.length
	if forward and (player.reverser == ReverserState.REVERSE):
		distance_on_rail += currentRail.length


var lastDoorRight: bool = false
var lastDoorLeft: bool = false
var lastDoorsClosing: bool = false
func check_doors() -> void:
	if player.doorRight and not lastDoorRight:
		$Doors/DoorRight.play("open")
	if player.doorRight and not lastDoorsClosing and player.doorsClosing:
		$Doors/DoorRight.play_backwards("open")
	if player.doorLeft and not lastDoorLeft:
		$Doors/DoorLeft.play("open")
	if player.doorLeft and not lastDoorsClosing and player.doorsClosing:
		$Doors/DoorLeft.play_backwards("open")


	lastDoorRight = player.doorRight
	lastDoorLeft = player.doorLeft
	lastDoorsClosing = player.doorsClosing


var lastPantograph: bool = false
var lastPantographUp: bool = false
func check_pantograph() -> void:
	if not self.has_node("Pantograph"):
		return
	if not lastPantographUp and player.pantographUp:
		Logger.vlog("Started Pantograph Animation")
		$Pantograph/AnimationPlayer.play("Up")
	if lastPantograph and not player.pantograph:
		$Pantograph/AnimationPlayer.play_backwards("Up")
	lastPantograph = player.pantograph
	lastPantographUp = player.pantographUp


func despawn() -> void:
	queue_free()


func registerDoors() -> void:
	for child in $Doors.get_children():
		if child.is_in_group("PassengerDoor"):
			if child.translation[2] > 0:
				child.translation += Vector3(0,0,0.5)
				child.side = DoorSide.RIGHT
				rightDoors.append(child)
			else:
				child.translation -= Vector3(0,0,0.5)
				child.side = DoorSide.LEFT
				leftDoors.append(child)


func registerPerson(person: Spatial, door: Spatial):
	var seatIndex: int = getRandomFreeSeatIndex()
	if seatIndex == -1:
		person.queue_free()
		# We should add overcrowding :)
		return
	attachedPersons.append(person)
	person.get_parent().remove_child(person)
	$Persons.add_child(person)
	person.owner = self
	person.translation = door.translation

	var passengerRoutePath: Array = get_path_from_to(door, seats[seatIndex])
	if passengerRoutePath == []:
		Logger.err("Some seats of "+ name + " are not reachable from every door!!", self)
		return
	person.destinationPos = passengerRoutePath
	person.destinationIsSeat = true
	person.attachedSeat = seats[seatIndex]
	seatsOccupancy[seatIndex] = person


func getRandomFreeSeatIndex() -> int:
	if attachedPersons.size()+1 > seats.size():
		return -1
	while (true):
		var randIndex: int = int(rand_range(0, seats.size()))
		if seatsOccupancy[randIndex] == null:
			return randIndex
	return -1


func get_path_from_to(from: Spatial, to: Spatial) -> Array:
	if from == to:
		return []

	var previous := {}
	var visited := []
	var stack := [from]
	while not stack.empty():
		var node = stack.pop_front()
		visited.append(node)
		if node == to:
			break
		for conn in node.connection_nodes:
			if not visited.has(conn):
				stack.append(conn)
				previous[conn] = node

	var path := [to.translation]
	var node := to
	while previous.has(node):
		node = previous[node]
		path.push_front(node.translation)
	return path


func registerPassengerPathNodes() -> void:
	for child in $PathNodes.get_children():
		if child.is_in_group("PassengerPathNode"):
			passengerPathNodes.append(child)


func registerSeats() -> void:
	for child in $Seats.get_children():
		if child.is_in_group("PassengerSeat"):
			seats.append(child)
			seatsOccupancy.append(null)


var leavingPassengerNodes := []
## Called by the train when arriving
## Randomly picks some to the waggon attached persons, picks randomly a door
## on the given side, sends the routeInformation for that to the persons.
func sendPersonsToDoor(doorDirection: int, proportion: float = 0.5) -> void:
	leavingPassengerNodes.clear()
	var possibleDoors := []
	if doorDirection == PlatformSide.LEFT or doorDirection == PlatformSide.BOTH:
		possibleDoors.append_array(leftDoors)
	if doorDirection == PlatformSide.RIGHT or doorDirection == PlatformSide.BOTH:
		possibleDoors.append_array(rightDoors)

	if possibleDoors.empty():
		Logger.err(name + ": No Doors found for doorDirection: " + String(doorDirection), self)
		return

	randomize()
	for personNode in $Persons.get_children():
		if rand_range(0, 1) < proportion:
			leavingPassengerNodes.append(personNode)
			var randomDoor: Spatial = possibleDoors[int(rand_range(0, possibleDoors.size()))]

			var seatIndex: int = -1
			for i in range(seatsOccupancy.size()):
				if seatsOccupancy[i] == personNode:
					seatIndex = i
					break
			if seatIndex == -1:
				Logger.err(name + ": Error: Seat from person" + personNode.name+  " not found!", self)
				return

			var passengerRoutePath: Array = get_path_from_to(seats[seatIndex], randomDoor)
			if passengerRoutePath == []:
				Logger.err("Some doors are not reachable from every door! Check your Path configuration", self)
				return

			# Update position of door. (The Persons should stick inside the train while waiting ;)
			if passengerRoutePath.back().z < 0:
				passengerRoutePath[passengerRoutePath.size()-1].z += 1.3
			else:
				passengerRoutePath[passengerRoutePath.size()-1].z -= 1.3

			personNode.destinationPos = passengerRoutePath # Here maybe .append could be better
			personNode.attachedStation = player.current_station_node
			personNode.transitionToStation = true
			personNode.assignedDoor = randomDoor
			personNode.attachedSeat = null
			seatsOccupancy[seatIndex] = null


func deregisterPerson(personNode: Node) -> void:
	if leavingPassengerNodes.has(personNode):
		leavingPassengerNodes.erase(personNode)


var outside_announcement_player: AudioStreamPlayer3D
func initialize_outside_announcement_player() -> void:
	var audioStreamPlayer := AudioStreamPlayer3D.new()

	audioStreamPlayer.unit_size = 10
	audioStreamPlayer.bus = "Game"
	outside_announcement_player = audioStreamPlayer

	add_child(audioStreamPlayer)


func play_outside_announcement(sound_path : String) -> void:
	if sound_path == "":
		return
	if cabinMode:
		return
	var stream: AudioStream = load(sound_path)
	if stream == null:
		return
	stream.loop = false
	if stream != null:
		outside_announcement_player.stream = stream
		outside_announcement_player.play()


var switch_on_next_change: bool = false
func updateSwitchOnNextChange(): ## Exact function also in player.gd. But these are needed: When the player drives over many small rails that could be inaccurate..
	if forward and currentRail.switch_part[1] != "":
		switch_on_next_change = true
		return
	elif not forward and currentRail.switch_part[0] != "":
		switch_on_next_change = true
		return

	if baked_route.size() > route_index+1:
		var nextRail: Spatial = baked_route[route_index+1].rail
		var nextForward: bool = baked_route[route_index+1].forward
		if nextForward and nextRail.switch_part[0] != "":
			switch_on_next_change = true
			return
		elif not nextForward and nextRail.switch_part[1] != "":
			switch_on_next_change = true
			return

	switch_on_next_change = false
