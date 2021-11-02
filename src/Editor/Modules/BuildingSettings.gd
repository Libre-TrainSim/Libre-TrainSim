extends VBoxContainer

signal updated()

var current_material_index = 0
var current_mesh = null
var material_count = 0

var requested_content_selector = false

onready var editor = find_parent("Editor")
onready var content_selector = editor.get_node("EditorHUD/Content_Selector")

func _ready():
	configure_mouse_signals($"Material-1")

func _input(event):
	if not is_instance_valid(current_mesh):
		hide()

func emit_signal_updated():
	emit_signal("updated")

func set_mesh(mesh : MeshInstance):
	current_mesh = mesh
	clear_materials_list()
	if current_mesh == null:
		return
	material_count = mesh.get_surface_material_count()
	for i in range(material_count):
		var new_child = get_node("Material-1").duplicate()
		new_child.name = "Material" + String(i)
		var current_material = current_mesh.get_surface_material(i)
		if current_material != null:
			new_child.get_node("LineEdit").text = current_material.resource_path
		new_child.get_node("Label").text += String(i)
		add_child(new_child)
		new_child.show()
		configure_mouse_signals(new_child)

	## Add Update Button:
	var button = Button.new()
	button.name = "Button"
	button.text = "Update"
	button.connect("pressed", self, "set_current_config_to_mesh")
	button.connect("pressed", self, "emit_signal_updated")
	add_child(button)
	button.connect("mouse_entered", find_parent("EditorHUD"), "_on_Mouse_entered_UI")
	button.connect("mouse_exited", find_parent("EditorHUD"), "_on_Mouse_exited_UI")

	show()

func set_current_config_to_mesh():
	if not is_instance_valid(current_mesh):
		return
	var counter = 0
	for child in get_children():
		if child.name == "Material-1" or child is Button:
			continue
		var material_path = child.get_node("LineEdit").text
		if ResourceLoader.exists(material_path):
			current_mesh.set_surface_material(counter, load(material_path))
		counter += 1




func clear_materials_list():
	for child in get_children():
		if child.name != "Material-1":
			child.queue_free()

func pick_pressed(material_index):
	current_material_index = material_index
	content_selector.set_type(content_selector.MATERIALS)
	content_selector.show()
	requested_content_selector = true


func _on_Content_Selector_resource_selected(complete_path):
	if not requested_content_selector:
		return
	requested_content_selector = false
	if complete_path == "":
		return
	if not is_instance_valid(current_mesh):
		return
	get_child(current_material_index + 1).get_node("LineEdit").text = complete_path
	set_current_config_to_mesh()
	emit_signal_updated()

func get_material_array():
	if not is_instance_valid(current_mesh):
		return []
	var array = []
	for child in get_children():
		if child.name == "Material-1" or child is Button:
			continue
		var material_path = child.get_node("LineEdit").text
		if ResourceLoader.exists(material_path):
			array.append(material_path)
		else:
			array.append("")
	return array

func configure_mouse_signals(node):
	node.get_node("LineEdit").connect("mouse_entered", find_parent("EditorHUD"), "_on_Mouse_entered_UI")
	node.get_node("LineEdit").connect("mouse_exited", find_parent("EditorHUD"), "_on_Mouse_exited_UI")
	node.get_node("Button").connect("mouse_entered", find_parent("EditorHUD"), "_on_Mouse_entered_UI")
	node.get_node("Button").connect("mouse_exited", find_parent("EditorHUD"), "_on_Mouse_exited_UI")
