tool
extends Control

var line = -1

signal line_up(line)
signal line_down(line)
signal line_delete(line)

func _on_Up_pressed():
	emit_signal("line_up", line)

func _on_Down_pressed():
	emit_signal("line_down", line)

func _on_Delete_pressed():
	emit_signal("line_delete", line)
	
func update_line(new_line):
	$HBoxContainer/Line.text = String(new_line)
	line = new_line
	
