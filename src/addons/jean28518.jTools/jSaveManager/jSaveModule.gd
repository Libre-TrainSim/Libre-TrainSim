tool
extends Node

# Example: "res://Levels/Level1/Level1.save"
export (String) var save_path = ""


func set_save_path(save_path : String):
	self.save_path = save_path

func save_value(key : String, value):
	if _config == null:
		print_debug("Save path not configured correctly. Don't saving anything...")
		return
		
	_config.set_value("Main", key, value)
	_config.save(save_path)

func get_value(key,  default_value = null):
	if _config == null:
		print_debug("Save path not configured correctly. Returning default_value.")
		return default_value
		
	if _config.has_section_key("Main", key):
		return _config.get_value("Main", key, default_value)
	return default_value
	
## Internal Code ###############################################################
var _config

func _ready():
	_load_current_config()

func _load_current_config():
	if save_path == "":
		print_debug("Save path not configured correctly. Not initializing jSaveModlue "+ name + ".")
	_config = ConfigFile.new()
	
	var dir = Directory.new()
	if not dir.dir_exists(save_path.get_base_dir()):
		dir.make_dir_recursive(save_path.get_base_dir())
	
	_config.load(save_path)
