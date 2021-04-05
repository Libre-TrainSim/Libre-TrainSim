tool
extends EditorPlugin

var jConfig = preload("res://addons/jean28518.jTools/jConfig.gd")

func _enter_tree():
	add_autoload_singleton("jConfig", "res://addons/jean28518.jTools/jConfig.gd")
	if jConfig.enable_jEssentials:
		add_autoload_singleton("jEssentials", "res://addons/jean28518.jTools/jEssentials/jEssentials.gd")
	if jConfig.enable_jSaveManager:
		add_autoload_singleton("jSaveManager", "res://addons/jean28518.jTools/jSaveManager/jSaveManager.gd")
	if jConfig.enable_jAudioManager:
		add_autoload_singleton("jAudioManager", "res://addons/jean28518.jTools/jAudioManager/JAudioManager.gd")
	if jConfig.enable_jSettings:
		add_autoload_singleton("jSettings", "res://addons/jean28518.jTools/jSettings/JSettings.tscn")
	if jConfig.enable_jList:
		add_autoload_singleton("jListManager", "res://addons/jean28518.jTools/jList/jListManager.gd")
	

	
	
func _exit_tree():
	remove_autoload_singleton("jConfig")
	if jConfig.enable_jEssentials:
		remove_autoload_singleton("jEssentials")
	if jConfig.enable_jSaveManager:
		remove_autoload_singleton("jSaveManager")
	if jConfig.enable_jAudioManager:
		remove_autoload_singleton("jAudioManager")
	if jConfig.enable_jSettings:
		remove_autoload_singleton("jSettings")
	if jConfig.enable_jList:
		remove_autoload_singleton("jListManager")
	
func _ready():
	pass
