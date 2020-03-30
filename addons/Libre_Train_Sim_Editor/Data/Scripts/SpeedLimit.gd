tool
extends Spatial

var type = "Speed"

export (int) var speed

export (String) var attachedRail
export (int) var onRailPosition
export (bool) var update setget setToRail
export var forward = true


func _ready():

	if not Engine.is_editor_hint():
		setToRail(true)



# warning-ignore:unused_argument
func setToRail(newvar):
	$Viewport.set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	var texture = $Viewport.get_texture()
	$Object/Display.material_override = $Object/Display.material_override.duplicate(true)
	$Object/Display.material_override.albedo_texture = texture
	
	
	if speed - 100 >= 0:
		var outputSpeed = int(speed / 10)
		$Viewport/Speed/Label.text = String(outputSpeed)
	else: 
		var outputSpeed = int(speed / 10)
		var string = " " + String(outputSpeed)
		$Viewport/Speed/Label.text = string
	
	
	if not find_parent("World"):
		queue_free()
		return
	
	if find_parent("World").has_node("Rails/"+attachedRail) and attachedRail != "":
		var rail = find_parent("World").get_node("Rails/"+attachedRail)
		rail.register_signal(self.name, onRailPosition)
		self.translation = rail.getNextPos(rail.radius, rail.translation, rail.rotation_degrees.y, onRailPosition)
		self.rotation_degrees.y = rail.getNextDeg(rail.radius, rail.rotation_degrees.y, onRailPosition)
		if not forward:
			self.rotation_degrees.y += 180
