tool
extends Node



func call_delayed(delay : float, object : Object, method : String, arg_array : Array = []):
	delayed_call_table.delay.append(delay)
	delayed_call_table.object.append(object)
	delayed_call_table.method.append(method)
	delayed_call_table.arg_array.append(arg_array)

## Internal Functions ##########################################################

func _ready():
	delayed_call_table = {"delay" : [], "object" : [], "method" : [], "arg_array" : [] }

func _process(delta):
	handle_delayed_calls(delta)

var delayed_call_table

func handle_delayed_calls(delta):
	var i = 0
	while(i < delayed_call_table.delay.size()): ## We need here a while loop, because want to keep track of the (changing) table size. 
		delayed_call_table.delay[i] -= delta
		if delayed_call_table.delay[i] <= 0:
			var object = delayed_call_table.object[i]
			object.callv(delayed_call_table.method[i], delayed_call_table.arg_array[i])
			delayed_call_table.delay.remove(i)
			delayed_call_table.object.remove(i)
			delayed_call_table.method.remove(i)
			delayed_call_table.arg_array.remove(i)
			i -= 1 ## Because we remove here an entry
		i += 1


			
