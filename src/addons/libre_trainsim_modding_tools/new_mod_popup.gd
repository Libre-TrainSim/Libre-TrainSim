tool
extends WindowDialog

var base_control


func validate():
	var unique_name = $MarginContainer/VBoxContainer/Grid/Input_Unique.text
	unique_name = unique_name.to_lower() \
							.strip_edges() \
							.strip_escapes() \
							.replace(" ", "_") \
							.replace("-", "_")

	var author_name = $MarginContainer/VBoxContainer/Grid/Input_Author.text
	var display_name = $MarginContainer/VBoxContainer/Grid/Input_Name.text

	create_mod(author_name, unique_name, display_name)
	hide()
	var notice = preload("notice_popup.tscn").instance()
	base_control.add_child(notice)
	notice.popup_centered()
	queue_free()


func create_mod(author_name: String,
				mod_unique_name: String,
				mod_display_name: String):

	var mod_path = "res://Mods/" + mod_unique_name

	var d = Directory.new()
	d.open("res://")
	d.make_dir("Mods")
	d.change_dir("Mods")
	d.make_dir(mod_unique_name)
	d.change_dir(mod_unique_name)
	d.make_dir("Environments")
	d.make_dir("Materials")
	d.make_dir("Music")
	d.make_dir("Objects")
	d.make_dir("Persons")
	d.make_dir("RailTypes")
	d.make_dir("SignalTypes")
	d.make_dir("Sounds")
	d.make_dir("Textures")

	var authors = Authors.new()
	authors.developers = [author_name]
	authors.contributors = []
	authors.translators = []
	ResourceSaver.save(mod_path + "/authors.tres", authors, ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

	var content = ModContentDefinition.new()
	content.unique_name = mod_unique_name
	content.display_name = mod_display_name

	content.environment_folders = [mod_path + "/Environments"]
	content.material_folders = [mod_path + "/Materials"]
	content.music_folders = [mod_path + "/Music"]
	content.object_folders = [mod_path + "/Objects"]
	content.persons_folders = [mod_path + "/Persons"]
	content.rail_type_folders = [mod_path + "/RailTypes"]
	content.signal_type_folders = [mod_path + "/SignalTypes"]
	content.sound_folders = [mod_path + "/Sounds"]
	content.texture_folders = [mod_path + "/Textures"]

	ResourceSaver.save(mod_path + "/content.tres", content, ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
