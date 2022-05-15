extends Button


func _on_Button_pressed():
	find_parent("BuildingSettings").pick_pressed(get_parent().get_position_in_parent()-1)
