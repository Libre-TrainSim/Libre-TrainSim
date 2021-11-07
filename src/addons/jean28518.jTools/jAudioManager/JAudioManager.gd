extends Node

var resourceTable := {}

const bus_names := ["Master", "Game", "Music"]
enum AudioBus {
	MASTER = 0,
	GAME = 1,
	MUSIC = 2
}


func play(soundPath: String, loop: bool = false, pausable: bool = true, volume_db: float = 0.0 , bus: int = AudioBus.GAME):
	var audioStreamPlayer = AudioStreamPlayer.new()

	if not resourceTable.has(soundPath) or resourceTable[soundPath] == null:
		resourceTable[soundPath] = load(soundPath)
		if resourceTable[soundPath] == null:
			print_debug("jAudioManager: " + soundPath + " not found. Please give in a appropriate path beginning with res://")
			return

	audioStreamPlayer.volume_db = volume_db
	audioStreamPlayer.stream = resourceTable[soundPath].duplicate()
	audioStreamPlayer.stream.loop = loop

	audioStreamPlayer.bus = bus_names[bus]

	if pausable:
		audioStreamPlayer.pause_mode  = 1
	else:
		audioStreamPlayer.pause_mode  = 2

	add_child(audioStreamPlayer)
	audioStreamPlayer.owner = self
	audioStreamPlayer.play()
	audioStreamPlayer.connect("finished", audioStreamPlayer, "queue_free")


func clear_all_sounds():
	for child in get_children():
		child.queue_free()


func play_music(soundPath : String, loop : bool = true, volume_db : float = 0.0):
	play(soundPath, loop, false, volume_db, AudioBus.MUSIC)


func play_game_sound(soundPath : String, volume_db : float = 0.0):
	play(soundPath, false, true, volume_db, AudioBus.GAME)


func set_main_volume_db(volume : float):
	AudioServer.set_bus_volume_db(AudioBus.MASTER, linear2db(volume))


func set_game_volume_db(volume : float):
	AudioServer.set_bus_volume_db(AudioBus.GAME, linear2db(volume))


func set_music_volume_db(volume : float):
	AudioServer.set_bus_volume_db(AudioBus.MUSIC, linear2db(volume))
