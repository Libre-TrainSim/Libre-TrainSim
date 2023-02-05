extends PanelContainer


func _ready() -> void:
	var dir = Directory.new()
	dir.open("user://")
	if not dir.dir_exists("user://addons/"):
		dir.make_dir("user://addons/")


func show() -> void:
	update_content_list()
	$VBoxContainer/Buttons/Back.grab_focus()
	.show()


func update_content_list() -> void:
	$VBoxContainer/Packlist.clear_items()
	for mod in ContentLoader.loaded_mods:
		$VBoxContainer/Packlist.add_item(ContentLoader.loaded_mods[mod].display_name)


func _on_Back_pressed() -> void:
	hide()


func _on_Open_pressed() -> void:
	var _unused = OS.shell_open(ProjectSettings.globalize_path("user://addons/"))
