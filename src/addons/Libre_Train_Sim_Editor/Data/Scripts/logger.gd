tool
class_name Logger
extends Object


const ENABLE_VERBOSE_LOGGING = true # constant for dead code elimination


static func log(message, context = null) -> void:
	print("[%s][INFO](%s) %s" % [get_time_string(), context, message])


static func vlog(message, context = null) -> void:
	if !ENABLE_VERBOSE_LOGGING:
		return
	print("[%s][VERBOSE](%s) %s" % [get_time_string(), context, message])


static func err(message, context) -> void:
	printerr("[%s][ERROR](%s) %s" % [get_time_string(), context, message])
	print_stack_trace()
	push_error("(%s) %s" % [context, message])


static func warn(message, context) -> void:
	print("[%s][WARNING](%s) %s" % [get_time_string(), context, message])
	print_stack_trace()
	push_warning("(%s) %s" % [context, message])


static func get_time_string() -> String:
	var dt := OS.get_datetime()
	return "%s-%02d-%02d %02d:%02d:%02d" % [dt["year"], dt["month"], dt["day"], \
			dt["hour"], dt["minute"], dt["second"]]


static func print_stack_trace() -> void:
	var skips := 2 # We don't want to clutter the stacktrace with logger steps
	for entry in get_stack():
		if skips:
			skips -= 1
			continue
		print("\tAt: %s:%s:%s()" % [entry["source"], entry["line"], entry["function"]])
