extends Node

var currentScenario
var currentTrain
var EasyMode = true




var world ## Reference to world

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func checkAndLoadTranslationsForTrack(trackName): # Searches for translation files with trackName in res://Translations/
	print(trackName.get_file().get_basename())
	var trackTranslations = []
	var dir = Directory.new()
	dir.open("res://Translations")
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "":
				break
		if file.get_extension() == "translation":
			if file.get_file().begins_with(trackName):
				trackTranslations.append("res://Translations/" + file.get_file())
				print("Track Translation Found " + "res://Translations/" + file.get_file())
	for trackTranslationPath in trackTranslations:
		var trackTranslation = load(trackTranslationPath)
		print(trackTranslation.locale)
		TranslationServer.add_translation(trackTranslation)

func checkAndLoadTranslationsForTrain(trainDirPath): # Searches for translation files wich are located in the same folder as the train.tscn. Gets the full path to train.tscn as input
	print(trainDirPath)
	var trainTranslations = []
	var dir = Directory.new()
	dir.open(trainDirPath)
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "":
				break
		if file.get_extension() == "translation":
			trainTranslations.append(trainDirPath+"/"+file)
			print("Track Translation Found " + "res://Translations/" + file.get_file())
	for trainTranslationPath in trainTranslations:
		var tainTranslation = load(trainTranslationPath)
		print(tainTranslation.locale)
		TranslationServer.add_translation(tainTranslation)

func crawlDirectory(directoryPath,foundFiles,fileExtension): ## found files has to be an dict: {"Array" : []}
	var dir = Directory.new()
	if dir.open(directoryPath) != OK: return
	dir.list_dir_begin()
	while(true):
		var file = dir.get_next()
		if file == "": break
		if file.begins_with("."): continue
		if dir.current_is_dir():
			crawlDirectory(directoryPath+"/"+file, foundFiles, fileExtension)
		else:
			if file.get_extension() == fileExtension:
				foundFiles["Array"].append(directoryPath +"/"+file)
	dir.list_dir_end()
