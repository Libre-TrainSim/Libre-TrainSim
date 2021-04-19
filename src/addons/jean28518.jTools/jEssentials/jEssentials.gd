tool
extends Node

func call_delayed(delay : float, object : Object, method : String, arg_array : Array = []):
	delayed_call_table.delay.append(delay)
	delayed_call_table.object.append(object)
	delayed_call_table.method.append(method)
	delayed_call_table.arg_array.append(arg_array)
	
func find_files_recursively(directory_path : String, file_extension : String):
	var found_files = {"Array" : []}
	_find_files_recursively_helper(directory_path, found_files, file_extension)
	return found_files["Array"]

func remove_duplicates(array : Array):
	var return_value = []
	for item in array:
		if not return_value.has(item):
			return_value.append(item)
	return return_value

## Internal Functions ##########################################################

func _ready():
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
			if object != null:
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
