extends SceneTree
## CI: parse every .gd file under res:// without loading scenes (Godot 4.x).
## Run: godot --headless --path src -s res://tools/ci_validate_scripts.gd


func _init() -> void:
	call_deferred("_validate_all")


func _validate_all() -> void:
	var errors: Array[String] = []
	_scan_dir("res://", errors)
	if errors.is_empty():
		quit(0)
		return
	push_error("GDScript validation failed (%d file(s)):" % errors.size())
	for msg in errors:
		push_error("  " + msg)
	quit(1)


func _scan_dir(dir_path: String, errors: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		errors.append("Could not open directory: %s" % dir_path)
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if name == "." or name == "..":
			name = d.get_next()
			continue
		var full: String = dir_path.path_join(name)
		if d.current_is_dir():
			if name.begins_with("."):
				pass
			elif name == ".import" or name == "build":
				pass
			elif full == "res://addons" or full.begins_with("res://addons/"):
				# Editor addons reference autoloads / editor APIs; parsing alone fails.
				pass
			elif full == "res://Editor" or full.begins_with("res://Editor/"):
				pass
			else:
				_scan_dir(full, errors)
		elif name.ends_with(".gd"):
			_validate_gd_file(full, errors)
		name = d.get_next()
	d.list_dir_end()


func _validate_gd_file(resource_path: String, errors: Array[String]) -> void:
	var f := FileAccess.open(resource_path, FileAccess.READ)
	if f == null:
		errors.append("Could not read: %s" % resource_path)
		return
	var source := f.get_as_text()
	source = _strip_class_name_line(source)
	var script := GDScript.new()
	# Do not set resource_path: the real script is already registered in the
	# resource cache and would trigger "cyclic resource inclusion" errors.
	script.source_code = source
	var err: Error = script.reload()
	if err != OK:
		errors.append("%s (%s)" % [resource_path, error_string(err)])


## Parsing the same file twice in one run would duplicate `class_name` registration and fail.
func _strip_class_name_line(source: String) -> String:
	var lines := source.split("\n")
	var out: PackedStringArray = PackedStringArray()
	for line in lines:
		if line.strip_edges().begins_with("class_name "):
			continue
		out.append(line)
	return "\n".join(out)
