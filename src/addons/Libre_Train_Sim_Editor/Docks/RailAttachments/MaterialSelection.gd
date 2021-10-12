tool
extends HBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Pick_pressed():
	find_parent("RailAttachments").currentMaterial = get_position_in_parent()
	find_parent("RailAttachments")._on_PickMaterial_pressed()




