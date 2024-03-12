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


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_Back_pressed()
		accept_event()


func update_content_list() -> void:
	$VBoxContainer/Packlist.clear_items()
	for mod in ContentLoader.loaded_mods:
		$VBoxContainer/Packlist.add_item(ContentLoader.loaded_mods[mod].display_name)


func _on_Back_pressed() -> void:
	hide()


func _on_Open_pressed() -> void:
	var _unused = OS.shell_open("file://" + ProjectSettings.globalize_path("user://addons/"))
