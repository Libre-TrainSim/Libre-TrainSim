extends CanvasLayer

var language_selector_prepared = false

func popup():
	update_and_prepare_language_handling()
	update_settings_window()
	$JSettings.show()

################################################################################

func _ready():
	if get_parent().name == "root":
		$JSettings.hide()
	first_run_check()
	apply_saved_settings()


func first_run_check():
	# Check if this is the first run, and if it is, apply default settings
	var dir = Directory.new()
	if not dir.file_exists("user://override.cfg") or OS.has_feature("editor"):
		Logger.log("First run (\"user://override.cfg\" doesn't exist). Applying default settings.")
		reset_settings_to_default()


func reset_settings_to_default():
	Logger.vlog("Settings reset to default.")
	set_fullscreen(true)
	set_vsync(true)
	set_fps_limit(0) # disable limit
	set_anti_aliasing(2)
	set_fog(true)
	set_shadows(true)
	set_main_volume(1.0)
	set_music_volume(1.0)
	set_game_volume(1.0)
	set_persons(true)
	set_view_distance(1000)
	set_sifa(true)
	set_pzb(true)
	set_chunk_unload_distance(2)
	set_chunk_load_all(false)
	set_dynamic_lights(false)


func apply_saved_settings():
	jAudioManager.set_main_volume_db(ProjectSettings["game/audio/main_volume"])
	jAudioManager.set_game_volume_db(ProjectSettings["game/audio/game_volume"])
	jAudioManager.set_music_volume_db(ProjectSettings["game/audio/music_volume"])


func save_settings():
	# Save, except if in Godot Editor
	if not OS.has_feature("editor"):
		ProjectSettings.save_custom("user://override.cfg")


func update_settings_window():
	$"%Fullscreen".pressed = ProjectSettings["display/window/size/fullscreen"]
	$"%Vsync".pressed = ProjectSettings["display/window/vsync/use_vsync"]
	$"%FpsLimitToggle".pressed = (ProjectSettings["debug/settings/fps/force_fps"] != 0)
	show_fps_limit(not ProjectSettings["display/window/vsync/use_vsync"])
	$"%Shadows".pressed = ProjectSettings["game/graphics/shadows"]
	$"%DynamicLights".pressed = ProjectSettings["game/graphics/enable_dynamic_lights"]
	$"%Fog".pressed = ProjectSettings["game/graphics/fog"]
	$"%Persons".pressed = ProjectSettings["game/gameplay/enable_persons"]
	$"%ViewDistance".value = ProjectSettings["game/gameplay/view_distance"]
	$"%Language".select(_language_table[get_language()])
	$"%AntiAliasing".selected = ProjectSettings["rendering/quality/filters/msaa"]
	$"%MainVolume".value = ProjectSettings["game/audio/main_volume"]
	$"%MusicVolume".value = ProjectSettings["game/audio/music_volume"]
	$"%GameVolume".value = ProjectSettings["game/audio/game_volume"]
	$"%SIFA".pressed = ProjectSettings["game/gameplay/sifa_enabled"]
	$"%PZB".pressed = ProjectSettings["game/gameplay/pzb_enabled"]
	$"%ChunkUnloadDistance".value = ProjectSettings["game/gameplay/chunk_unload_distance"]
	$"%ChunkLoadAll".pressed = ProjectSettings["game/gameplay/load_all_chunks"]


## Setter/Getter ###############################################################
func set_fullscreen(val: bool):
	ProjectSettings["display/window/size/fullscreen"] = val
	save_settings()
	OS.window_fullscreen = val


func set_vsync(val: bool):
	ProjectSettings["display/window/vsync/use_vsync"] = val
	show_fps_limit(not val) # only show fps limit settings if vsync is off
	save_settings()
	OS.set_use_vsync(val)


func set_fps_limit(target_fps: int):
	ProjectSettings["debug/settings/fps/force_fps"] = target_fps
	save_settings()
	Engine.set_target_fps(target_fps)


func set_shadows(val: bool):
	ProjectSettings["game/graphics/shadows"] = val
	save_settings()


func set_dynamic_lights(val: bool):
	ProjectSettings["game/graphics/enable_dynamic_lights"] = val
	save_settings()


func set_language(language_code: String):
	ProjectSettings["locale/overwritten_language"] = language_code
	save_settings()
	TranslationServer.set_locale(language_code)

