extends PanelContainer


const ADDONS_DIR := "user://addons/"
const CATALOG_URL_SETTING := "game/content/addon_catalog_url"

var available_addons := []
var selected_addon := -1
var current_request := ""
var download_target := ""
var download_temp_file := ""

onready var pack_list := $VBoxContainer/Packlist
onready var available_list := $VBoxContainer/AvailableList
onready var status_label := $VBoxContainer/Status
onready var refresh_button := $VBoxContainer/Buttons/Refresh
onready var download_button := $VBoxContainer/Buttons/Download
onready var http_request := $HTTPRequest


func _ready() -> void:
	var dir := Directory.new()
	dir.open("user://")
	if not dir.dir_exists(ADDONS_DIR):
		dir.make_dir(ADDONS_DIR)
	_update_download_buttons()


func show() -> void:
	update_content_list()
	refresh_available_content()
	$VBoxContainer/Buttons/Back.grab_focus()
	.show()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_Back_pressed()
		accept_event()


func update_content_list() -> void:
	pack_list.clear_items()
	for mod in ContentLoader.loaded_mods:
		pack_list.add_item(ContentLoader.loaded_mods[mod].display_name)


func refresh_available_content() -> void:
	available_addons.clear()
	selected_addon = -1
	available_list.clear()
	_update_download_buttons()

	var catalog_url: String = _get_catalog_url()
	if catalog_url.empty():
		_set_status("MENU_CONTENT_NO_CATALOG")
		return

	if not _is_supported_url(catalog_url):
		_set_status("MENU_CONTENT_INVALID_CATALOG_URL")
		return

	current_request = "catalog"
	_set_status("MENU_CONTENT_LOADING_CATALOG")
	_update_download_buttons()

	var error: int = http_request.request(catalog_url)
	if error != OK:
		current_request = ""
		_set_status("MENU_CONTENT_CATALOG_REQUEST_FAILED")
		_update_download_buttons()


func _on_Back_pressed() -> void:
	_cancel_active_request()
	hide()


func _on_Open_pressed() -> void:
	var _unused = OS.shell_open("file://" + ProjectSettings.globalize_path(ADDONS_DIR))


func _on_Refresh_pressed() -> void:
	if not current_request.empty():
		return
	refresh_available_content()


func _on_Download_pressed() -> void:
	if not current_request.empty() or selected_addon < 0:
		return

	var addon: Dictionary = available_addons[selected_addon]
	var url: String = String(addon["url"])
	if not _is_supported_url(url):
		_set_status("MENU_CONTENT_INVALID_DOWNLOAD_URL")
		return

	var pack_file_name: String = _get_pack_file_name(addon)
	download_target = ADDONS_DIR.plus_file(pack_file_name)
	download_temp_file = download_target + ".download"

	var dir := Directory.new()
	if dir.file_exists(download_temp_file):
		dir.remove(download_temp_file)

	http_request.download_file = download_temp_file
	current_request = "download"
	_set_status("MENU_CONTENT_DOWNLOADING", [addon["name"]])
	_update_download_buttons()

	var error: int = http_request.request(url)
	if error != OK:
		http_request.download_file = ""
		current_request = ""
		download_target = ""
		download_temp_file = ""
		_set_status("MENU_CONTENT_DOWNLOAD_REQUEST_FAILED")
		_update_download_buttons()


func _on_AvailableList_item_selected(index: int) -> void:
	selected_addon = index
	_update_download_buttons()


func _on_HTTPRequest_request_completed(result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray) -> void:
	var finished_request: String = current_request
	current_request = ""

	if finished_request == "catalog":
		_handle_catalog_response(result, response_code, body)
	elif finished_request == "download":
		_handle_download_response(result, response_code)

	_update_download_buttons()


