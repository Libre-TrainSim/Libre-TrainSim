extends CanvasLayer

func popup():
	update_and_prepare_language_handling()
	update_settings_window()
	$JSettings.show()

################################################################################

func _ready():
	if get_parent().name == "root":
		$JSettings.hide()
	apply_saved_settings()


func apply_saved_settings():
	OS.window_fullscreen = get_fullscreen()
	OS.set_use_vsync(get_vsync())
	ProjectSettings.set_setting("rendering/quality/filters/msaa", get_anti_aliasing())
	jAudioManager.set_main_volume_db(get_main_volume())
	jAudioManager.set_game_volume_db(get_game_volume())
	jAudioManager.set_music_volume_db(get_music_volume())


func update_settings_window():
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Fullscreen.pressed = get_fullscreen()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Vsync.pressed = get_vsync()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Shadows.pressed = get_shadows()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/DynamicLights.pressed = get_dynamic_lights()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Fog.pressed = get_fog()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Persons.pressed = get_persons()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/ViewDistance.value = get_view_distance()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Language.select(_language_table[get_language()])
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/AntiAliasing.selected = get_anti_aliasing()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/MainVolume.value = get_main_volume()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/MusicVolume.value = get_music_volume()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/GameVolume.value = get_game_volume()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/SIFA.pressed = get_sifa()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/PZB.pressed = get_pzb()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/ChunkUnloadDistance.value = get_chunk_unload_distance()
	$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/ChunkLoadAll.pressed = get_chunk_load_all()


## Setter/Getter ###############################################################
func get_fullscreen() -> bool:
	return jSaveManager.get_setting("fullscreen", true)

func set_fullscreen(val: bool):
	jSaveManager.save_setting("fullscreen", val)
	OS.window_fullscreen = val


func set_vsync(val: bool):
	jSaveManager.save_setting("vsync", val)
	OS.set_use_vsync(val)

func get_vsync() -> bool:
	return jSaveManager.get_setting("vsync", true)


func set_shadows(val: bool):
	jSaveManager.save_setting("shadows", val)

func get_shadows() -> bool:
	return jSaveManager.get_setting("shadows", true)


func set_dynamic_lights(val: bool):
	jSaveManager.save_setting("dynamic_lights", val)

func get_dynamic_lights() -> bool:
	return jSaveManager.get_setting("dynamic_lights", false)


func set_language(language_code: String):
	jSaveManager.save_setting("language", language_code)
	TranslationServer.set_locale(language_code)

func get_language() -> String:
	return jSaveManager.get_setting("language", TranslationServer.get_locale().rsplit("_")[0])


func set_anti_aliasing(val: int):
	jSaveManager.save_setting("antiAliasing", val)
	ProjectSettings.set_setting("rendering/quality/filters/msaa", val)

func get_anti_aliasing() -> int:
	return jSaveManager.get_setting("antiAliasing", 2)


func set_main_volume(val: float):
	jSaveManager.save_setting("mainVolume", val)
	jAudioManager.set_main_volume_db(val)

func get_main_volume() -> float:
	return jSaveManager.get_setting("mainVolume", 1)


func set_music_volume(val: float):
	jSaveManager.save_setting("musicVolume", val)
	jAudioManager.set_music_volume_db(val)

func get_music_volume() -> float:
	return jSaveManager.get_setting("musicVolume", 1)


func set_game_volume(val: float):
	jSaveManager.save_setting("gameVolume", val)
	jAudioManager.set_game_volume_db(val)

func get_game_volume() -> float:
	return jSaveManager.get_setting("gameVolume", 1)


func set_fog(value: bool):
	jSaveManager.save_setting("fog", value)

func get_fog() -> bool:
	return jSaveManager.get_setting("fog", true)


func set_persons(value: bool):
	jSaveManager.save_setting("persons", value)

func get_persons() -> bool:
	return jSaveManager.get_setting("persons", true)


func set_view_distance(value: int):
	jSaveManager.save_setting("view_distance", value)

func get_view_distance() -> int:
	return jSaveManager.get_setting("view_distance", 1000)


func set_sifa(value: bool):
	jSaveManager.save_setting("sifa_enabled", value)

func get_sifa() -> bool:
	return jSaveManager.get_setting("sifa_enabled", false)


func set_pzb(value: bool):
	jSaveManager.save_setting("pzb_enabled", value)

func get_pzb() -> bool:
	return jSaveManager.get_setting("pzb_enabled", false)


func get_chunk_unload_distance() -> int:
	return int(jSaveManager.get_setting("chunk_unload_distance", 2))

func set_chunk_unload_distance(value: float):
	jSaveManager.save_setting("chunk_unload_distance", int(value))

func get_chunk_load_all() -> bool:
	return jSaveManager.get_setting("chunk_load_all", false)

func set_chunk_load_all(value: bool):
	jSaveManager.save_setting("chunk_load_all", value)

## Other Functionality #########################################################

var _language_table = {"en" : 0, "de" : 1} # Translates language codes to ids
func update_and_prepare_language_handling():
	var language_codes = TranslationServer.get_loaded_locales()
	language_codes = jEssentials.remove_duplicates(language_codes)
	if language_codes.size() == 0:
		$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Label7.hide()
		$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Language.hide()
		return

	# Prepare _language_table
	language_codes.sort()
	_language_table.clear()
	for i in language_codes.size():
		_language_table[language_codes[i]] = i

	# Prepare language
	for index in range(_language_table.size()):
		$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Language.add_item("",index)
	for language in _language_table.keys():
		$JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Language.set_item_text(_language_table[language], TranslationServer.get_locale_name(language))

	# If Language is not found, select one language, which is available
	var language_code = get_language()
	if not _language_table.has(language_code):
		if not language_codes.has("en"):
			language_code = _language_table.keys()[0]
		else:
			language_code = "en"
	set_language(language_code)


func _id_to_language_code(id : int):
	for key in _language_table:
		if _language_table[key] == id:
			return key

## Other Signals ###############################################################

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.is_action("Escape"):
		$JSettings.hide()


func _on_Back_pressed():
	$JSettings.hide()


func _on_Fullscreen_pressed():
	set_fullscreen($JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Fullscreen.pressed)

func _on_Vsync_pressed():
	set_vsync($JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Vsync.pressed)


func _on_Shadows_pressed():
	set_shadows($JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Shadows.pressed)


func _on_Language_item_selected(index):
	set_language(_id_to_language_code(index))


func _on_Fog_pressed():
	set_fog($JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Fog.pressed)


func _on_Persons_pressed():
	set_persons($JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/Persons.pressed)


func _on_DynamicLights_pressed():
	set_dynamic_lights($JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/DynamicLights.pressed)


func _on_SIFA_pressed():
	set_sifa($JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/SIFA.pressed)


func _on_PZB_pressed():
	set_pzb($JSettings/MarginContainer/VBoxContainer/ScrollContainer/GridContainer/PZB.pressed)
