extends Node

var jAudioManagerBus = true # Set this to false, if you want to deactivate jAudioManagers bus System

var resourceTable = {}

var gameBusIdx = 1
var musicBusIdx = 2

func _ready():
	if jAudioManagerBus:
		print("jAudioManager loads in it's own audio bus layout. If you want to deactivate that, set 'jAudioManagerBus' in JAudioManager.gd:3 to false")
		AudioServer.set_bus_layout(preload("res://addons/jean28518.jTools/jAudioManager/jAudoManager_bus_layout.tres"))


# Groups:
# 0: Game
# 1: Music
# 2: Other
func play(soundPath : String, loop : bool = false, pausable : bool = true, volume_db : float = 0.0 , bus : String = "Game"):
	var audioStreamPlayer = AudioStreamPlayer.new()
	
	if not resourceTable.has(soundPath):
		resourceTable[soundPath] = load(soundPath)
		if resourceTable[soundPath] == null:
			print_debug("jAudioManager: " + soundPath + " not found. Please give in a appropriate path beginning with res://")
			return
			
	if not resourceTable[soundPath] is AudioStream:
		return
	
	audioStreamPlayer.volume_db = volume_db
	audioStreamPlayer.stream = resourceTable[soundPath].duplicate()
	audioStreamPlayer.stream.loop = loop
	
	if jAudioManagerBus:
		audioStreamPlayer.bus = bus
		
	if pausable:
		audioStreamPlayer.pause_mode  = 1
	else:
		audioStreamPlayer.pause_mode  = 2
	add_child(audioStreamPlayer)
	audioStreamPlayer.owner = self
	audioStreamPlayer.play()
	
	audioStreamPlayer.connect("finished", self, "queue_me_free", [audioStreamPlayer])

func clear_all_sounds():
	for child in get_children():
		child.queue_free()

func queue_me_free(node): ## Usually Called by AudioPlayers, which finished playing their sound.
	node.queue_free()

func play_music(soundPath : String, loop : bool = true, volume_db : float = 0.0):
	play(soundPath, loop, false, volume_db, "Music")

func play_game_sound(soundPath : String, volume_db : float = 0.0):
	play(soundPath, false, true, volume_db, "Game")


func set_main_volume_db(volume : float):
	if jAudioManagerBus:
		AudioServer.set_bus_volume_db(0, linear2db(volume))

func set_game_volume_db(volume : float):
	if jAudioManagerBus:
		AudioServer.set_bus_volume_db(gameBusIdx, linear2db(volume))

func set_music_volume_db(volume : float):
	if jAudioManagerBus:
		AudioServer.set_bus_volume_db(musicBusIdx, linear2db(volume))
