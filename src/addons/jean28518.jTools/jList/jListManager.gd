tool
extends Node

func get_jList(id : String):
	for i in range(registered_jList_ids.size()):
		if registered_jList_ids[i] == id:
			return registered_nodes[i]
	return null

# Returns null, if buffer is empty
func get_buffer():
	if buffer_source_jList_id == "":
		return null
	return (buffer)
	
func get_buffer_source_jList_id():
	if buffer_source_jList_id == "":
		return null
	return buffer_source_jList_id

func clear_bufffer():
	buffer = []
	buffer_source_jList_id == ""


## Internal Code ###############################################################
var registered_nodes = []
var registered_jList_ids = []

var buffer = []
var buffer_source_jList_id = ""

func register_jList(node : Node): # Called by the jList itself while entering the tree
	var id = node.id
	if check_duplicate(id, node):
		print("jListGlobal.register_jList: Aborting...")
		return false
	
	registered_jList_ids.append(id)
	registered_nodes.append(node)
	
func deregister_jList(node : Node): # Called by the jList itself while exiting the tree
	var id = node.id
	for i in range(registered_jList_ids.size()):
		if registered_jList_ids[i] == id:
			registered_jList_ids.remove(i)
			registered_nodes.remove(i)
			return true
	return false

func _enter_tree():
	InputMap.add_action("jList_enter")
	var key_event_enter = InputEventKey.new()
	key_event_enter.scancode = KEY_ENTER
	InputMap.action_add_event("jList_enter", key_event_enter)
	
func _exit_tree():
	InputMap.erase_action("jList_enter")
	
# Returns true, if duplicate was found.
# Checks if already such information is stored in the databse
func check_duplicate(id : String, node : Node):
	var return_value = false
	if (id == "" or node == null):
		print_debug("jListGlobal.check_duplicate: id == null or node == null!")
		return true
	if registered_jList_ids.has(id):
		print_debug("jList " + node.name + ": There currently exists a node with the same ID.")
		return_value = true
	if registered_nodes.has(node):
		print_debug("jListGlobal.jListGlobal.check_duplicate: " + node.name + " is already registered!")
		return_value = true
	
	return return_value
	
func set_buffer(node : Node, copied_entry_names : Array):
	buffer = copied_entry_names.duplicate()
	buffer_source_jList_id = node.id
