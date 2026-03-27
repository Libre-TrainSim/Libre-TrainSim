extends HBoxContainer


func _on_Pick_pressed():
	find_parent("RailAttachments").currentMaterial = get_index()
	find_parent("RailAttachments")._on_PickMaterial_pressed()
