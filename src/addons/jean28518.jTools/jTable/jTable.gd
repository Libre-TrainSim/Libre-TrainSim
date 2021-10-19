extends Control

export (Array, String) var headings
export (Array, String) var keys

export (int) var minimum_column_size = 100

export (bool) var show_save_button = false
export (bool) var show_clear_button = true

signal remove_entry_pressed
signal clear_table_pressed
signal add_entry_pressed
signal saved_pressed(tableData) # Gives a Dictionary

export (bool) var _update_table setget update_table_in_editor

var columns = 0
var current_entries = 0

var LineControlResource = preload("res://addons/jean28518.jTools/jTable/LineControl.tscn")

# Called when the node enters the scene tree for the first time.
var grid_node
var headings_node

func _ready():
	update_node_references()
	update_button_configuration()
	clear_data()
	pass # Replace with function body.

func update_node_references():
	grid_node = $VBoxContainer/ScrollContainer/VBoxContainer/Grid
	headings_node = $VBoxContainer/ScrollContainer/VBoxContainer/Headings

func update_button_configuration():
	$VBoxContainer/Buttons/Save.visible = show_save_button
	$VBoxContainer/Buttons/ClearTable.visible = show_clear_button

func update_table_in_editor(newvar):
	update_node_references()
	update_button_configuration()
	_update_table = false
	clear_data()


func clear():
	current_entries = 0
	for child in grid_node.get_children():
		child.free()

	for heading in headings_node.get_children():
		heading.free()

func initialize():
	if not check_configuration():
		return

	for child in get_children():
		if child.name != "VBoxContainer":
			child.hide()

	columns = headings.size()
	grid_node.columns = columns + 1 # +1 because of our line control

	var labelI = Label.new()
	labelI.align = Label.ALIGN_CENTER
	labelI.name = "Space"
	labelI.text = ""
	labelI.size_flags_horizontal = Label.SIZE_EXPAND_FILL
	if minimum_column_size < 175:
		labelI.rect_min_size.x = 175
	else:
		labelI.rect_min_size.x = minimum_column_size
	headings_node.add_child(labelI)
	labelI.owner = self

	for heading in headings:
		labelI = Label.new()
		labelI.align = Label.ALIGN_CENTER
		labelI.name = heading
		labelI.text = heading
		labelI.size_flags_horizontal = Label.SIZE_EXPAND_FILL
		labelI.rect_min_size.x = minimum_column_size
		headings_node.add_child(labelI)
		labelI.owner = self


	pass

func check_configuration():
	if (headings.size() != keys.size() or keys.size() != get_children().size()-1 or headings.size()==0) and current_entries == 0:
		print_debug("JTable " + name + ": The configuration of the table is wrong!")
		return false
	if current_entries != 0:
		print_debug("JTable " + name + ": Can't check configuration. Table not empty.")
		return false
	return true

func new_line():
	if columns == 0:
		return
	current_entries += 1

	var line_control_instance = LineControlResource.instance()
	line_control_instance.connect("line_up", self, "move_line_up")
	line_control_instance.connect("line_down", self, "move_line_down")
	line_control_instance.connect("line_delete", self, "delete_line")
	line_control_instance.update_line(current_entries)
	grid_node.add_child(line_control_instance)
	line_control_instance.owner = self


	for child in get_children():
		if child.name != "VBoxContainer":
			var child_duplicate = child.duplicate()
			child_duplicate.show()
			child_duplicate.size_flags_horizontal = Label.SIZE_EXPAND_FILL
			grid_node.add_child(child_duplicate)

func _on_AddEntry_pressed():
	new_line()
	emit_signal("add_entry_pressed")

func _on_RemoveEntry_pressed():
	delete_line(current_entries)
	emit_signal("remove_entry_pressed")


func move_line_up(line): # line counting here starts from 1
	line -= 1 # converting to line counting from 0
	if line == 0:
		return

	for i in range (columns +1):
		grid_node.move_child(grid_node.get_child(line*(columns+1)+i), (line-1)*(columns+1)+i)

	grid_node.get_child((line-1)*(columns+1)).update_line(line)
	grid_node.get_child(line*(columns+1)).update_line(line+1)

func move_line_down(line):  # line counting here starts from 1
	if line < current_entries:
		move_line_up(line+1)


func delete_line(line): # line counting here starts from 1
	if line == 0:
		return
	line -= 1 # converting to line counting from 0
	for i in range (columns +1):
		grid_node.get_child(line*(columns+1)+i).queue_free()
	for i in range(line, current_entries):
		grid_node.get_child(i*(columns+1)).update_line(i)

	current_entries -= 1

func get_data():
	var data = {}
	for key in keys:
		data[key] = []

	for line in range(current_entries):
		for i in range(columns):
			data[keys[i]].append(get_value_of(line*(columns+1)+i+1))

	return data

func set_data(data):
	clear_data()
	if data == null:
		return
	for line in range(data[keys[0]].size()):
		new_line()
		for k in range(columns):
			if data.has(keys[k]):
				set_value_to(line*(columns+1)+k+1, data[keys[k]][line])



func get_value_of(grid_address : int):
	var node = grid_node.get_child(grid_address)
	if node is LineEdit:
		return node.text
	if node is SpinBox:
		return node.value
	if node is OptionButton:
		return node.selected
	if node is CheckBox or node is CheckButton:
		return node.pressed

	return jConfig.get_value_of(node)


func set_value_to(grid_address : int, value):
	var node = grid_node.get_child(grid_address)
	if node is LineEdit:
		node.text = value
		return
	if node is SpinBox:
		node.value = value
		return
	if node is OptionButton:
		node.selected = value
		return
	if node is CheckBox or node is CheckButton:
		node.pressed = value
		return

	jConfig.set_value_to(node, value)


func _on_Save_pressed():
	emit_signal("saved_pressed", get_data())


func _on_ClearTable_pressed():
	clear_data()
	emit_signal("clear_table_pressed")

func clear_data():
	clear()
	initialize()
