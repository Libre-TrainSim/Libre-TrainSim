extends Panel

signal export_confirmed(path)

func show_up(predefined_path):
	$LineEdit.text = predefined_path
	$Question.show()
	$LineEdit.show()
	$Cancel.show()
	$Export.show()
	$Label.hide()
	show()



func _on_Cancel_pressed():
	hide()



func _on_Export_pressed():
	var dir = Directory.new()
	if not dir.dir_exists($LineEdit.text):
		find_parent("Editor").send_message("Path does not exist!")
		return
	$Question.hide()
	$LineEdit.hide()
	$Cancel.hide()
	$Export.hide()
	$Label.show()
	emit_signal("export_confirmed", $LineEdit.text)
