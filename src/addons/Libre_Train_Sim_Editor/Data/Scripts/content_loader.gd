extends Node

var foundTracks := []
var foundContentPacks := []
var foundTrains := []


func _init() -> void:
	load_content_packs()


func load_content_packs():
	foundContentPacks = []
	if OS.has_feature("standalone"):
		foundContentPacks.append_array(jEssentials.crawl_directory_for(OS.get_executable_path().get_base_dir(), "pck"))
		foundContentPacks.append_array(jEssentials.crawl_directory_for("user://addons/", "pck"))
	else:
		Logger.warn("Skipping pack loading in editor build, because of https://github.com/godotengine/godot/issues/16798", self)
	Logger.vlog("Found Content Packs: %s" % [foundContentPacks])

	for contentPack in foundContentPacks:
		if ProjectSettings.load_resource_pack(contentPack, false):
			Logger.vlog("Loading Content Pack %s successfully finished" % contentPack)

	## Get all Tracks:
	var foundFiles = {"Array": []}
	Root.crawlDirectory("res://Worlds",foundFiles,"tscn")
	foundTracks = foundFiles["Array"].duplicate(true)

	## Get all Trains
	foundFiles = {"Array": []}
	Root.crawlDirectory("res://Trains",foundFiles,"tscn")
	foundTrains = foundFiles["Array"].duplicate(true)
