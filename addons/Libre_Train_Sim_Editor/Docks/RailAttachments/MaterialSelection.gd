tool
extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("HUHU2")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Pick_pressed():
	print("HUHU")
	find_parent("Rail Attachments").currentMaterial = int(name[-1])
	find_parent("Rail Attachments")._on_PickMaterial_pressed()
	
