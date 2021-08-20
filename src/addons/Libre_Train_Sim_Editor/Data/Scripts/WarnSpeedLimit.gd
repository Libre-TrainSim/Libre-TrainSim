tool
extends Spatial

var type = "WarnSpeed"

export (int) var warn_speed

export (String) var attachedRail
export (int) var onRailPosition
export (bool) var update setget setToRail
export var forward = true


func _ready():
	if Engine.is_editor_hint():
		if get_parent().name == "Signals":
			return
		if get_parent().is_in_group("Rail"):
			attachedRail = get_parent().name
		var signals = find_parent("World").get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		setToRail(true)
	if not Engine.is_editor_hint():
		setToRail(true)



# warning-ignore:unused_argument
func setToRail(newvar):
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = $Viewport.get_texture()
	$MeshInstance/Display.material_override = $MeshInstance/Display.material_override.duplicate(true)
	$MeshInstance/Display.material_override.albedo_texture = texture

	
	
	if warn_speed - 100 >= 0:
		var outputSpeed = int(warn_speed / 10)
		$Viewport/Speed/Label.text = String(outputSpeed)
	else: 
		var outputSpeed = int(warn_speed / 10)
		var string = " " + String(outputSpeed)
		$Viewport/Speed/Label.text = string
	
	
	if not find_parent("World"):
		print("WarnSpeedSign can't find World Parent!'")
		return
	
	if find_parent("World").has_node("Rails/"+attachedRail) and attachedRail != "":
		var rail = get_parent().get_parent().get_node("Rails/"+attachedRail)
		rail.register_signal(self.name, onRailPosition)
		self.translation = rail.get_pos_at_RailDistance(onRailPosition)
		self.rotation_degrees.y = rail.get_deg_at_RailDistance(onRailPosition)
		if not forward:
			self.rotation_degrees.y += 180

func set_scenario_data(d):
	return
func get_scenario_data():
	return null
