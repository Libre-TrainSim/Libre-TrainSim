extends Button



func _on_selected_object_changed(_new_object: Node, type_string: String) -> void:
	disabled = type_string != "Rail"
	hint_tooltip = "Please select a rail first before" + \
			" adding a dependent rail object." if disabled else ""
