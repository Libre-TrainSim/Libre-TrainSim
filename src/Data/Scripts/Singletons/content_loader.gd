extends Node


var found_mods := {
	"content.pck": [],
	"content.tres": [],
	"unique_name": [],
}
var loaded_mods := []
var repo := ModContentDefinition.new()

var dependency_tree_root: Node


func _ready() -> void:
	append_content_to_global_repo(preload("res://content.tres"))
	find_content_packs()
	load_content_packs()  # TODO: let user select which mods to load??


func load_content_packs() -> void:
	# load information for all available mods first (required for dependency check)
	var i = 0
	while i < len(found_mods["content.tres"]):
		var content: ModContentDefinition = found_mods["content.tres"][i]
		if content == null:
			Logger.warn("Found pack %s, but could not load its content.tres file!" % found_mods["content.pck"][i], self)
			found_mods["content.tres"].remove(i)
			found_mods["content.pck"].remove(i)
			continue
		found_mods["unique_name"].append(content.unique_name)
		i += 1

	# build dependency tree
	var mods_to_load = build_dependency_tree()  # return leaf nodes

	while not mods_to_load.empty():
		var node: Node = mods_to_load.pop_front()
		if node == null:
			continue

		if not node.get_parent() in mods_to_load and node.get_parent() != dependency_tree_root:
			mods_to_load.append(node.get_parent())

		var idx = found_mods["unique_name"].find(node.name)
		var content = found_mods["content.tres"][idx]
		var pack = found_mods["content.pck"][idx]

		if OS.has_feature("standalone"):
			if ProjectSettings.load_resource_pack(pack, true):
				Logger.vlog("Loading Content Pack %s successfully finished" % pack)
				append_content_to_global_repo(content)
			else:
				Logger.err("Something went wrong when loading pack %s, not loading mods that require it!" % pack, self)
				_remove_top_most_mod_except_siblings(node)
		else:
			Logger.warn("Skipping pack loading in editor build, because of https://github.com/godotengine/godot/issues/16798", self)

	dependency_tree_root.queue_free()


func find_content_packs() -> void:
	var found_content_packs := []

	# limit recursion to 2 levels
	Root.crawl_directory(found_content_packs, OS.get_executable_path().get_base_dir(), ["pck"], 2)
	Root.crawl_directory(found_content_packs, "user://addons/", ["pck"], 2)

	Logger.vlog("Found Content Packs: %s" % [found_content_packs])

	for content_pack in found_content_packs:
		found_mods["content.pck"].append(content_pack)
		found_mods["content.tres"].append(load(content_pack.get_base_dir().plus_file("content.tres")))


func build_dependency_tree() -> Array:
	dependency_tree_root = Node.new()
	dependency_tree_root.name = "Mod Dependency Tree"
	self.add_child(dependency_tree_root)

	# add all mods to dependency tree
	var i = 0
	while i < len(found_mods["unique_name"]):
		# make sure mods are unique
		var unique_name = found_mods["unique_name"][i]
		if dependency_tree_root.find_node(unique_name, true, false):
			Logger.err("Multiple mods with the same unique name '%s' found! Removing duplicate!" % unique_name, self)
			found_mods["unique_name"].remove(i)
			found_mods["content.tres"].remove(i)
			found_mods["content.pck"].remove(i)
			continue
		var node = Node.new()
		node.name = unique_name
		dependency_tree_root.add_child(node)
		i += 1

	# reparent mods to what they are required by
	for mod in found_mods["content.tres"]:
		var mod_node = dependency_tree_root.find_node(mod.unique_name, true, false)
		if mod_node == null:
			continue

		for dep in mod.depends_on:
			if mod_node.find_parent(dep.unique_name):
				Logger.warn("Dependency cycle detected for mod %s !" % mod_node.unique_name, self)
				_remove_top_most_mod_except_siblings(mod_node)
				break

			var dep_node = dependency_tree_root.find_node(dep.unique_name, true, false)
			if dep_node == null:
				Logger.warn("Dependency %s not found for mod %s !" % [dep.unique_name, mod.unique_name], self)
				_remove_top_most_mod_except_siblings(mod_node)
				break

			var idx = found_mods["unique_name"].find(dep.unique_name)
			var dep_content = found_mods["content.tres"][idx]
			if not dep_content._check_semver(dep.version):
				Logger.warn("Version mismatch for dependency %s of mod %s. Got %s, Require %s." % [dep.unique_name, mod.unique_name, dep_content._semver_to_string(), dep.version], self)
				_remove_top_most_mod_except_siblings(mod_node)
				break

			dep_node.get_parent().remove_child(dep_node)
			mod_node.add_child(dep_node)

	var stack := dependency_tree_root.get_children()
	var load_order := []
	while not stack.empty():
		var child = stack.pop_front()
		load_order.push_front(child)
		stack.append_array(child.get_children())
	return load_order


func _get_top_most_mod(mod: Node) -> Node:
	var node = mod
	while(node.get_parent() != dependency_tree_root):
		node = node.get_parent()
	return node


func _remove_top_most_mod_except_siblings(node: Node) -> void:
	# children of this mod can still be loaded
	var children := node.get_children()
	for child in children:
		node.remove_child(child)
		dependency_tree_root.add_child(child)

	var top_most := _get_top_most_mod(node)
	var stack := [top_most]
	while not stack.empty():
		var n: Node = stack.pop_front()
		if n == node or n.find_node(node.name, true, false):
			# this mod depends on the broken one, can't load anymore
			# its children may not depend on it, and be loadable, check them
			stack.append_array(n.get_children())
		else:
			# save these mods, they can still be loaded
			n.get_parent().remove_child(n)
			dependency_tree_root.add_child(n)

	top_most.free()


func append_content_to_global_repo(content: ModContentDefinition) -> void:
	repo.trains.append_array(content.trains)
	repo.worlds.append_array(content.worlds)
	repo.environment_folders.append_array(content.environment_folders)
	repo.material_folders.append_array(content.material_folders)
	repo.music_folders.append_array(content.music_folders)
	repo.object_folders.append_array(content.object_folders)
	repo.persons_folders.append_array(content.persons_folders)
	repo.rail_type_folders.append_array(content.rail_type_folders)
	repo.signal_type_folders.append_array(content.signal_type_folders)
	repo.sound_folders.append_array(content.sound_folders)
	repo.texture_folders.append_array(content.texture_folders)

	loaded_mods.append(content)


func get_editor_tracks() -> Dictionary:
	var tracks: Dictionary = {}
	var editor_directory: String = jSaveManager.get_setting("editor_directory_path", "user://editor/")
	var track_names: Array = []
	var files: Array = []
	Root.crawl_directory(files, editor_directory, ["tres"], 2)
	for file in files:
		if file.get_file() != "content.tres":
			continue
		var content = load(file) as ModContentDefinition
		if !content:
			continue
		for world in content.worlds:
			var mod_path: String = file.get_base_dir()
			track_names.push_back(world.replace("res://Mods", \
					mod_path.get_base_dir()).get_basename())
			tracks[track_names.back()] = [content, mod_path]
	return tracks


func get_scenarios_for_track(track_folder: String) -> Array:
	var scenario_dir: String = track_folder.plus_file("scenarios")
	var result: Array = []
	Root.crawl_directory(result, scenario_dir, ["tres"], 2)
	return result


# If train_name is part of the path, this function returns the whole path
func find_train_path(train_name: String) -> String:
	for available_train_path in ContentLoader.repo.trains:
		if available_train_path.find(train_name) != -1:
			return available_train_path
	return ""
