extends VBoxContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var editor_directory_path

# Called when the node enters the scene tree for the first time.
func _ready():
	editor_directory_path = jSaveManager.get_setting("editor_directory_path")
	pass # Replace with function body.

func update_lists_ui():
	editor_directory_path = jSaveManager.get_setting("editor_directory_path")
	var all_new_resources_in_editor_folder = get_all_resources_in_editor_folder()
	var all_loaded_resources = get_all_loaded_additional_resources()
	for resource in all_loaded_resources:
		all_new_resources_in_editor_folder.erase(resource)
	
	$HBoxContainer/LoadedAdditionalResources/ItemList.clear()
	for resource in all_loaded_resources:
		$HBoxContainer/LoadedAdditionalResources/ItemList.add_item(resource)
	
	$HBoxContainer/FoundAdditionalResources/ItemList.clear()
	for resource in all_new_resources_in_editor_folder:
		$HBoxContainer/FoundAdditionalResources/ItemList.add_item(resource)

func get_all_resources_in_editor_folder() -> Array:
	var found_resources = []
	var resource_subfolders = Root.get_subfolders_of(editor_directory_path + "Resources")
	for resource_subfolder in resource_subfolders:
		var found_files = {"Array" : []}

		Root.crawlDirectory(editor_directory_path + "Resources/" + resource_subfolder + "/Materials", found_files, "tres")
		
		Root.crawlDirectory(editor_directory_path + "Resources/" + resource_subfolder + "/Objects", found_files, "obj")
		
		Root.crawlDirectory(editor_directory_path + "Resources/" + resource_subfolder + "/RailTypes", found_files, "tscn")
		
		Root.crawlDirectory(editor_directory_path + "Resources/" + resource_subfolder + "/SignalTypes", found_files, "tscn")
		
		Root.crawlDirectory(editor_directory_path + "Resources/" + resource_subfolder + "/Sounds", found_files, "ogg")
		
		Root.crawlDirectory(editor_directory_path + "Resources/" + resource_subfolder + "/Textures", found_files, "png")
		
		for file in found_files["Array"]:
			found_resources.append(file.replace(editor_directory_path + "Resources/", ""))

	return found_resources

func get_all_loaded_additional_resources() -> Array:
	var found_resources = []
	var resource_subfolders = Root.get_subfolders_of(editor_directory_path + "Resources")
	for resource_subfolder in resource_subfolders:
		var found_files = {"Array" : []}

		Root.crawlDirectory("res://" + "Resources/" + resource_subfolder + "/Materials", found_files, "tres")
		
		Root.crawlDirectory("res://" + "Resources/" + resource_subfolder + "/Objects", found_files, "obj")
		
		Root.crawlDirectory("res://" + "Resources/" + resource_subfolder + "/RailTypes", found_files, "tscn")
		
		Root.crawlDirectory("res://" + "Resources/" + resource_subfolder + "/SignalTypes", found_files, "tscn")
		
		Root.crawlDirectory("res://" + "Resources/" + resource_subfolder + "/Sounds", found_files, "ogg")
		
		Root.crawlDirectory("res://" + "Resources/" + resource_subfolder + "/Textures", found_files, "png")
		
		for file in found_files["Array"]:
			found_resources.append(file.replace("res://" + "Resources/", ""))

	return found_resources
	
func get_found_additional_resources() -> Array:
	return []

func remove_additional_resource() -> void:
	pass

func update_all_additional_resources() -> void:
	pass

# Input example: Test-Track/Objects/object.obj
func import_resource(resource_path : String) -> void:
	var full_path = editor_directory_path + "/Resources/" + resource_path
	
	var dir = Directory.new()
	dir.make_dir_recursive(editor_directory_path + "/.cache/")
	var pck_path = editor_directory_path + "/.cache/additional_resources.pck"
	var packer = PCKPacker.new()
	packer.pck_start(pck_path)
	packer.add_file("res://Resources/" + resource_path, full_path)
	
	var loaded_resources = get_all_loaded_additional_resources()
	
	for resource in loaded_resources:
		if resource == resource_path: continue
		packer.add_file("res://Resources/" + resource, "res://Resources/" + resource)
	packer.flush()
	
	ProjectSettings.load_resource_pack(pck_path)
	update_lists_ui()



func _on_ImportAdditionalResource_pressed():
	if $HBoxContainer/FoundAdditionalResources/ItemList.get_selected_items().size() == 0:
		return
	var resource = $HBoxContainer/FoundAdditionalResources/ItemList.get_item_text( $HBoxContainer/FoundAdditionalResources/ItemList.get_selected_items()[0])
	print(resource)
	import_resource(resource)
