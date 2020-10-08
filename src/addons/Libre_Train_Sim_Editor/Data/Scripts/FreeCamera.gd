extends Camera

export var flyspeed = 1
export var mouseSensitivity = 10
var yaw = 0
var pitch = 0

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
		mouseMotion = event.relative
	
var cameraY = 0
var cameraX = 0
func _process(delta):
	#mouse movement
	
	if not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if mouseMotion == null: return
#	cameraY += delta * mouseSensitivity
	cameraY += -mouseMotion.x * delta * mouseSensitivity
	cameraX += +mouseMotion.y * delta * mouseSensitivity 
	if cameraX > 85: cameraX = 85
	if cameraX < -85: cameraX = -85
	rotation_degrees.y = cameraY +90
	rotation_degrees.x = -cameraX
	mouseMotion = Vector2(0,0)
	
	if(Input.is_key_pressed(KEY_W)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * flyspeed)
	if(Input.is_key_pressed(KEY_S)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * -flyspeed)
	if(Input.is_key_pressed(KEY_A)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * flyspeed)
	if(Input.is_key_pressed(KEY_D)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * -flyspeed)
	if(Input.is_key_pressed(KEY_SHIFT)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,1,0) * -flyspeed)
	if(Input.is_key_pressed(KEY_CONTROL)):
		self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,1,0) * flyspeed)
	
