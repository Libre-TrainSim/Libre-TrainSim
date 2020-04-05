tool
extends Spatial

var type = "Station"

export (int) var stationLength


export (int) var platformSide
#platformSide:
#0: No platform
#1: at left side
#2: at right side
#3: at both sides
	

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
	if rail == null:
		setToRail(true)



# warning-ignore:unused_argument
func setToRail(newvar):
	if find_parent("World") == null:
		return
	if find_parent("World").has_node("Rails/"+attachedRail) and attachedRail != "":
		rail = get_parent().get_parent().get_node("Rails/"+attachedRail)
		rail.register_signal(self.name, onRailPosition)
		self.translation = rail.getNextPos(rail.radius, rail.translation, rail.rotation_degrees.y, onRailPosition)
		
		
func get_scenario_data():
	return null
func set_scenario_data(d):
	return
	
