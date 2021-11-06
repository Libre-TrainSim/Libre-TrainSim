tool
extends VBoxContainer

var base: Control

func _on_new_mod_pressed() -> void:
	var popup = preload("new_mod_popup.tscn").instance()
	popup.base_control = base
	base.add_child(popup)
	popup.popup_centered()


func _on_LinkButton_pressed() -> void:
	OS.shell_open("https://www.libre-trainsim.de/contribute")
