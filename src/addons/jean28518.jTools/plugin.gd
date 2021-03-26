tool
extends EditorPlugin

func _enter_tree():
	 add_autoload_singleton("jTools", "res://addons/jean28518.jTools/jTools.gd")
	 add_autoload_singleton("jSaveManager", "res://addons/jean28518.jTools/jSaveManager/jSaveManager.gd")
	 add_autoload_singleton("jAudioManager", "res://addons/jean28518.jTools/jAudioManager/JAudioManager.gd")
	 add_autoload_singleton("jSettings", "res://addons/jean28518.jTools/jSettings/JSettings.tscn")
	
func _exit_tree():
	remove_autoload_singleton("jTools")
	remove_autoload_singleton("jSaveManager")
	remove_autoload_singleton("jAudioManager")
	remove_autoload_singleton("jSettings")
	
	




# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
