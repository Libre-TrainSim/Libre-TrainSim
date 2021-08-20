tool
extends Node

func call_delayed(delay : float, object : Object, method : String, arg_array : Array = []):
	delayed_call_table.delay.append(delay)
	delayed_call_table.object.append(object)
	delayed_call_table.method.append(method)
	delayed_call_table.arg_array.append(arg_array)

func remove_all_pending_delayed_calls():
	initialize_delayed_call_table()

func find_files_recursively(directory_path : String, file_extension : String):
	var found_files = {"Array" : []}
	_find_files_recursively_helper(directory_path, found_files, file_extension)
	return found_files["Array"]
	
func copy_folder_recursively(from : String, to : String):
	var dir = Directory.new()
	dir.make_dir_recursive(to)
	if not dir.dir_exists(from):
		return
	if not from.ends_with("/"):
		from += "/"
	if not to.ends_with("/"):
		to += "/"
	_copy_folder_recursively_helper(from, to)
	
func remove_folder_recursively(path):
	var dir = Directory.new()
	if not dir.dir_exists(path):
		return
	if not path.ends_with("/"):
		path += "/"
	if dir.open(path) != OK: return
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "": break
		if file == ".": continue
		if file == "..": continue
		if dir.current_is_dir():
			remove_folder_recursively(path + file + "/")
		else:
			var dir2 = Directory.new()
			dir2.remove(path + file)
	dir.list_dir_end()
	dir.remove(path)
	

func remove_duplicates(array : Array):
	var return_value = []
	for item in array:
		if not return_value.has(item):
			return_value.append(item)
	return return_value

func show_message(message : String, title : String = ""):
	var message_box = AcceptDialog.new()
	message_box.dialog_text = message
	message_box.window_title = title
	get_tree().current_scene.add_child(message_box)
	message_box.anchor_left = 0.4
	message_box.anchor_right = 0.5
	message_box.anchor_top = 0.5
	message_box.anchor_bottom = 0.5
	message_box.show_on_top = true
	message_box.popup_centered()


func does_path_exist(path : String):
	var dir = Directory.new()
	return dir.dir_exists(path) or dir.file_exists(path)

## Internal Functions ##########################################################

func _ready():
	initialize_delayed_call_table()

func initialize_delayed_call_table():
	delayed_call_table = {"delay" : [], "object" : [], "method" : [], "arg_array" : [] }

func _process(delta):
	_handle_delayed_calls(delta)

var delayed_call_table

func _handle_delayed_calls(delta):
	var i = 0
	while(i < delayed_call_table.delay.size()): ## We need here a while loop, because want to keep track of the (changing) table size.
		delayed_call_table.delay[i] -= delta
		if delayed_call_table.delay[i] <= 0:
			var object = delayed_call_table.object[i]
			if is_instance_valid(object):
				object.callv(delayed_call_table.method[i], delayed_call_table.arg_array[i])
			delayed_call_table.delay.remove(i)
			delayed_call_table.object.remove(i)
			delayed_call_table.method.remove(i)
			delayed_call_table.arg_array.remove(i)
			i -= 1 ## Because we remove here an entry
		i += 1

func _find_files_recursively_helper(directory_path,found_files,file_extension):
	var dir = Directory.new()
	if dir.open(directory_path) != OK: return
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "": break
		if file.begins_with("."): continue
		if dir.current_is_dir():
			if directory_path.ends_with("/"):
				_find_files_recursively_helper(directory_path+file, found_files, file_extension)
			else:
				_find_files_recursively_helper(directory_path+"/"+file, found_files, file_extension)
		else:
			if file.get_extension() == file_extension:
				var exportString
				if directory_path.ends_with("/"):
					exportString = directory_path +file
				else:
					exportString = directory_path +"/"+file
				found_files["Array"].append(exportString)
	dir.list_dir_end()

func _copy_folder_recursively_helper(from, to):
	var dir = Directory.new()
	dir.make_dir_recursive(to)
	if dir.open(from) != OK: return
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "": break
		if file == ".": continue
		if file == "..": continue
		if dir.current_is_dir():
			print(from + file + "/" + "     " + to + file + "/")
			_copy_folder_recursively_helper(from + file + "/", to + file + "/")
		else:
			var dir2 = Directory.new()
			print(from + file + "     " + to + file)
			dir2.copy(from + file, to + file)
	dir.list_dir_end()