func _handle_catalog_response(result: int, response_code: int, body: PoolByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_set_status("MENU_CONTENT_CATALOG_REQUEST_FAILED")
		return

	var parsed_json: JSONParseResult = JSON.parse(body.get_string_from_utf8())
	if parsed_json.error != OK:
		_set_status("MENU_CONTENT_CATALOG_INVALID")
		return

	var catalog = parsed_json.result
	var entries := []
	if typeof(catalog) == TYPE_ARRAY:
		entries = catalog
	elif typeof(catalog) == TYPE_DICTIONARY and catalog.has("addons") and typeof(catalog["addons"]) == TYPE_ARRAY:
		entries = catalog["addons"]
	else:
		_set_status("MENU_CONTENT_CATALOG_INVALID")
		return

	for entry in entries:
		var addon: Dictionary = _parse_catalog_entry(entry)
		if addon.empty():
			continue
		available_addons.append(addon)

	available_list.clear()
	for addon in available_addons:
		available_list.add_item(_get_available_addon_label(addon))

	if available_addons.empty():
		_set_status("MENU_CONTENT_CATALOG_EMPTY")
	else:
		_set_status("MENU_CONTENT_CATALOG_READY", [available_addons.size()])


func _handle_download_response(result: int, response_code: int) -> void:
	http_request.download_file = ""

	var dir := Directory.new()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if not download_temp_file.empty() and dir.file_exists(download_temp_file):
			dir.remove(download_temp_file)
		download_target = ""
		download_temp_file = ""
		_set_status("MENU_CONTENT_DOWNLOAD_FAILED")
		return

	if dir.file_exists(download_target):
		dir.remove(download_target)

	var error: int = dir.rename(download_temp_file, download_target)
	if error != OK:
		if dir.file_exists(download_temp_file):
			dir.remove(download_temp_file)
		download_target = ""
		download_temp_file = ""
		_set_status("MENU_CONTENT_DOWNLOAD_SAVE_FAILED")
		return

	download_target = ""
	download_temp_file = ""

	_refresh_available_labels()
	_set_status("MENU_CONTENT_DOWNLOAD_COMPLETE")


func _parse_catalog_entry(entry) -> Dictionary:
	if typeof(entry) != TYPE_DICTIONARY:
		return {}

	var name: String = String(entry.get("name", entry.get("display_name", ""))).strip_edges()
	var url: String = String(entry.get("url", entry.get("download_url", ""))).strip_edges()
	if name.empty() or url.empty():
		return {}

	var addon := {
		"name": name,
		"url": url,
		"version": String(entry.get("version", "")).strip_edges(),
		"description": String(entry.get("description", "")).strip_edges(),
		"file_name": String(entry.get("file_name", "")).strip_edges(),
	}
	return addon


func _refresh_available_labels() -> void:
	available_list.clear()
	for addon in available_addons:
		available_list.add_item(_get_available_addon_label(addon))
	if selected_addon >= 0 and selected_addon < available_addons.size():
		available_list.select(selected_addon)


func _get_available_addon_label(addon: Dictionary) -> String:
	var label := String(addon["name"])
	if not String(addon["version"]).empty():
		label += " (%s)" % addon["version"]
	if _is_pack_downloaded(addon):
		label += " - " + tr("MENU_CONTENT_INSTALLED")
	return label


func _is_pack_downloaded(addon: Dictionary) -> bool:
	var dir := Directory.new()
	return dir.file_exists(ADDONS_DIR.plus_file(_get_pack_file_name(addon)))


func _get_pack_file_name(addon: Dictionary) -> String:
	var file_name := String(addon["file_name"])
	if file_name.empty():
		file_name = String(addon["url"]).get_file()

	var query_index := file_name.find("?")
	if query_index != -1:
		file_name = file_name.substr(0, query_index)

	var fragment_index := file_name.find("#")
	if fragment_index != -1:
		file_name = file_name.substr(0, fragment_index)

	file_name = _sanitize_file_name(file_name.get_file())
	if file_name.empty() or file_name.get_extension().to_lower() != "pck":
		file_name = _sanitize_file_name(String(addon["name"])) + ".pck"
	return file_name


func _sanitize_file_name(value: String) -> String:
	var allowed := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"
	var result := ""
	for i in range(value.length()):
		var character := value.substr(i, 1)
		if allowed.find(character) != -1:
			result += character
		else:
			result += "_"
	return result.strip_edges()


func _get_catalog_url() -> String:
	if not ProjectSettings.has_setting(CATALOG_URL_SETTING):
		return ""
	return String(ProjectSettings.get_setting(CATALOG_URL_SETTING)).strip_edges()


func _is_supported_url(url: String) -> bool:
	return url.begins_with("https://") or url.begins_with("http://")


func _set_status(message: String, args: Array = []) -> void:
	var text := tr(message)
	if not args.empty():
		text = text % args
	status_label.text = text


func _update_download_buttons() -> void:
	refresh_button.disabled = not current_request.empty()
	download_button.disabled = not current_request.empty() or selected_addon < 0


func _cancel_active_request() -> void:
	if current_request.empty():
		return
	http_request.cancel_request()
	http_request.download_file = ""
	if not download_temp_file.empty():
		var dir := Directory.new()
		if dir.file_exists(download_temp_file):
			dir.remove(download_temp_file)
	current_request = ""
	download_target = ""
	download_temp_file = ""
	_update_download_buttons()
