extends Camera

export var flyspeed = 0.5
export var mouseSensitivity = 10
var yaw = 0
var pitch = 0

# Reference delta at 60fps
const refDelta = 0.0167 # 1.0 / 60

onready var world = find_parent("World")

func _ready():
	# Initialization here
	self.set_process_input(true)
	self.set_process(true)
	#set mouse position

func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

var mouseMotion = Vector2(0,0)

func _input(event):
	if event is InputEventMouseMotion:
		mouseMotion = mouseMotion + event.relative
	
var cameraY = 0
var cameraX = 0
func _process(delta):
	#mouse movement
	
	if not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if mouseMotion.length() > 0:
		var motionFactor = (refDelta / delta * refDelta) * mouseSensitivity
		cameraY += -mouseMotion.x * motionFactor
		cameraX += +mouseMotion.y * motionFactor
		if cameraX > 85: cameraX = 85
		if cameraX < -85: cameraX = -85
		rotation_degrees.y = cameraY +90
		rotation_degrees.x = -cameraX
		mouseMotion = Vector2(0,0)
	
	var deltaFlyspeed = (delta / refDelta) * flyspeed
	
	if(Input.is_key_pressed(KEY_W)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * deltaFlyspeed)
	if(Input.is_key_pressed(KEY_S)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * -deltaFlyspeed)
	if(Input.is_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_CONTROL)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * deltaFlyspeed)
	if(Input.is_key_pressed(KEY_D)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * -deltaFlyspeed)
	if(Input.is_key_pressed(KEY_SHIFT)):
		flyspeed = 2
	else:
		flyspeed = 0.5

	
	
