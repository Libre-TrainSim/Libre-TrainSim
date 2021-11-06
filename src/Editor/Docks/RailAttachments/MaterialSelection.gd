extends HBoxContainer


func _on_Pick_pressed():
	find_parent("RailAttachments").currentMaterial = get_position_in_parent()
	find_parent("RailAttachments")._on_PickMaterial_pressed()




