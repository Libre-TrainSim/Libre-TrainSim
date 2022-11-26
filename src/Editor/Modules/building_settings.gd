extends VBoxContainer

signal updated

var current_material_index := 0
var current_mesh: ArrayMesh = null
var mesh_instance: MeshInstance = null # for buildings
var material_count := 0

var requested_content_selector := false

onready var editor := find_parent("Editor")
onready var content_selector := editor.get_node("EditorHUD/Content_Selector")

var possible_materials := {}

func _ready():
	$"Material-1".hide()
	hide()

	var materials = []
	for folder in ContentLoader.repo.material_folders:
		Root.crawl_directory(materials, folder, ["tres", "res"])
	for material in materials:
		possible_materials[material.get_file().get_basename()] = material


func set_mesh(new_mesh: ArrayMesh, new_mesh_instance: MeshInstance = null):
	#if current_mesh == new_mesh:
	#	Logger.warn("BuildingSettings is set with the already set mesh. There is a logic issue anywhere. We are probably hiding a bug here.", self)
	#	return

	current_mesh = new_mesh
	mesh_instance = new_mesh_instance
	clear_materials_list()
	if not is_instance_valid(current_mesh):
		hide()
		mesh_instance = null
		return

	material_count = new_mesh.get_surface_count()
	for i in range(material_count):
		var new_child = get_node("Material-1").duplicate()
		new_child.name = "Material" + String(i)

		var line_edit := new_child.get_node("LineEdit") as LineEdit

		var material_name := new_mesh.surface_get_name(i)
		if material_name in possible_materials:
			line_edit.placeholder_text = material_name
		else:
			line_edit.placeholder_text = material_name

		var current_material := mesh_instance.get_active_material(i) if mesh_instance \
				else current_mesh.surface_get_material(i)
		if "::" in current_material.resource_path:
			current_material = null
		if current_material != null:
			line_edit.text = current_material.resource_path
		else:
			if material_name in possible_materials:
				line_edit.text = possible_materials[material_name]
				current_material = load(possible_materials[material_name])
				if mesh_instance:
					mesh_instance.set_surface_material(i, current_material)
				else:
					current_mesh.surface_set_material(i, current_material)
			else:
				line_edit.text = ""

		new_child.get_node("Label").text += String(i)
		add_child(new_child)
		new_child.show()

	# Add Update Button
	## TODO: Do we really need that boy?
	### yo, why tf is this in code and not in the scene hierarchy!?
	var button := Button.new()
	button.name = "Button"
	button.text = "Update"
	button.connect("pressed", self, "set_current_config_to_mesh")
	add_child(button)

	show()


func set_current_config_to_mesh():
	if not is_instance_valid(current_mesh):
		hide()
		return

	assert(get_child_count() - 2 == current_mesh.get_surface_count())

	var counter := 0
	for child in get_children():
		if child.name == "Material-1" or child is Button:
			continue

		var material_path: String = child.get_node("LineEdit").text

		if ResourceLoader.exists(material_path):
			if mesh_instance:
				mesh_instance.set_surface_material(counter, load(material_path))
			else:
				current_mesh.surface_set_material(counter, load(material_path))

		counter += 1

	emit_signal("updated")


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
		hide()
		return
	get_child(current_material_index + 1).get_node("LineEdit").text = complete_path
	set_current_config_to_mesh()


func get_material_array():
	if not is_instance_valid(current_mesh):
		hide()
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
