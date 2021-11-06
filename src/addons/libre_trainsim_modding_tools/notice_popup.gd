tool
extends AcceptDialog


func _on_Control_confirmed() -> void:
	get_tree().quit()


func _on_Control_popup_hide() -> void:
	queue_free()