func get_language() -> String:
	var language_code = ProjectSettings["locale/overwritten_language"]
	if language_code == "":
		return TranslationServer.get_locale().rsplit("_")[0]
	else:
		return language_code


func set_anti_aliasing(val: int):
	ProjectSettings["rendering/quality/filters/msaa"] = val
	save_settings()


func set_main_volume(val: float):
	ProjectSettings["game/audio/main_volume"] = val
	save_settings()
	jAudioManager.set_main_volume_db(val)


func set_music_volume(val: float):
	ProjectSettings["game/audio/music_volume"] = val
	save_settings()
	jAudioManager.set_music_volume_db(val)


func set_game_volume(val: float):
	ProjectSettings["game/audio/game_volume"] = val
	save_settings()
	jAudioManager.set_game_volume_db(val)


func set_fog(val: bool):
	ProjectSettings["game/graphics/fog"] = val
	save_settings()


func set_persons(val: bool):
	ProjectSettings["game/gameplay/enable_persons"] = val
	save_settings()


func set_view_distance(val: int):
	ProjectSettings["game/gameplay/view_distance"] = val
	save_settings()


func set_sifa(val: bool):
	ProjectSettings["game/gameplay/sifa_enabled"] = val
	save_settings()


func set_pzb(val: bool):
	ProjectSettings["game/gameplay/pzb_enabled"] = val
	save_settings()


func set_chunk_unload_distance(val: float):
	ProjectSettings["game/gameplay/chunk_unload_distance"] = int(val)
	save_settings()


func set_chunk_load_all(val: bool):
	ProjectSettings["game/gameplay/load_all_chunks"] = val
	save_settings()

## Other Functionality #########################################################

var _language_table = {"en" : 0, "de" : 1} # Translates language codes to ids
func update_and_prepare_language_handling():
	var language_codes = TranslationServer.get_loaded_locales()
	language_codes = jEssentials.remove_duplicates(language_codes)
	if language_codes.size() == 0:
		$"%Label7".hide()
		$"%Language".hide()
		return

	# Prepare _language_table
	language_codes.sort()
	_language_table.clear()
	for i in language_codes.size():
		_language_table[language_codes[i]] = i

	# Prepare language selector
	if not language_selector_prepared:
		for index in range(_language_table.size()):
			$"%Language".add_item("",index)
		for language in _language_table.keys():
			$"%Language".set_item_text(_language_table[language], TranslationServer.get_locale_name(language))
		language_selector_prepared = true

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


func show_fps_limit(val: bool):
	$"%LabelFpsLimitToggle".visible = val
	$"%FpsLimitToggle".visible = val
	show_fps_limit_selector(val and $"%FpsLimitToggle".pressed)
	if not val:
		set_fps_limit(0)

func show_fps_limit_selector(val: bool):
	if val:
		# Initate the FPS limit with the screen refresh rate if we just enabled the fps limiter.
		# Otherwise, show the current fps limit.
		if ProjectSettings["debug/settings/fps/force_fps"] == 0:
			$"%FpsLimit".value = OS.get_screen_refresh_rate()
		else:
			$"%FpsLimit".value = ProjectSettings["debug/settings/fps/force_fps"]
		set_fps_limit($"%FpsLimit".value)
	$"%LabelFpsLimit".visible = val
	$"%FpsLimit".visible = val

## Other Signals ###############################################################

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.is_action("Escape"):
		$JSettings.hide()


func _on_Back_pressed():
	$JSettings.hide()


func _on_Fullscreen_pressed():
	set_fullscreen($"%Fullscreen".pressed)


func _on_Vsync_pressed():
	set_vsync($"%Vsync".pressed)


func _on_FpsLimitToggle_toggled(button_pressed):
	show_fps_limit_selector(button_pressed) # Only show selector when FPS limit is enabled
	if not button_pressed:
		set_fps_limit(0) # disable limit


func _on_Shadows_pressed():
	set_shadows($"%Shadows".pressed)


func _on_Language_item_selected(index):
	set_language(_id_to_language_code(index))


func _on_Fog_pressed():
	set_fog($"%Fog".pressed)


func _on_Persons_pressed():
	set_persons($"%Persons".pressed)


func _on_DynamicLights_pressed():
	set_dynamic_lights($"%DynamicLights".pressed)


func _on_SIFA_pressed():
	set_sifa($"%SIFA".pressed)


func _on_PZB_pressed():
	set_pzb($"%PZB".pressed)


func _on_Reset_pressed():
	reset_settings_to_default()
	update_settings_window()
