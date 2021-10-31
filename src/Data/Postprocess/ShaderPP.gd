extends Node

# README:
# shaders are processed bottom-up
# this means the most nested Viewport is run FIRST!

# the camera node inside the viewport is necessary, because
# it will only render Layer 2 (default is Layer 1)
# so you have to put anything you want to be highlighted into Layer 2
# like this: visual_instance.set_layer_mask_bit(1, true)
# to remove the object from Layer 2:
# visual_instance.set_layer_mask_bit(1, false)

# Viewport is basically the Image we want to process
# the ViewportContainer is the shader that processes that image
# the ViewportContainer also has the side effect of then drawing that
# processed image on top of the screen... :)

# check ViewportContainer -> Material for the Shader

export var highlight_color: Color

onready var external_camera := get_viewport().get_camera()
onready var shader_camera := find_node("Camera") as Camera

func _ready():
	get_child(0).material.set_shader_param("highlight_color", highlight_color)


func _process(_delta: float) -> void:
	shader_camera.global_transform = external_camera.global_transform
