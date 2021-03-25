extends Control

func open_window():
	var node = get_tree().get_current_scene()
	var instance = self.duplicate()
	node.add_child(instance)
	instance.owner = node
	instance.update_settings_window()
	instance.show()
	
################################################################################

func _ready():
	if get_parent().name == "root":
		hide()
	
	if get_fullscreen() == null:
		set_fullscreen(true)
		
	if get_shadows() == null:
		set_shadows(true)
		
	if get_anti_aliasing() == null:
		set_anti_aliasing(2)
	
	if get_main_volume() == null:
		set_main_volume(1)
	
	if get_music_volume() == null:
		set_music_volume(1)
	
	if get_game_volume() == null:
		set_game_volume(1)
	
	apply_saved_settings()
	


func apply_saved_settings():
	OS.window_fullscreen = get_fullscreen()
	ProjectSettings.set_setting("rendering/quality/filters/msaa", get_anti_aliasing())
	
	## This can only be used, if JAudioManager is in project.
	if jAudioManager.jAudioManagerBus: 
		jAudioManager.set_main_volume_db(get_main_volume())
		jAudioManager.set_game_volume_db(get_game_volume())
		jAudioManager.set_music_volume_db(get_music_volume())
	

func update_settings_window():
	$ScrollContainer/GridContainer/Fullscreen.pressed = get_fullscreen()
	$ScrollContainer/GridContainer/Shadows.pressed = get_shadows()
	$ScrollContainer/GridContainer/AntiAliasing.selected = get_anti_aliasing()
	$ScrollContainer/GridContainer/MainVolume.value = get_main_volume()
	$ScrollContainer/GridContainer/MusicVolume.value = get_music_volume()
	$ScrollContainer/GridContainer/GameVolume.value = get_game_volume()
	
	if not jAudioManager.jAudioManagerBus:
		$ScrollContainer/GridContainer/Label4.hide()
		$ScrollContainer/GridContainer/GameVolume.hide()
		$ScrollContainer/GridContainer/Label5.hide()
		$ScrollContainer/GridContainer/MusicVolume.hide()

## Setter/Getter ###############################################################

func get_fullscreen():
	return jSaveManager.get_setting("fullscreen")

func set_fullscreen(val : bool):
	jSaveManager.save_setting("fullscreen", val)
	OS.window_fullscreen = val


func set_shadows(val : bool):
	jSaveManager.save_setting("shadows", val)

func get_shadows():
	return jSaveManager.get_setting("shadows")


func set_anti_aliasing(val : int):
	jSaveManager.save_setting("antiAliasing", val)
	ProjectSettings.set_setting("rendering/quality/filters/msaa", val)

func get_anti_aliasing():
	return jSaveManager.get_setting("antiAliasing")


func set_main_volume(val : float):
	jSaveManager.save_setting("mainVolume", val)
	jAudioManager.set_main_volume_db(val)


func get_main_volume():
	return jSaveManager.get_setting("mainVolume")


func set_music_volume(val : float):
	jSaveManager.save_setting("musicVolume", val)
	jAudioManager.set_music_volume_db(val)

func get_music_volume():
	return jSaveManager.get_setting("musicVolume")
	
	
func set_game_volume(val : float):
	jSaveManager.save_setting("gameVolume", val)
	jAudioManager.set_game_volume_db(val)

func get_game_volume():
	return jSaveManager.get_setting("gameVolume")

## Other Signals ###############################################################

func _on_Back_pressed():
	queue_free()

func _on_Fullscreen_pressed():
	set_fullscreen($ScrollContainer/GridContainer/Fullscreen.pressed)

func _on_Shadows_pressed():
	set_shadows($ScrollContainer/GridContainer/Shadows.pressed)
