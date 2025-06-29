extends Button



func _on_selected_object_changed(_new_object: Node, type_string: String) -> void:
	disabled = type_string != "Rail"
	tooltip_text = "Please select a rail first before" + \
			" adding a dependent rail object." if disabled else ""
