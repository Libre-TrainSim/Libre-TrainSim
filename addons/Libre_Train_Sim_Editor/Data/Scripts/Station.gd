tool
extends Spatial

var type = "Station"

export (String) var stationName
export (bool) var beginningStation
export (bool) var regularStop
export (bool) var endStation
export (int) var stationLength
export (int) var stopTime
export (int) var departureH
export (int) var departureM
export (int) var departureS

export (String) var attachedRail
export (int) var onRailPosition
export (bool) var update setget setToRail
export var forward = true

var rail
func _ready():
	if not Engine.is_editor_hint():
		$MeshInstance.queue_free()
		setToRail(true)
		
func _process(delta):
	if regularStop and rail == null:
		setToRail(true)



# warning-ignore:unused_argument
func setToRail(newvar):
	if beginningStation or endStation:
		regularStop = true
	if find_parent("World") == null:
		return
	if find_parent("World").has_node("Rails/"+attachedRail) and attachedRail != "":
		rail = get_parent().get_parent().get_node("Rails/"+attachedRail)
		rail.register_signal(self.name, onRailPosition)
		self.translation = rail.getNextPos(rail.radius, rail.translation, rail.rotation_degrees.y, onRailPosition)
		
		
func get_scenario_data():
	var d = {}
	d.beginningStation = beginningStation
	d.regularStop = regularStop
	d.endStation = endStation 
	d.stopTime = stopTime
	d.departureH = departureH
	d.departureM = departureM
	d.departureS = departureS
	return d
func set_scenario_data(d):
	beginningStation = d.beginningStation
	regularStop = d.regularStop
	endStation = d.endStation 
	stopTime = d.stopTime
	departureH = d.departureH
	departureM = d.departureM
	departureS = d.departureS
	
