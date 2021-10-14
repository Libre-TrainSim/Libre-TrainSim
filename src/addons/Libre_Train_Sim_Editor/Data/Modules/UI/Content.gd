extends PanelContainer


func _ready() -> void:
	var dir = Directory.new()
	dir.open("user://")
	if not dir.dir_exists("user://addons/"):
		dir.make_dir("user://addons/")


func show() -> void:
	update_content_list()
	.show()


func update_content_list() -> void:
	$VBoxContainer/Packlist.clear_items()
	for contentPack in ContentLoader.foundContentPacks:
		$VBoxContainer/Packlist.add_item(contentPack)


func _on_Back_pressed() -> void:
	hide()


func _on_Import_pressed():
	$FileDialog.current_path = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	$FileDialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	$FileDialog.popup_centered(Vector2(500,500))


func _on_FileDialog_file_selected(path):
	_on_FileDialog_files_selected([path])


func _on_FileDialog_files_selected(paths):
	var dir = Directory.new()
	dir.open("user://")
	for path in paths:
		print(path)
		print("user://addons/%s" % path.get_file())
		var err = dir.copy(path, "user://addons/%s" % path.get_file())
		if err:
			jEssentials.show_message("Failed for: %s \nError code: %s" % [path, String(err)])
	ContentLoader.update_config()
	update_content_list()


func _on_Open_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://addons/"))
